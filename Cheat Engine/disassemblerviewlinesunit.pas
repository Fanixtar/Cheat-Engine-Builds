unit disassemblerviewlinesunit;

{$MODE Delphi}

interface

uses math,LCLIntf,sysutils, classes,ComCtrls, graphics, CEFuncProc, disassembler,
     CEDebugger, debughelper, KernelDebugger, symbolhandler, plugin,
     disassemblerComments, SymbolListHandler, ProcessHandlerUnit, tcclib,SynHighlighterCpp
     {$ifdef USELAZFREETYPE}
     ,LazFreeTypeIntfDrawer, EasyLazFreeType
     {$endif}, betterControls;

type
  TDisassemblerViewColorsState=(csUndefined=-1, csNormal=0, csHighlighted=1, csSecondaryHighlighted=2, csBreakpoint=3, csHighlightedbreakpoint=4, csSecondaryHighlightedbreakpoint=5, csUltimap=6, csHighlightedUltimap=7, csSecondaryHighlightedUltimap=8);
  TDisassemblerViewColors=array [csNormal..csSecondaryHighlightedUltimap] of record
    backgroundcolor: TColor;
    normalcolor: TColor;
    registercolor: TColor;
    symbolcolor: TColor;
    hexcolor: TColor;
  end;

  PDisassemblerViewColors=^TDisassemblerViewColors;

  TDisassemblerLine=class
  private
    fowner: TObject;
    fbitmap: tbitmap;
    fCanvas: TCanvas;
    fHeaders: THeaderSections;
    ftop: integer;
    fheight: integer; //height of the line
    fDefaultHeight: integer; //the normal height without anything extra
    fInstructionCenter: integer; //y position of the center of the disassembled line (so no header)

    isselected: boolean;

    faddress: ptrUint;
    fdescription: string;
    fdisassembled: string;

    fisJump: boolean;
    fjumpcolor: TColor;
    fJumpsTo: ptrUint;
    fcolors: PDisassemblerViewColors;


    addressstring: string;
    bytestring: string;
    opcodestring: string;
    specialstring: string;
    specialstrings: tstringlist;
    customheaderstrings: tstringlist;
    parameterstring: string;
    referencedbylineheight: integer;
    boldheight: integer;
    textheight: integer;

    refferencedByStart: integer;

    sourcecodestart: integer;
    sourcecodestop: integer;



    isbp,isultimap: boolean;
    focused: boolean;

    {$ifdef USELAZFREETYPE}
    drawer: TIntfFreeTypeDrawer;
    ftfont,ftfontb: TFreeTypeFont;
    {$endif}

    function truncatestring(s: string; maxwidth: integer; hasSpecialChars: boolean=false): string;
    procedure buildReferencedByString(sl: tstringlist);
    function DrawTextRectWithColor(const ARect: TRect; X, Y: integer; const Text: string): integer;
    procedure renderCCodeLine(x,y: integer; text: string);
  public



    property instructionCenter: integer read fInstructionCenter;
    function isJumpOrCall(var addressitjumpsto: ptrUint): boolean;
    function getReferencedByAddress(y: integer):ptruint;
    function getSourceCode(y: integer):PLineNumberInfo;
    function getHeight: integer;
    function getTop: integer;
    property description:string read fdescription;
    property disassembled:string read fdisassembled;
    procedure renderLine(var address: ptrUint; linestart: integer; selected: boolean=false; focused: boolean=false; spaceAboveLines:integer=0; spaceBelowLines:integer=0);
    procedure drawJumplineTo(yposition: integer; offset: integer; showendtriangle: boolean=true);
    procedure handledisassemblerplugins(addressStringPointer: pointer; bytestringpointer: pointer; opcodestringpointer: pointer; specialstringpointer: pointer; textcolor: PColor);
    constructor create(owner: TObject; bitmap: TBitmap; headersections: THeaderSections; colors: PDisassemblerViewColors);
    destructor destroy; override;

  published

    property height: integer read fheight;
    property top: integer read fTop;
    property defaultHeight: integer read fDefaultHeight;
    property Address: ptrUint read faddress;
    property Owner: TObject read fowner;

end;

implementation

uses
  MemoryBrowserFormUnit, DissectCodeThread,debuggertypedefinitions,
  dissectcodeunit, disassemblerviewunit, frmUltimap2Unit, frmcodefilterunit,
  BreakpointTypeDef, vmxfunctions, globals, sourcecodehandler, SynHighlighterAA;

resourcestring
  rsUn = '(Unconditional)';
  rsCon = '(Conditional)';
  rsCall = '(Call)';
  rsMemory = '(Code/Data)';

  rsInvalidDisassembly = 'Invalid disassembly';

var
  chighlighter: TSynCppSyn;  //the disassemblerview lines highlighter is accessed only from the GUI thread, so can be global


procedure TDisassemblerLine.drawJumplineTo(yposition: integer; offset: integer; showendtriangle: boolean=true);
var
  oldpenstyle: Tpenstyle;
  oldpenwidth: integer;
  oldpencolor, oldbrushcolor: TColor;
  jlThickness: integer;

  triangleheight: integer;
