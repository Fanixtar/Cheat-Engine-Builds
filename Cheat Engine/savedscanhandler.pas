unit savedscanhandler;

{$MODE Delphi}

{
12 december 2010: Firsthandler should be renamed to "previousscanhandler" as it's being used for saved scans as well now
}

{
First scan handler is a class that will help with scanning the results of the
first scan.
It'll read the results of the first scan and provides an inteface for the
scanroutines for quick lookup of the previous value of a specific address
}

{
Current problem:
The saved scan can be used by other threads and keep the files in use possibly making deletion impossible.

solution:
do something

final result:
All file handles released

}


{
function BinSearchEntry(Strings: TStrings; address: dword; var Pivot: integer): integer;
var
  First: Integer;
  Last: Integer;
  Found: Boolean;
begin
  try
    First  := 0; //Sets the first item of the range
    Last   := Strings.Count-1; //Sets the last item of the range
    Found  := False; //Initializes the Found flag (Not found yet)
    Result := -1; //Initializes the Result

    while (First <= Last) and (not Found) do
    begin

      //Gets the middle of the selected range
      Pivot := (First + Last) div 2;
      //Compares the String in the middle with the searched one
      if TMemoryAllocEvent(strings.Objects[Pivot]).BaseAddress = address then
      begin
        Found  := True;
        Result := Pivot;
      end
      //If the Item in the middle has a bigger value than
      //the searched item, then select the first half
      else if TMemoryAllocEvent(strings.Objects[Pivot]).BaseAddress > address then
        Last := Pivot - 1
          //else select the second half
      else
        First := Pivot + 1;
    end;
  except
    outputdebugstring('Exception in BinSearchEntry');
  end;
end;   }


interface

{$ifdef darwin}
uses macport, LCLIntf,classes,sysutils,syncobjs, CEFuncProc, CustomTypeHandler, commonTypeDefs;
{$endif}

{$ifdef windows}
uses windows, LCLIntf,classes,sysutils,syncobjs, CEFuncProc, CustomTypeHandler, commonTypeDefs;

{$define customtypeimplemented}

{$endif}

{$ifdef jni}
uses Classes,sysutils,syncobjs,unixporthelper, CustomTypeHandler, commonTypeDefs;

{$endif}

type TSavedScantype= (fs_advanced,fs_addresslist);
//type TValueType= (vt_byte,vt_word, vt_dword, vt_single, vt_double, vt_int64, vt_all);     //todo: Make compatible with the rest of ce's vartype


type

  ESavedScanException = class(Exception);   //debugger can ignore this
  ESavedScanExceptionBad = class(Exception);

  TSavedScanHandler = class
  private
    SavedScanmemoryFS: TFileStream;
    SavedScanaddressFS: TFileStream;
    SavedScantype: tSavedScantype;

    maxaddresslistcount: integer;
    currentaddresslistcount: integer; //the current amount of items in the list
    addresslistmemory: pointer;  //can be an array of regions, an array of pointers or an array of tbitaddress definitions
    addresslistoffset: qword; //offset into the savedscanaddressFS file
    SavedScanmemory: pointer;


    maxnumberofregions: integer;
    scandir: string;
    savedresultsname: string;

    SavedScanaddressSizeWithoutHeader: qword;
    SavedScanaddressCountAll, SavedScanaddressCountNormal: qword; //saves on a div each time


    LastAddressAccessed: record
      address: ptruint; //holds the last address that was read
      index: integer; //holds the index in the addresslist array
    end;

    currentRegion: integer;
    currentSubRegion: QWORD; //offset into the current region (governed by buffersize)
    Deinitialized: boolean; //if set do not lookup pointers

    reinitializeLater: boolean;
    reinitializeTimeout: qword;

    procedure cleanup;
    function loadIfNotLoadedRegion(p: pointer): pointer;

    procedure LoadNextChunk(valuetype: TVariableType);
    procedure LoadMemoryForCurrentChunk(valuetype: TVariableType; ct: TCustomType);
    procedure loadCurrentRegionMemory;
    procedure InitializeScanHandler;
  public
    lastFail: integer;
    AllowRandomAccess: boolean; //set this if you wish to allow random access through the list. (EXTREMELY INEFFICIENT IF IT HAPPENS, addresslist purposes only)
    AllowNotFound: boolean; //set this if you wish to return nil instead of an exception if the address can't be found in the list

    memscan: TObject;
    function getpointertoaddress(address:ptruint;valuetype:TVariableType; ct: TCustomType; recallifneeded: boolean=true): pointer;
    function getStringFromAddress(address: ptruint; out r: string; Hexadecimal: boolean=false; Signed: boolean=false; allVT: TVariableType=vtAll; allCustomType: TCustomType=nil): boolean;

    procedure deinitialize;
    procedure reinitialize;

    property name: string read savedresultsname;


    constructor create(scandir: string; savedresultsname: string; reinitializeLaterOnFailure: boolean=false);
    destructor destroy; override;
end;


implementation

uses Math, globals, memscan, lua, lauxlib, lualib, LuaClass, LuaObject,
  LuaHandler, byteinterpreter;

resourcestring
  rsMaxaddresslistcountIs0MeansTheAddresslistIsBad = 'maxaddresslistcount is 0 (Means: the addresslist is bad)';
  rsFailureInFindingInThePreviousScanResults = 'Failure in finding %s in the previous scan results';
  rsInvalidOrderOfCallingGetpointertoaddress = 'Invalid order of calling getpointertoaddress';
  rsFailureInFindingInTheFirstScanResults = 'Failure in finding %s in the first scan results';
  rsNoFirstScanDataFilesFound = 'No first scan data files found';


type TArrMemoryRegion= array [0..0] of TMemoryRegion;

function TSavedScanHandler.loadIfNotLoadedRegion(p: pointer): pointer;
{
Will load in a section from the memory file
p is a pointer in the memory buffer as if it was completely loaded
This will effectivly decrease reads to the file. Of course, there is still
unused memory which is kinda a waste, but it's the most efficient way
}
var index: integer;
    base: pointer;
begin
  result:=p;

  {
  adding a multireadexclusivewrite or not...
  might result in memory being written multiple times to exactly the same value
  but besides that no real problem.
  decision: no need to block other threads. Besides, the way threadjobs are made
  all have a separate region to scan, so usually shouldn't have much overlap
  }
  (*
  if not LoadedFromList[(ptrUint(p)-ptrUint(SavedScanmemory)) shr 12] then
  begin
    //not loaded yet, load this section
    index:=(ptrUint(p)-ptrUint(SavedScanmemory)) shr 12;

    base:=pointer(ptrUint(SavedScanmemory)+(index shl 12));
    SavedScanmemoryfile.Seek((index shl 12),soFromBeginning);

    //read 8KB (2 entries)
    SavedScanmemoryfile.Read(base^,$2000);

    loadedfromlistMREW.BeginWrite;
    LoadedFromList[index]:=true;
    LoadedFromList[index+1]:=true;
    loadedfromlistMREW.EndWrite;
  end; *)
end;

procedure TSavedScanHandler.loadCurrentRegionMemory;
{Loads the memory region designated by the current region}
var
  pm: ^TArrMemoryRegion;
begin
  pm:=addresslistmemory;

  SavedScanmemoryfs.position:=ptruint(pm^[currentRegion].startaddress)+currentSubRegion;
  savedscanmemoryfs.readbuffer(SavedScanmemory^, integer(min(qword(buffersize+64), qword(pm^[currentRegion].memorysize-currentSubRegion))));

end;

procedure TSavedScanHandler.LoadMemoryForCurrentChunk(valuetype: TVariableType; ct: TCustomType);
{
Loads the savedscanmemory block for the current adddresslist block
}
var addressliststart: qword;
    index: qword;
    i: integer;
    varsize: integer;