begin
  jlThickness:=TDisassemblerview(owner).jlThickness;

  oldpenstyle:=fCanvas.Pen.Style;
  oldpenwidth:=fcanvas.pen.Width;
  oldpencolor:=fCanvas.Pen.color;
  oldbrushcolor:=fCanvas.Brush.color;

  fCanvas.Pen.Color:=fjumpcolor;
  fCanvas.Pen.Style:=psDot;
  fcanvas.Pen.Width:=jlThickness;

  fCanvas.PenPos:=point(fHeaders.items[2].Left,instructioncenter);
  fCanvas.LineTo(fHeaders.items[2].Left-offset,instructioncenter);
  fCanvas.LineTo(fHeaders.items[2].Left-offset,yposition);
  fCanvas.LineTo(fHeaders.items[2].Left,yposition);

  fCanvas.Pen.Style:=oldpenstyle;
  if showendtriangle then
  begin
    triangleheight:=defaultHeight div 4;

    fCanvas.Brush.Style:=bsSolid; //should be the default, but in case something fucked with it (not in the planning, never intended, so even if someone did do it, I'll undo it)
    fCanvas.Brush.Color:=fjumpcolor;
    fCanvas.Polygon([point(fheaders.items[2].Left-triangleheight,yposition-triangleheight),point(fheaders.items[2].Left,yposition),point(fheaders.items[2].Left-triangleheight,yposition+triangleheight)]);
  end;
  fCanvas.Brush.Color:=oldbrushcolor;
  fCanvas.Pen.Color:=oldpencolor;

end;

function TDisassemblerLine.isJumpOrCall(var addressitjumpsto: ptrUint): boolean;
begin
  result:=fisJump;
  if result then
    addressitjumpsto:=fJumpsTo;
end;

function TDisassemblerLine.getReferencedByAddress(y: integer):ptruint;
//Search the referenced by strings for one with the correct start (if it has one)
var sl: Tstringlist;
  p: integer;
  a: string;
  i: integer;
begin
  result:=0;
  sl:=TStringList.create;
  buildReferencedByString(sl);
  if sl.count>0 then
  begin
    //find the line that matches with this y pos
    p:=refferencedByStart-top;
    for i:=0 to sl.count-1 do
    begin
      p:=p+fcanvas.GetTextHeight(sl[i]);
      if p>=y then //found it
      begin
        a:=copy(sl[i], 1, pos('(', sl[i])-1);
        result:=StrToQWord('$'+a);
        exit;
      end;
    end;
  end;
  freeandnil(sl);
end;

function TDisassemblerLine.getSourceCode(y: integer):PLineNumberInfo;
var sci: TSourceCodeInfo;
begin
  result:=nil;
  //check if y is between sourcecodestart/sourcecodestop, and if so get the sourcecode

  if (sourcecodestart<>sourcecodestop) and InRange(top+y,sourcecodestart, sourcecodestop) then
  begin
    sci:=SourceCodeInfoCollection.getSourceCodeInfo(fAddress);
    if sci<>nil then
    begin
      if sci.processID<>processid then
      begin
        sci.Free;
        exit(nil);
      end;

      result:=sci.getLineInfo(fAddress);
    end;
  end;

end;

function TDisassemblerLine.truncatestring(s: string; maxwidth: integer; hasSpecialChars: boolean=false): string;
var
  dotsize: integer;
  charindexes: array of integer;
  original: string;
  i,j: integer;
  insidecommand: boolean;

begin
  setlength(charindexes,0);
  if s='' then exit(s);
  original:=s;
  insidecommand:=false;

  if hasSpecialChars then
  begin

    setlength(charindexes, length(s)+1); //skipping index 0
    j:=1;
    for i:=1 to length(original) do
    begin
      case original[i] of
        '{':
        begin
          insidecommand:=true;
          continue
        end;

        '}':
        begin
          if insidecommand then
          begin
            insidecommand:=false;
            continue;
          end;
        end;
      end;

      if insidecommand then continue;

      s[j]:=original[i];
      charindexes[j]:=i;
      inc(j);
    end;

    setlength(s,j-1);
  end;


  if fCanvas.TextWidth(s)>maxwidth then
  begin
    dotsize:=fCanvas.TextWidth('...');
    maxwidth:=maxwidth-dotsize;
    if maxwidth<=0 then
    begin
      result:=''; //it's too small for '...'
      exit;
    end;

    while fCanvas.TextWidth(s)>maxwidth do
      s:=copy(s,1,length(s)-1);

    if hasSpecialChars then
    begin
      i:=charindexes[length(s)];
      result:=copy(original,1,i)+'{U}...';
    end
    else
      result:=s+'...';
  end
  else
  begin
    if hasSpecialChars then
      result:=original
    else
      result:=s; //it fits
  end;
end;


procedure TdisassemblerLine.buildReferencedByString(sl: tstringlist);
var addresses: tdissectarray;
    i: integer;
begin
  setlength(addresses,0);

  if (dissectcode<>nil) and (dissectcode.done) then
  begin
    if dissectcode.CheckAddress(address, addresses) then
    begin
      for i:=0 to length(addresses)-1 do
      begin
        case addresses[i].jumptype of
          jtUnconditional:
            sl.Add(inttohex(addresses[i].address, 8)+utf8toansi(rsUn));

          jtConditional:
            sl.Add(inttohex(addresses[i].address, 8)+utf8toansi(rsCon));

          jtCall:
            sl.Add(inttohex(addresses[i].address, 8)+utf8toansi(rsCall));

          jtMemory:
            sl.Add(inttohex(addresses[i].address, 8)+utf8toansi(rsMemory));
        end;
      end;
    end;
  end;
end;

procedure TDisassemblerLine.renderLine(var address: ptrUint; linestart: integer; selected: boolean=false; focused: boolean=false; spaceAboveLines:integer=0; spaceBelowLines:integer=0);
var
    baseofsymbol: qword;
    symbolname: string;
    parameters, locations,result: string;
    comment, header: string;
    refferencedby: string;
    refferencedbylinecount: integer;
    refferencedbyheight: integer;
    refferencedbystrings: tstringlist;
    i,j: integer;

    paddressstring: pchar;
    pbytestring: pchar;
    popcodestring: pchar;
    pspecialstring: pchar;

    textcolor: TColor;

    bp: PBreakpoint;


    ExtraLineRenderAbove: TRasterImage;
    AboveX, AboveY: Integer;

    ExtraLineRenderBelow: TRasterImage;
    BelowX, BelowY: Integer;
   // z: ptrUint;

    found :boolean;
    extrasymboldata: TExtraSymbolData;

    sourcecodeinfo: TSourceCodeInfo;
    lni: PLineNumberInfo;
    sourcecode: Tstringlist=nil;
    sourcecodelineheight: integer;
    sourcecodeheight: integer;
    sourcecodeindentationstart: integer; //after filename+linenumber

    iscurrentinstruction: boolean;

    PA: qword;
    BO: integer;
    b: byte;

    inactive: boolean;

    {$ifdef USELAZFREETYPE}
    w,h: single;
    {$endif}

    d: TDisassembler;

    header0left: integer;