begin
  if valuetype<>vtall then
  begin
    //find the start of this region
    addressliststart:=(savedscanaddressfs.Position)-currentaddresslistcount*sizeof(ptruint);
    index:=(addressliststart-7) div sizeof(ptruint);
  end
  else
  begin
    addressliststart:=(savedscanaddressfs.Position)-currentaddresslistcount*sizeof(TBitAddress);
    index:=(addressliststart-7) div sizeof(TBitAddress);
  end;

  varsize:= 1;

  case valuetype of
    vtbyte: varsize:= 1;
    vtword: varsize:= 2;
    vtdword, vtSingle: varsize:= 4;
    vtdouble, vtQword: varsize:= 8;
    vtall:
    begin
      varsize:=8;
      {$ifdef customtypeimplemented}
      if vtCustom in ScanAllTypes then
        varsize:=max(varsize, MaxCustomTypeSize);
      {$endif}
    end;

    {$ifdef customtypeimplemented}
    vtcustom: varsize:= ct.bytesize;
    {$endif}
  end;



  SavedScanmemoryFS.Position:=index * varsize;
  SavedScanmemoryFS.ReadBuffer(SavedScanmemory^, currentaddresslistcount*varsize);
end;

procedure TSavedScanHandler.LoadNextChunk(valuetype: TVariableType);
{
For the addresslist specific type: Loads in the next region based on the addresslist
}
begin
//savedscanaddressfs.ReadBuffer(addresslistmemory, maxaddresslistcount*sizeof(ptruint));

  if valuetype<>vtall then
  begin

    currentaddresslistcount:=min(maxaddresslistcount, (savedscanaddressfs.size-savedscanaddressfs.Position) div sizeof(ptruint)); //limit to the addresslist file size
         {
         //for some reason setting a breakpoint on the above line will break gdb...
    if currentaddresslistcount=0 then
    begin
      beep;
    end;   }

    if addresslistmemory=nil then
      getmem(addresslistmemory, maxaddresslistcount*sizeof(ptruint));

    //load the results
    savedscanaddressfs.ReadBuffer(addresslistmemory^, currentaddresslistcount*sizeof(ptruint));
  end
  else
  begin
    currentaddresslistcount:=min(maxaddresslistcount, (savedscanaddressfs.size-savedscanaddressfs.Position) div sizeof(TBitAddress)); //limit to the addresslist file size

    if addresslistmemory=nil then
      getmem(addresslistmemory, maxaddresslistcount*sizeof(TBitAddress));

    savedscanaddressfs.ReadBuffer(addresslistmemory^, currentaddresslistcount*sizeof(TBitAddress));
  end;

  if currentaddresslistcount=0 then
  begin
    raise ESavedScanException.create(rsMaxaddresslistcountIs0MeansTheAddresslistIsBad+' (savedscanaddressfs.size='+inttostr(savedscanaddressfs.size)+')');
  end;

  LastAddressAccessed.index:=0; //reset the index
end;

function TSavedScanHandler.getStringFromAddress(address: ptruint; out r: string; Hexadecimal: boolean=false; Signed: boolean=false; allVT: TVariableType=vtAll; allCustomType: TCustomType=nil): boolean;
var
  p: pointer;
  ms: TMemScan;

  vtype: TVariableType;
  ct: TCustomType;
begin
  result:=false;
  if memscan=nil then exit;


  ms:=TMemscan(memscan);

  p:=getpointertoaddress(address, ms.VarType, ms.Customtype);
  if p<>nil then
  begin
    if ms.vartype=vtAll then
    begin
      vtype:=allVT;
      ct:=allCustomType;
    end
    else
    begin
      if allVT=vtAll then
      begin
        vtype:=ms.VariableType;
        ct:=ms.Customtype;
      end
      else
      begin
        vtype:=allVT;
        ct:=allCustomType;
      end;
    end;

    r:=readAndParsePointer(address, p, vtype, ct, hexadecimal, Signed);
    result:=true;
  end;