begin
  d:=TDisassemblerview(owner).currentDisassembler;

  fcanvas.font.style:=[];

  iscurrentinstruction:=MemoryBrowser.lastdebugcontext.{$ifdef cpu64}rip{$else}EIP{$endif}=address;

  self.focused:=focused;

  ftop:=linestart;
  faddress:=address;

  if assigned(TDisassemblerview(fowner).OnExtraLineRender) then
  begin
    AboveX:=-1000;
    AboveY:=-1000;
    ExtraLineRenderAbove:=TDisassemblerview(fOwner).OnExtraLineRender(self, faddress, true, selected, AboveX, AboveY);

    BelowX:=-1000;
    BelowY:=-1000;
    ExtraLineRenderBelow:=TDisassemblerview(fOwner).OnExtraLineRender(self, faddress, false, selected, BelowX, BelowY);
  end
  else
  begin
    ExtraLineRenderAbove:=nil;
    ExtraLineRenderBelow:=nil;
  end;


  isselected:=selected;

  refferencedbystrings:=nil;
  fheight:=0;
  baseofsymbol:=0;
  //z:=address;


  symbolname:=symhandler.getNameFromAddress(address,symhandler.showsymbols,symhandler.showmodules,symhandler.showsections, @baseofsymbol, @found, 8,false);
  if (faddress=baseofsymbol) and found then
  begin
    extrasymboldata:=symhandler.getExtraDataFromSymbolAtAddress(address);
  end
  else
    extrasymboldata:=nil;


  if iscurrentinstruction then
    d.context:=@MemoryBrowser.lastdebugcontext
  else
    d.context:=nil;

  fdisassembled:=d.disassemble(address,fdescription);

  if TDisassemblerview(owner).UseRelativeBase then
    addressString:='+'+inttohex(d.LastDisassembleData.address-TDisassemblerview(owner).RelativeBase,8)
  else
    addressstring:=inttohex(d.LastDisassembleData.address,8);

  bytestring:=d.getLastBytestring;
  opcodestring:=d.LastDisassembleData.prefix+d.LastDisassembleData.opcode;
  
  parameterstring:=d.LastDisassembleData.parameters+' ';
  specialstring:=d.DecodeLastParametersToString;

  if iscurrentinstruction and d.LastDisassembleData.isconditionaljump and d.LastDisassembleData.willJumpAccordingToContext then
    parameterstring:=parameterstring+'  ---> ';



  //userdefined comments
  if dassemblercomments<>nil then
    comment:=dassemblercomments.comments[d.LastDisassembleData.address]
  else
    comment:='';

  if comment<>'' then
  begin
    try
      specialstring:=format(comment,[specialstring]);
    except
      specialstring:=comment;
    end;
  end;


  if symhandler.showsymbols or symhandler.showmodules then
  begin
    if TDisassemblerview(owner).UseRelativeBase then
      addressString:=addressstring+' ('+symbolname+')'
    else
      addressString:=symbolname;
  end
  else
    addressString:=truncatestring(addressString, fHeaders.Items[0].Width-2);


  //Correction for rendering bug.
  if (processhandler.isNetwork=true) and (processhandler.SystemArchitecture=archarm) then
  begin
    addressstring+=' ';
    bytestring+=' ';
    opcodestring+=' ';
  end;

  TDisassemblerview(owner).DoDisassemblerViewLineOverride(address, addressstring, bytestring, opcodestring, parameterstring, specialstring);

  //split up into lines
  specialstrings.text:=specialstring;
  customheaderstrings.text:=dassemblercomments.commentHeader[d.LastDisassembleData.address];


  bytestring:=truncatestring(bytestring, fHeaders.Items[1].Width-2, true);
  //opcodestring:=truncatestring(opcodestring, fHeaders.Items[2].Width-2, true);
  //specialstring:=truncatestring(specialstring, fHeaders.Items[3].Width-2);



  if boldheight=-1 then
  begin
    {$ifdef USELAZFREETYPE}
    if (not UseOriginalRenderingSystem) and (ftfontb<>nil) then
    begin
      boldheight:=ceil(ftfontb.TextHeight(fdisassembled));
    end
    else
    {$endif}
    begin
      fcanvas.Font.Style:=[fsbold];
      boldheight:=fcanvas.TextHeight(fdisassembled)+1;
      fcanvas.Font.Style:=[];
    end;
  end;

  fheight:=fheight+boldheight+1;
  fDefaultHeight:=fHeight;   //the height without anything special

  //calculate how big the comments are. (beyond the default height)
  for i:=1 to specialstrings.count-1 do
  begin
    {$ifdef USELAZFREETYPE}
    if (not UseOriginalRenderingSystem) and (ftfont<>nil) then
      inc(fHeight, ceil(ftfont.TextHeight(specialstrings[i])))
    else
    {$endif}
      inc(fHeight, fcanvas.textHeight(specialstrings[i]));
  end;

  //calculate the custom headersize
  for i:=0 to customheaderstrings.count-1 do
  begin
    {$ifdef USELAZFREETYPE}
    if (not UseOriginalRenderingSystem) and (ftfont<>nil) then
      inc(fHeight, ceil(ftfont.TextHeight(customheaderstrings[i])))
    else
    {$endif}
      inc(fheight, fCanvas.TextHeight(customheaderstrings[i]));
  end;

  inc(fHeight, spaceAboveLines+spaceBelowLines);

  if ExtraLineRenderAbove<>nil then
  begin
    if AboveY=-1000 then //y doesn't care about center...
      AboveY:=0;

    if AboveX=-1000 then //center
      AboveX:=(fHeaders.Items[fHeaders.Count-1].Width div 2) - (ExtraLineRenderAbove.Width div 2);

    inc(fheight, AboveY);
    inc(fHeight, ExtraLineRenderAbove.Height);
  end;

  if ExtraLineRenderBelow<>nil then
  begin
    if BelowY=-1000 then
      BelowY:=0;

    if BelowX=-1000 then //center
      BelowX:=(fHeaders.Items[fHeaders.Count-1].Width div 2) - (ExtraLineRenderBelow.Width div 2);

    inc(fheight, BelowY);
    inc(fHeight, ExtraLineRenderAbove.Height);
  end;




  if (baseofsymbol>0) and (faddress=baseofsymbol) then
  begin
    parameters:='';
    if textheight=-1 then
    begin
      {$ifdef USELAZFREETYPE}
      if (not UseOriginalRenderingSystem) and (ftfont<>nil) then
        textheight:=ceil(ftfont.TextHeight(symbolname))
      else
      {$endif}
        textheight:=fcanvas.TextHeight(symbolname);
    end;

    fheight:=height+textheight+1+10;

    if extrasymboldata<>nil then //more space needed for the local vars
      fHeight:=fHeight+textheight*extrasymboldata.locals.count;

  end;

  refferencedbylinecount:=0;


  if (dissectcode<>nil) and (dissectcode.done) then
  begin
    refferencedbystrings:=tstringlist.create;
    buildReferencedByString(refferencedbystrings);

    if refferencedbystrings.count>0 then
    begin
      if referencedbylineheight=-1 then
      begin
        {$ifdef USELAZFREETYPE}
        if (not UseOriginalRenderingSystem) and (ftfontb<>nil) then
        begin
          referencedbylineheight:=ceil(ftfontb.TextHeight('xxx'));
        end
        else
        {$endif}
        begin
          fcanvas.Font.Style:=[fsBold];
          referencedbylineheight:=fcanvas.textheight('xxx');
          fcanvas.Font.Style:=[];
        end;
      end;

      refferencedbylinecount:=refferencedbystrings.count;
      refferencedbyheight:=refferencedbylinecount*referencedbylineheight;
      fheight:=height+refferencedbyheight;
    end;
  end;

  lni:=nil;
  if SourceCodeInfoCollection<>nil then
  begin
    sourcecodeinfo:=SourceCodeInfoCollection.getSourceCodeInfo(faddress);
    if sourcecodeinfo<>nil then
    begin
      lni:=sourcecodeinfo.getLineInfo(faddress);
      if lni<>nil then
      begin
        sourcecode:=Tstringlist.create;
        sourcecode.text:=lni.sourcecode; //sourcecode has newline chars

        {$ifdef USELAZFREETYPE}
        if (not UseOriginalRenderingSystem) and (ftfont<>nil) then
        begin
          sourcecodelineheight:=ceil(ftfont.TextHeight('xxx'));
          sourcecodeindentationstart:=ceil(ftfont.TextWidth(sourcecode[0]+' '));
        end
        else
        {$endif}
        begin
          fcanvas.Font.Style:=[fsItalic];
          sourcecodelineheight:=fcanvas.TextHeight('QjgPli');
          fcanvas.Font.Style:=[];
          sourcecodeindentationstart:=fcanvas.TextWidth(sourcecode[0]+' ');
        end;

        sourcecodeheight:=sourcecodelineheight*(sourcecode.Count-1); //first line is the file and linenumber

        fheight:=height+sourcecodeheight;
      end;
    end;
  end;



  fisJump:=d.LastDisassembleData.isjump;

  if fisJump then
  begin
    fisjump:=cefuncproc.isjumporcall(faddress, fJumpsTo);


    if d.LastDisassembleData.iscall then
      fjumpcolor:= TDisassemblerview(owner).jlCallColor
    else
    begin
      if d.LastDisassembleData.isconditionaljump then
        fjumpcolor:=TDisassemblerview(owner).jlConditionalJumpColor
      else
        fjumpcolor:=TDisassemblerview(owner).jlUnConditionalJumpColor ;
    end;
  end;


  if debuggerthread<>nil then
    bp:=debuggerthread.isBreakpoint(faddress,0,true)
  else
    bp:=nil;


  isbp:=(bp<>nil) and (bp.breakpointTrigger=bptExecute) and (bp.active or (bp.breakpointMethod=bpmException) ) and (bp.markedfordeletion=false);
  isultimap:=((frmUltimap2<>nil) and frmUltimap2.IsMatchingAddress(faddress)) or ((frmCodeFilter<>nil) and (frmCodeFilter.isBreakpoint(faddress,b) ));
  isultimap:=isultimap or dbvm_isBreakpoint(faddress,PA,BO, b); //mark dbvm internal breakpoints with the same color as an ultimap bp


  if selected then
  begin
    if not isbp then
    begin
      //default
      if not focused then
      begin
        if isultimap then
        begin
          fcanvas.Brush.Color:=fcolors^[csSecondaryHighlightedUltimap].backgroundcolor;
          fcanvas.Font.Color:=fcolors^[csSecondaryHighlightedUltimap].normalcolor;
        end
        else
        begin
          fcanvas.Brush.Color:=fcolors^[csSecondaryHighlighted].backgroundcolor;
          fcanvas.Font.Color:=fcolors^[csSecondaryHighlighted].normalcolor;
        end;
      end
      else
      begin
        if isultimap then
        begin
          fcanvas.Brush.Color:=fcolors^[csHighlightedUltimap].backgroundcolor;
          fcanvas.Font.Color:=fcolors^[csHighlightedUltimap].normalcolor;
        end
        else
        begin
          fcanvas.Brush.Color:=fcolors^[csHighlighted].backgroundcolor;
          fcanvas.Font.Color:=fcolors^[csHighlighted].normalcolor;
        end;
      end;
    end
    else
    begin
      //it's a breakpoint
      fcanvas.Brush.Color:=fcolors^[csHighlightedbreakpoint].backgroundcolor;
      fcanvas.Font.Color:=fcolors^[csHighlightedbreakpoint].normalcolor;
    end;
    fcanvas.Refresh;



  end
  else
  begin
    //not selected
    if isbp then
    begin
      fCanvas.Brush.Color:=fcolors^[csbreakpoint].backgroundcolor;
      fCanvas.font.Color:=fcolors^[csbreakpoint].normalcolor;
    end else
    begin
      if isultimap then
      begin
        fCanvas.Brush.Color:=fcolors^[csUltimap].backgroundcolor;
        fCanvas.font.Color:=fcolors^[csUltimap].normalcolor;
      end
      else
      begin
        fCanvas.Brush.Color:=fcolors^[csNormal].backgroundcolor;
        fCanvas.font.Color:=fcolors^[csNormal].normalcolor;
      end;

    end;

    fcanvas.Refresh
  end;

  //height may not change after this
  {$ifdef USELAZFREETYPE}
  if (not UseOriginalRenderingSystem) and (drawer<>nil) then
    drawer.FillRect(0,top,fbitmap.width,top+height,TColorToFPColor(colortorgb(fcanvas.Brush.Color)))
  else
  {$endif}
    fcanvas.FillRect(rect(0,top,fbitmap.width,top+height));

  inc(linestart, spaceAboveLines);

  if ExtraLineRenderAbove<>nil then
  begin
    //render the image above
    linestart:=linestart+AboveY;
    fcanvas.Draw(abovex, linestart, ExtraLineRenderAbove);
    linestart:=linestart+ExtraLineRenderAbove.height;
  end;

  if (baseofsymbol>0) and (faddress=baseofsymbol) then
  begin

    parameters:='';
    result:='';
    if extrasymboldata<>nil then
    begin
      result:=extrasymboldata.return;
      if result<>'' then
        result:=result+' ';

      locations:='';
      parameters:='(';
      if extrasymboldata.parameters.count>0 then
      begin
        for i:=0 to extrasymboldata.parameters.count-1 do
        begin
          if i=0 then
            parameters:=parameters+extrasymboldata.parameters[i].vtype+' '+extrasymboldata.parameters[i].name
          else
            parameters:=parameters+', '+extrasymboldata.parameters[i].vtype+' '+extrasymboldata.parameters[i].name;

          if i=0 then
            locations:=' : '+extrasymboldata.parameters[i].name+'='+extrasymboldata.parameters[i].position
          else
            locations:=locations+' - '+extrasymboldata.parameters[i].name+'='+extrasymboldata.parameters[i].position;
        end;
      end
      else
        parameters:=parameters+extrasymboldata.simpleparameters;


      parameters:=parameters+')'+locations;


    end;

    {$ifdef USELAZFREETYPE}
    if (not UseOriginalRenderingSystem) and (drawer<>nil) then
    begin
      drawer.DrawText(AnsiToUtf8(result+symbolname+parameters), ftfontb,fHeaders.Items[0].Left+5,linestart+5, tcolortofpcolor(colortorgb(fcanvas.Font.color)), [ftaLeft, ftaTop]);
      linestart:=linestart+ceil(ftfontb.TextHeight(symbolname))+1+10;
    end
    else
    {$endif}
    begin
      fcanvas.Font.Style:=[fsbold];
      fcanvas.TextOut(fHeaders.Items[0].Left+5,linestart+5,AnsiToUtf8(result+symbolname+parameters));
      linestart:=linestart+fcanvas.TextHeight(symbolname)+1+10;
      fcanvas.Font.Style:=[];
    end;



    //render the local vars
    if extrasymboldata<>nil then
    begin
      linestart:=linestart-5; //go back a bit
      for i:=0 to extrasymboldata.locals.count-1 do
      begin
        parameters:=extrasymboldata.locals[i].vtype+' '+extrasymboldata.locals[i].name;
        if extrasymboldata.locals[i].position<>'' then
          parameters:=parameters+'('+extrasymboldata.locals[i].position+')';

        {$ifdef USELAZFREETYPE}
        if (not UseOriginalRenderingSystem) and (drawer<>nil) then
          drawer.DrawText(AnsiToUtf8(parameters), ftfont, fHeaders.Items[0].Left+5,linestart,tcolortofpcolor(colortorgb(fcanvas.Font.color)),  [ftaLeft, ftaTop])
        else
        {$endif}
          fcanvas.TextOut(fHeaders.Items[0].Left+5,linestart,AnsiToUtf8(parameters));
        linestart:=linestart+textheight;
      end;
      linestart:=linestart+5;
    end;

  end;

  if (refferencedbylinecount>0) then
  begin
    refferencedByStart:=linestart;

    fcanvas.Font.Style:=[fsBold];
    for i:=0 to refferencedbylinecount-1 do
    begin
      {$ifdef USELAZFREETYPE}
      if (not UseOriginalRenderingSystem) and (drawer<>nil) then
        drawer.DrawText(AnsiToUtf8(refferencedbystrings[i]), ftfontb, fHeaders.Items[0].Left+5,linestart, tcolortofpcolor(colortorgb(fcanvas.Font.color)), [ftaLeft, ftaTop])
      else
      {$endif}
        fcanvas.TextOut(fHeaders.Items[0].Left+5,linestart,AnsiToUtf8(refferencedbystrings[i]));

      linestart:=linestart+fcanvas.TextHeight(refferencedbystrings[i]);
    end;
    fcanvas.Font.Style:=[];

  end;


  if lni<>nil then  //render sourcecode lines
  begin
    sourcecodestart:=linestart;
    fcanvas.Font.Style:=[fsItalic];
    {$ifdef USELAZFREETYPE}
    if (not UseOriginalRenderingSystem) and (drawer<>nil) then
      drawer.DrawText(AnsiToUtf8(sourcecode[0]), ftfont, fHeaders.Items[0].Left+5, linestart, tcolortofpcolor(colortorgb(fcanvas.Font.color)), [ftaLeft, ftaTop])
    else
    {$endif}
    fcanvas.TextOut(fHeaders.Items[0].Left+5,linestart,AnsiToUtf8(sourcecode[0]));
    for i:=1 to sourcecode.count-1 do
    begin
      {$ifdef USELAZFREETYPE}
      if (not UseOriginalRenderingSystem) and (drawer<>nil) then
        drawer.DrawText(AnsiToUtf8(sourcecode[i]), ftfont, fHeaders.Items[0].Left+5+sourcecodeindentationstart, linestart, tcolortofpcolor(colortorgb(fcanvas.Font.color)), [ftaLeft, ftaTop])
      else
      {$endif}
      begin
        renderCCodeLine(fHeaders.Items[2].Left+1,linestart,AnsiToUtf8(sourcecode[i]));
      end;
      inc(linestart, sourcecodelineheight);
    end;

    fcanvas.Font.Style:=[];
    sourcecodestop:=linestart;
  end
  else
  begin
    sourcecodestart:=0;
    sourcecodestop:=0;
  end;

  if customheaderstrings.count>0 then
  begin
    //render the custom header
    for i:=0 to customheaderstrings.count-1 do
    begin
      {$ifdef USELAZFREETYPE}
      if (not UseOriginalRenderingSystem) and (drawer<>nil) then
        drawer.DrawText(AnsiToUtf8(customheaderstrings[i]),ftfont, fHeaders.Items[0].Left,linestart, tcolortofpcolor(colortorgb(fcanvas.Font.color)),  [ftaLeft, ftaTop] );
      {$endif}
        fcanvas.TextOut(fHeaders.Items[0].Left,linestart,AnsiToUtf8(customheaderstrings[i]));
      linestart:=linestart+fcanvas.TextHeight(customheaderstrings[i]);
    end;
  end;



  if iscurrentinstruction then
    addressString:='>>'+addressString;


  //set pointers to strings
  paddressstring:=nil;
  pbytestring:=nil;
  popcodestring:=nil;
  pspecialstring:=nil;

  if length(addressstring)>0 then
    paddressstring:=@addressstring[1];

  if length(bytestring)>0 then
    pbytestring:=@bytestring[1];

  if length(opcodestring)>0 then
    popcodestring:=@opcodestring[1];

  if length(specialstring)>0 then
    pspecialstring:=@specialstring[1];




  textcolor:=fcanvas.Font.Color;
  handledisassemblerplugins(@paddressString, @pbytestring, @popcodestring, @pspecialstring, @textcolor);
  fcanvas.font.color:=textcolor;


  DrawTextRectWithColor(rect(fHeaders.Items[0].Left, linestart, fHeaders.Items[0].Right, linestart+height), fHeaders.Items[0].Left+1,linestart, paddressString);

//  fcanvas.TextRect(rect(fHeaders.Items[1].Left, linestart, fHeaders.Items[1].Right, linestart+height),fHeaders.Items[1].Left+1,linestart, pbytestring);

  DrawTextRectWithColor(rect(fHeaders.Items[1].Left, linestart, fHeaders.Items[1].Right, linestart+height),fHeaders.Items[1].Left+1,linestart, pbytestring);


  fcanvas.font.Style:=fcanvas.font.Style+[fsBold];
  i:=DrawTextRectWithColor(rect(fHeaders.Items[2].Left, linestart, fHeaders.Items[2].Right, linestart+height),fHeaders.Items[2].Left+1,linestart, popcodestring);
  fcanvas.font.Style:=fcanvas.font.Style-[fsBold];

  {$ifdef USELAZFREETYPE}
  if (not UseOriginalRenderingSystem) and (ftfont<>nil) then
  begin
    inc(i, ceil(ftfont.TextWidth('  ')));
    j:=ceil(ftfont.TextWidth('XXXXXXX'));
  end
  else
  {$endif}
  begin
    inc(i, fcanvas.TextWidth('  '));
    j:=fcanvas.textwidth('XXXXXXX');
  end;

  if i>j then
  begin
    {$ifdef USELAZFREETYPE}
    if (not UseOriginalRenderingSystem) and (ftfont<>nil) then
      i:=fHeaders.Items[2].Left+1+i+ceil(ftfont.textwidth(' '))
    else
    {$endif}
      i:=fHeaders.Items[2].Left+1+i+fcanvas.textwidth(' ')
  end
  else
    i:=fHeaders.Items[2].Left+1+j;

  DrawTextRectWithColor(rect(fHeaders.Items[2].Left, linestart, fHeaders.Items[2].Right, linestart+height),i,linestart, parameterstring);
  fInstructionCenter:=linestart+(fcanvas.TextHeight(opcodestring) div 2);

  if specialstrings.Count>0 then
  begin
    for i:=0 to specialstrings.Count-1 do
    begin
      fcanvas.TextRect(rect(fHeaders.Items[3].Left, linestart, fHeaders.Items[3].Right, linestart+height),fHeaders.Items[3].Left+1,linestart, specialstrings[i]);
      inc(linestart, fcanvas.GetTextHeight(specialstrings[i]));
    end;
  end
  else
    inc(linestart, fcanvas.GetTextHeight(parameterstring));



  if ExtraLineRenderBelow<>nil then
  begin
    //render the image below
    linestart:=linestart+BelowY;
    fcanvas.Draw(belowx, linestart, ExtraLineRenderBelow);
    linestart:=linestart+ExtraLineRenderBelow.height; //not really needed as it's the last one
  end;


  if focused and (tdisassemblerview(fowner).hidefocusrect=false) then
      fcanvas.DrawFocusRect(rect(0,top,fbitmap.width,top+height));

  if selected then //restore
  begin
    fCanvas.Brush.Color:=fcolors^[csNormal].backgroundcolor;
    fCanvas.font.Color:=fcolors^[csNormal].normalcolor;
    fcanvas.Refresh;
  end;

  if refferencedbystrings<>nil then
    freeandnil(refferencedbystrings);

  if sourcecode<>nil then
    freeandnil(sourcecode);