end;

function TSavedScanHandler.getpointertoaddress(address:ptruint;valuetype:TVariableType; ct: Tcustomtype; recallifneeded: boolean=true): pointer;
var i,j: integer;
    pm: ^TArrMemoryRegion;
    pa: PptruintArray;
    pab: PBitAddressArray;
    p: pbyte;
    p1: PByteArray;
    p2: PWordArray absolute p1;
    p3: PDwordArray absolute p1;
    p4: PSingleArray absolute p1;
    p5: PDoubleArray absolute p1;
    p6: PInt64Array absolute p1;

    first,last: integer;

    pivot: integer;
begin
  result:=nil;
  lastFail:=0;

  if Deinitialized then
  begin
    if reinitializeLater and (gettickcount64>reinitializeTimeout) then  //if has to reinitialize check if enough time has passed and try again
    begin
      try
        reinitialize;
        //success
        reinitializeLater:=false;
        deinitialized:=false;
      except
        deinitialized:=true;
        reinitializeLater:=true;
        reinitializeTimeout:=GetTickCount64+1000;
        lastFail:=1;
        exit;
      end;

    end
    else
    begin
      lastFail:=1;
      exit;
    end;
  end;

  if AllowRandomAccess then //no optimization if random access is used
  begin
    LastAddressAccessed.address:=0;
    LastAddressAccessed.index:=0;
  end;



  //6.1 Only part of the addresslist and memory results are loaded
  if SavedScantype=fs_advanced then
  begin
    {the addressfile exists out of a list of memoryregions started with the text
     REGION or NORMAL, so skip the first 7 bytes
    }


    pm:=addresslistmemory;

    if AllowRandomAccess and (currentregion>=0) and (address<pm^[currentregion].baseaddress+currentSubRegion) then //out of order access. Start from scratch
    begin
      currentRegion:=-1;
      currentSubRegion:=0;
    end;


    //if no region is set or the current region does not fall in the current list
    if (currentRegion=-1) or (address>pm^[currentregion].baseaddress+pm^[currentregion].memorysize) or (address>pm^[currentregion].baseaddress+currentSubRegion+buffersize) then
    begin
      //find the startregion, because it's a sequential read just go through it in order
      if (currentRegion=-1) or (address>pm^[currentregion].baseaddress+pm^[currentregion].memorysize) then
        inc(currentRegion);

      while (address>pm[currentregion].baseaddress+pm^[currentregion].memorysize) and (currentregion<maxnumberofregions) do
        inc(currentRegion);

      if currentregion>=maxnumberofregions then
      begin
        if AllowNotFound = false then
          raise ESavedScanException.create(Format(rsFailureInFindingInThePreviousScanResults, [inttohex(address, 8)]))
        else
        begin
          lastFail:=2;
          exit;
        end;
      end;

      currentSubRegion:=address-pm^[currentregion].baseaddress; //read from the requested address if a subregion  (skips stuff we don't need)

      loadCurrentRegionMemory;
    end;




    result:=pointer(ptruint(savedscanmemory)+(address-(pm^[currentregion].baseaddress+currentSubRegion)));
    exit;

  end
  else
  begin

    if addresslistmemory=nil then
    begin

      //the memoryblock should be only 20*4096=81920 bytes big set the addresslist size to be able to address that (it can do more if needed)
      case valuetype of
        //(vt_byte,vt_word, vt_dword, vt_single, vt_double, vt_int64, vt_all);
        vtbyte: maxaddresslistcount:= 20*4096 div 1;
        vtword: maxaddresslistcount:= 20*4096 div 2;
        vtdword, vtsingle: maxaddresslistcount:= 20*4096 div 4;
        vtdouble, vtQword: maxaddresslistcount:= 20*4096 div 8;

        vtall:
        begin
          maxaddresslistcount:=8;
          {$ifdef customtypeimplemented}
          if vtcustom in ScanAllTypes then
            maxaddresslistcount:=max(maxaddresslistcount, MaxCustomTypeSize);
          {$endif}

          if maxaddresslistcount>20*4096 then
          begin
            ReAllocMem(SavedScanmemory, maxaddresslistcount);
            maxaddresslistcount:=1
          end
          else
            maxaddresslistcount:=20*4096 div maxaddresslistcount;

        end
        {$ifdef customtypeimplemented}
        ;


        vtCustom:
        begin
          maxaddresslistcount:=ct.bytesize;
          if maxaddresslistcount>20*4096 then
          begin
            ReAllocMem(SavedScanmemory, maxaddresslistcount);
            maxaddresslistcount:=1
          end
          else
            maxaddresslistcount:=20*4096 div maxaddresslistcount;

        end
        {$endif}

        else
          maxaddresslistcount:=1;
      end;





      loadnextchunk(valuetype); //will load the initial addresslist
      LoadMemoryForCurrentChunk(valuetype, ct);
    end;


    pa:=addresslistmemory;
    pab:=addresslistmemory;
    p1:=SavedScanmemory;

    if (valuetype <> vtall) then
    begin
      //addresslist is a list of pointers

      if pa[0]>address then  //out of order access
      begin
        if AllowRandomAccess then
        begin
          //random access allowed. Start all over
          if recallifneeded=false then
          begin
            lastFail:=3;
            exit; //already recalled once and it seems to have failed
          end;

          InitializeScanHandler;
          exit(getpointertoaddress(address, valuetype, ct, false));
        end
        else
          raise ESavedScanException.create(rsInvalidOrderOfCallingGetpointertoaddress);
      end;

      if pa[currentaddresslistcount-1]<address then
      begin
        while pa[currentaddresslistcount-1]<address do //load in the next chunk
        begin
          try
            LoadNextChunk(valuetype);
          except
            on e: exception do
            begin
              if AllowRandomAccess then
              begin
                if recallifneeded=false then
                begin
                  lastfail:=4;
                  exit; //already recalled once and it seems to have failed
                end;

                InitializeScanHandler;
                exit(getpointertoaddress(address, valuetype, ct, false));
              end
              else
                raise ESavedScanException.create(e.message);
            end;
          end;
        end;


        LoadMemoryForCurrentChunk(valuetype, ct);
      end;

      //we now have an addresslist and memory region and we know that the address we need is in here
      j:=currentaddresslistcount;

      //the list is sorted so do a quickscan



      first:=LastAddressAccessed.index;

      last:=j-1;

      while (First <= Last) do
      begin

        //Gets the middle of the selected range
        Pivot := (First + Last) div 2;
        //Compares the data in the middle with the searched one
        if address=pa[pivot] then
        begin
          //found it
          case valuetype of
            vtbyte : result:=@p1[pivot];
            vtword : result:=@p2[pivot];
            vtdword : result:=@p3[pivot];
            vtsingle: result:=@p4[pivot];
            vtdouble: result:=@p5[pivot];
            vtQword: result:=@p6[pivot];
            {$ifdef customtypeimplemented}
            vtCustom: result:=@p1[pivot*ct.bytesize]
            {$endif}
          end;
          LastAddressAccessed.address:=address;
          LastAddressAccessed.index:=pivot;
          exit;
        end
        //If the Item in the middle has a bigger value than
        //the searched item, then select the first half
        else if pa[pivot] > address then
          Last := Pivot - 1
            //else select the second half
        else
          First := Pivot + 1;
      end;


      //not found
      if not AllowNotFound then
        raise ESavedScanException.create(Format(rsFailureInFindingInTheFirstScanResults, [inttohex(address, 8)]));
    end
    else
    begin
      //addresslist is a list of 2 items, address and vartype, what kind of vartype is not important because each type stores it's full max variablecount

      if pab[0].address>address then
      begin
        if AllowRandomAccess then
        begin
          //random access allowed. Start all over
          if recallifneeded=false then
          begin
            lastFail:=5;
            exit; //already recalled once and it seems to have failed
          end;

          InitializeScanHandler;
          exit(getpointertoaddress(address, valuetype, ct, false));
        end
        else
          raise ESavedScanExceptionBad.create(rsInvalidOrderOfCallingGetpointertoaddress);
      end;

      if pab[currentaddresslistcount-1].address<address then
      begin
        while pab[currentaddresslistcount-1].address<address do //load in the next chunk
        try
          LoadNextChunk(valuetype);
        except
          on e: exception do
          begin
            if AllowRandomAccess then
            begin
              if recallifneeded=false then
              begin
                lastFail:=6;
                exit; //already recalled once and it seems to have failed
              end;

              InitializeScanHandler;
              exit(getpointertoaddress(address, valuetype, ct, false));
            end
            else
              raise ESavedScanExceptionBad.create(e.message);
          end;
        end;

        LoadMemoryForCurrentChunk(valuetype, ct);
      end;

      //we now have an addresslist and memory region and we know that the address we need is in here
      j:=currentaddresslistcount;


      //the list is sorted so do a quickscan
      first:=LastAddressAccessed.index;
      last:=j-1;

      while (First <= Last) do
      begin

        //Gets the middle of the selected range
        Pivot := (First + Last) div 2;
        //Compares the String in the middle with the searched one
        if address=pab[pivot].address then
        begin
          //found it
          {$ifdef customtypeimplemented}
          if vtcustom in ScanAllTypes then
            result:=@p1[pivot*max(8, MaxCustomTypeSize)]
          else
          {$endif}
            result:=@p6[pivot]; //8 byte entries, doesnt have to match the same type, since it is the same 8 byte value that's stored

          LastAddressAccessed.address:=address;
          LastAddressAccessed.index:=pivot;
          exit;
        end
        //If the Item in the middle has a bigger value than
        //the searched item, then select the first half
        else if pab[pivot].address > address then
          Last := Pivot - 1
            //else select the second half
        else
          First := Pivot + 1;
      end;

    end;

  end;

  if not AllowNotFound then
    raise ESavedScanExceptionBad.create(Format(rsFailureInFindingInThePreviousScanResults, [inttohex(address, 8)]));