end;


procedure TDisassemblerLine.renderCCodeLine(x,y: integer; text: string);
var
  s: string;
 // a: TToken
 oldfg: tcolor;
 oldstyle: TFontStyles;
 w: integer;
begin
  if chighlighter=nil then
  begin
    chighlighter:=TSynCppSyn.Create(nil);
    chighlighter.loadFromRegistryDefault;
  end;

  oldstyle:=fcanvas.font.style;
  oldfg:=fcanvas.font.color;

  chighlighter.ResetRange;
  chighlighter.SetLine(text,0);

  while not chighlighter.GetEol do
  begin
    s:=chighlighter.GetToken;

    fcanvas.Font.color:=chighlighter.GetTokenAttribute.Foreground;
    fcanvas.Font.style:=chighlighter.GetTokenAttribute.Style;

    w:=fcanvas.GetTextWidth(s);
    fcanvas.TextOut(x ,y,s);
    inc(x,w);

    chighlighter.Next;
  end;

  fcanvas.font.style:=oldstyle;
  fcanvas.font.color:=oldfg;
end;

function TDisassemblerLine.DrawTextRectWithColor(const ARect: TRect; X, Y: integer; const Text: string): integer;
var defaultfontcolor, defaultbrushcolor: TColor;
    i: integer;
    start,startx: integer;

    s,s2: string;

    colorcode: integer; //0=normal, 1=hex, 2=reg, 3=symbol 4=rgb
    bcolorcode: integer; //0=normal, 1=rgb
    rgbcolor: integer;
    brgbcolor: integer;
    colorstate: TDisassemblerViewColorsState;

    ts: TTextStyle;

  procedure setcolor;
  begin
    if isselected then
    begin
      if isbp then
        colorstate:=csSecondaryHighlightedbreakpoint
      else
      if isultimap then
        colorstate:=csSecondaryHighlightedUltimap
      else
        colorstate:=csSecondaryHighlighted;

      if focused then
      begin
        if isbp then
          colorstate:=csHighlightedbreakpoint
        else
        if isultimap then
          colorstate:=csHighlightedUltimap
        else
          colorstate:=csHighlighted;
      end;
    end
    else
    begin
      if isbp then
        colorstate:=csBreakpoint
      else
      if isultimap then
        colorstate:=csUltimap
      else
        colorstate:=csNormal;
    end;

    case colorcode of
      0: fcanvas.font.color:=fcolors^[colorstate].normalcolor;
      1: fcanvas.font.color:=fcolors^[colorstate].hexcolor;
      2: fcanvas.font.color:=fcolors^[colorstate].registercolor;
      3: fcanvas.font.color:=fcolors^[colorstate].symbolcolor;
      4: fcanvas.font.color:=rgbcolor;
    end;

    case bcolorcode of
      0:
      begin
        ts:=fcanvas.TextStyle;
        ts.Opaque:=true;
        fcanvas.TextStyle:=ts;
        fcanvas.Brush.color:=defaultbrushcolor;
      end;
      1:
      begin
        ts:=fcanvas.TextStyle;
        ts.Opaque:=true;
        fcanvas.TextStyle:=ts;

        fcanvas.Brush.color:=brgbcolor;
      end;
    end;
  end;

  {$ifdef USELAZFREETYPE}
 var fnt: TFreeTypeFont;
  {$endif}

begin
  {$ifdef USELAZFREETYPE}
  if fsbold in fcanvas.Font.style then
    fnt:=ftfontb
  else
    fnt:=ftfont;
  {$endif}

  defaultbrushcolor:=fcanvas.Brush.color;
  defaultfontcolor:=fcanvas.Font.color;
  start:=1;
  startx:=x;
  s:='';
  i:=1;
  colorcode:=0;
  bcolorcode:=0;

  if processhandler.SystemArchitecture=archx86 then
  begin
    while i<=length(text) do
    begin
      case text[i] of
        '{':
        begin
          setcolor;

          s:=copy(text, start,i-start);
          {$ifdef USELAZFREETYPE}
          if (not UseOriginalRenderingSystem) and (drawer<>nil) then
          begin
            drawer.DrawTextWordBreak(AnsiToUtf8(s),fnt,x,y,arect.Width-(x-startx),tcolortofpcolor(colortorgb(fcanvas.Font.Color)),[ftaLeft, ftaTop]);
            x:=x+ceil(fnt.TextWidth(s))+1;
          end
          else
          {$endif}
          begin
            fcanvas.TextRect(ARect,x,y,AnsiToUtf8(s));
            x:=x+fcanvas.TextWidth(s)+1;
          end;


          inc(i);
          while i<=length(text) do
          begin
            case text[i] of
              'N':
              begin
                colorcode:=0;
                bcolorcode:=0;
              end;
              'H': colorcode:=1;
              'R': colorcode:=2;
              'S': colorcode:=3;
              'B': //followed by RRGGBB colorcode
              begin
                s2:=copy(text, i+1,6);
                if trystrtoint('$'+s2, brgbcolor) then bcolorcode:=1;
                inc(i,6);
              end;
              'C': //followed by RRGGBB colorcode
              begin
                s2:=copy(text, i+1,6);
                if trystrtoint('$'+s2, rgbcolor) then colorcode:=4;
                inc(i,6);
              end;
              '}':
              begin
                inc(i);
                break;
              end;

              //else raise exception.create(rsInvalidDisassembly);
            end;
            inc(i);
          end;

          start:=i;
        end;

        else inc(i);
      end;


    end;
  end
  else
    i:=length(text)+1;

  setcolor;

  s:=copy(text, start,i-start);
  {$ifdef USELAZFREETYPE}
  if (not UseOriginalRenderingSystem) and (drawer<>nil) then
    drawer.DrawTextWordBreak(AnsiToUtf8(s),fnt,x,y,arect.Width-(x-startx),tcolortofpcolor(colortorgb(fcanvas.Font.Color)),[ftaLeft, ftaTop])
  else
  {$endif}
    fcanvas.TextRect(ARect,x,y,AnsiToUtf8(s));

  fcanvas.Font.color:=defaultfontcolor;
  fcanvas.brush.color:=defaultbrushcolor;

  {$ifdef USELAZFREETYPE}
  if (not UseOriginalRenderingSystem) and (fnt<>nil) then
    x:=x+ceil(fnt.TextWidth(s))
  else
  {$endif}
    x:=x+fcanvas.TextWidth(s);

  result:=x-startx;