end;




procedure TSavedScanHandler.InitializeScanHandler;
var datatype: string[6];
    pm: ^TArrMemoryRegion;
    i: integer;
    p: ptrUint;

    maxregionsize: integer;
begin
  Log('TSavedScanHandler.InitializeScanHandler');
  cleanup;
  maxregionsize:=20*4096;
  try
    try
      SavedScanaddressFS:=tfilestream.Create(scandir+'ADDRESSES.'+savedresultsname, fmopenread or fmsharedenynone);
    except
      raise ESavedScanException.Create(rsNoFirstScanDataFilesFound);
    end;
    SavedScanaddressFS.ReadBuffer(datatype,7);

    if datatype='REGION' then
    begin
      SavedScantype:=fs_advanced;
      maxnumberofregions:=(SavedScanaddressFS.Size-7) div sizeof(TMemoryRegion); //max number of regions

      //fill the addresslist with the regions
      getmem(addresslistmemory, (SavedScanaddressFS.Size-7));
      SavedScanaddressFS.ReadBuffer(addresslistmemory^, (SavedScanaddressFS.Size-7));


      //find the max region and split up into bitesize chunks
      pm:=addresslistmemory;

      p:=0;
      for i:=0 to maxnumberofregions-1 do
      begin
        maxregionsize:=max(maxregionsize, integer(min(qword(buffersize+64+MaxCustomTypeSize), qword(pm^[i].memorysize))));
        pm[i].startaddress:=pointer(p); //set the offset in the file (if it wasn't set already)
        inc(p, pm[i].MemorySize);
      end;


      currentRegion:=-1;
      currentSubRegion:=0;
    end
    else
    begin
      SavedScantype:=fs_addresslist;
      SavedScanaddressSizeWithoutHeader:=(SavedScanaddressFS.Size-7);
      SavedScanaddressCountNormal:=SavedScanaddressSizeWithoutHeader div sizeof(ptruint);
      SavedScanaddressCountAll:=SavedScanaddressSizeWithoutHeader div sizeof(tbitaddress);

      //allocate addresslistmemory on first access
    end;


    try
      SavedScanmemoryFS:=Tfilestream.Create(scandir+'MEMORY.'+savedresultsname,fmOpenRead or fmsharedenynone);
      getmem(SavedScanmemory, maxregionsize+512); //extra just to be safe for custom types that misreport size
    except
      raise ESavedScanException.Create(rsNoFirstScanDataFilesFound);
    end;

    deinitialized:=false;

  except
    on e: exception do
    begin
      //clean up and raise the exception
      log('Error during TSavedScanHandler.InitializeScanHandler:'+e.Message);
      cleanup;
      raise ESavedScanException.Create(e.Message);
    end;
 end;