end;

procedure TDisassemblerLine.handledisassemblerplugins(addressStringPointer: pointer; bytestringpointer: pointer; opcodestringpointer: pointer; specialstringpointer: pointer; textcolor: PColor);
begin
  //obsolete
  if pluginhandler<>nil then
    pluginhandler.handledisassemblerplugins(faddress, addressStringPointer, bytestringpointer, opcodestringpointer, specialstringpointer, textcolor);
end;

function TDisassemblerLine.getHeight: integer;
begin
  result:=height;
end;

function TDisassemblerLine.getTop: integer;
begin
  result:=ftop;
end;

destructor TDisassemblerLine.destroy;
begin
  freeandnil(specialstrings);

  inherited destroy;
end;

constructor TDisassemblerLine.create(owner: TObject; bitmap: TBitmap; headersections: THeaderSections; colors: PDisassemblerViewColors);
begin
  fowner:=owner;
  fCanvas:=bitmap.canvas;
  fBitmap:=bitmap;
  fheaders:=headersections;
  boldheight:=-1; //bypass for memory leak
  textheight:=-1;
  referencedbylineheight:=-1;

  fcolors:=colors;

  fheight:=fCanvas.TextHeight('X');
  fDefaultHeight:=-1;

  specialstrings:=tstringlist.create;
  customheaderstrings:=tstringlist.create;
  {$ifdef USELAZFREETYPE}
  drawer:=TDisassemblerview(owner).drawer;
  ftfont:=TDisassemblerview(owner).ftfont;
  ftfontb:=TDisassemblerview(owner).ftfontb;
  {$endif}
end;

end.