end;

constructor TSavedScanHandler.create(scandir: string; savedresultsname: string; reinitializeLaterOnFailure: boolean=false);
begin
  inherited Create;

  Log('TSavedScanHandler.create('''+scandir+''','''+savedresultsname+'''');
  if savedresultsname='' then
    savedresultsname:='TMP';

  self.scandir:=scandir;
  self.savedresultsname:=savedresultsname;

  try
    InitializeScanHandler;
  except
    on e:exception do
    begin
      if reinitializeLaterOnFailure then
      begin
        Deinitialized:=true;
        reinitializeLater:=true;
        reinitializeTimeout:=gettickcount64+1000;
      end
      else
        raise;
    end;
  end;
end;

destructor TSavedScanHandler.destroy;
begin
  cleanup;
  inherited destroy;
end;

procedure TSavedScanHandler.cleanup;
{Cleanup routine, for use by create when failure and destroy}
begin
  if SavedScanmemory<>nil then
  begin
    freememandnil(SavedScanmemory);

  end;

  if addresslistmemory<>nil then
  begin
    freememandnil(addresslistmemory);

  end;

  if SavedScanaddressFS<>nil then
    freeandnil(SavedScanaddressFS);

  if SavedScanmemoryFS<>nil then
    freeandnil(SavedScanmemoryFS);
end;

procedure TSavedScanHandler.deinitialize;
begin
  cleanup;
  Deinitialized:=true;
  reinitializeLater:=false;
end;

procedure TSavedScanHandler.reinitialize;
begin
  InitializeScanHandler;
  deinitialized:=false;
end;


//---------------LUA-------------------
function savedscanhandler_getStringFromAddress(L: PLua_State): integer; cdecl;
var
  address: ptruint;
  ssh: TSavedScanHandler;
  r: string;
  hexadecimal, signed: boolean;
begin
  result:=0;
  ssh:=luaclass_getClassObject(L);
  if lua_gettop(L)>=1 then
  begin
    try
      address:=lua_toaddress(L,1);
    except
      on e: exception do
      begin
        lua_pushnil(L);
        lua_pushstring(L, e.Message);
        exit(2);
      end;
    end;

    if lua_Gettop(L)>=2 then
      hexadecimal:=lua_toboolean(L,2)
    else
      hexadecimal:=false;

    if lua_getProperty(L)>=3 then
      signed:=lua_toboolean(L,3)
    else
      signed:=false;

    if ssh.getStringFromAddress(address,r, hexadecimal, signed) then
      lua_pushstring(L,r)
    else
      lua_pushnil(L);

    result:=1;
  end;
end;

procedure savedscanhandler_addMetaData(L: PLua_state; metatable: integer; userdata: integer );
begin
  object_addMetaData(L, metatable, userdata);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'getStringFromAddress', savedscanhandler_getStringFromAddress);
end;

initialization
  luaclass_register(TSavedScanHandler, savedscanhandler_addMetaData);

end.

