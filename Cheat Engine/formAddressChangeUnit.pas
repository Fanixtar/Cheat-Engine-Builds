unit formAddressChangeUnit;

{$MODE Delphi}

{$warn 3057 off}

interface

uses
  {$ifdef darwin}
  macport, lcltype,
  {$endif}
  {$ifdef windows}
  windows, win32proc,
  {$endif}
  LCLIntf, LResources, LMessages, Messages, SysUtils, Variants,
  Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, ComCtrls,
  Buttons, Arrow, Spin, Menus, CEFuncProc, NewKernelHandler, symbolhandler,
  memoryrecordunit, types, byteinterpreter, math, CustomTypeHandler,
  commonTypeDefs, lua, lualib, lauxlib, luahandler{$ifdef windows}, CommCtrl{$endif}, LuaClass, Clipbrd,
  DPIHelper, betterControls;

const WM_disablePointer=WM_USER+1;

type
  TformAddressChange=class;
  TPointerInfo=class;

  {%region TOffsetInfo}

  TOffsetInfo=class
  private
    fowner: TPointerInfo;
    fBaseAddress: ptruint;
    fOffset: Integer; //signed integer
    fOffsetString: string;
    fInvalidOffset: boolean;
    fSpecial: boolean;

   // give this a popupmenu
    lblPointerAddressToValue: TLabel; //Address -> Value

    edtOffset: Tedit;
    sbDecrease, sbIncrease: TSpeedButton;
    istop: boolean;

    repeatstart: dword;
    repeattimer: TTimer;
    repeatdirection: integer;
    stepsize: integer;
    fReinterpretUpdateOnly: boolean;
    fOnlyUpdateAfterInterval: boolean;
    fUpdateInterval: integer;
    procedure setOffset(o: integer);
    procedure setOffsetString(os: string);
    procedure offsetchange(sender: TObject);

    procedure RepeatClick(sender: TObject);
    procedure DecreaseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure IncreaseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure IncreaseDecreaseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure DecreaseClick(sender: TObject);
    procedure IncreaseClick(sender: TObject);
    procedure setBaseAddress(address: ptruint);

  public
    constructor create(parentPointer: TPointerinfo);
    destructor destroy; override;
    function getAddressThisPointsTo(var address: ptruint): boolean;
    procedure setTop;
    procedure UpdateLabels;
    function parseOffset: boolean;
    property owner: TPointerinfo read fowner;
    property offset: integer read foffset write setOffset;  //obsolete, use offsetString
    property offsetString: string read fOffsetString write setOffsetString;
    property invalidOffset: boolean read fInvalidOffset;
    property baseAddress: ptruint read fBaseAddress write setBaseAddress;
    property special: boolean read fspecial;

    property OnlyUpdateWithReinterpret: boolean read fReinterpretUpdateOnly write fReinterpretUpdateOnly;
    property OnlyUpdateAfterInterval: boolean read fOnlyUpdateAfterInterval write fOnlyUpdateAfterInterval;
    property UpdateInterval: integer read fUpdateInterval write fUpdateInterval;
  end;

  {%endregion TOffsetInfo}

  {%region TPointerInfo}

  TPointerInfo=class(TCustomPanel)
  private
    fowner: TformAddressChange;
    fBaseAddress: ptruint;
    fInvalidBaseAddress: boolean;
    fError: boolean;  //indicator for the child offsets, accessed by Error
    baseAddress: TEdit;  //the bottom line
    baseValue: Tlabel;

    // List of Offsets. On Form Top Textbox is index=0, Bottom Textbox is index=count-1
    offsets: Tlist; //the lines above it

    btnAddOffset: TButton;
    btnRemoveOffset: TButton;
    baseAddressMinWidth: integer;
    procedure selfdestruct;
    procedure basechange(sender: Tobject);

    procedure AddOffsetClick(sender: TObject);
    procedure RemoveOffsetClick(sender: TObject);
    function getValueLeft: integer;
    function getOffset(index: integer): TOffsetInfo;
    function getoffsetcount: integer;

    function getAddressThisPointsTo(var address: ptruint): boolean;
  protected
    procedure DoOnResize; override;
  public
    property owner: TformAddressChange read fowner;
    property valueLeft: integer read getValueLeft; //gets the basevalue.left
    property error: boolean read ferror;
    property invalidBaseAddress: boolean read fInvalidBaseAddress;
    property offsetcount: integer read getoffsetcount;
    property offset[Index: Integer]: TOffsetInfo read getOffset;

    procedure processAddress; //reads the base address and all the offsets and shows what it all does
    procedure setupPositionsAndSizes;

    procedure addOffsetAroundSelectedOffset(const addAbove: boolean; const selectedOffset: TOffsetInfo);
    procedure appendOffset(newOffset: TOffsetInfo);

    constructor create(owner: TformAddressChange);
    destructor destroy; override;

  end;

  {%endregion TPointerInfo}

  {%region TformAddressChange }

  { TformAddressChange }

  TformAddressChange = class(TForm)
    cbCodePage: TCheckBox;
    cbHex: TCheckBox;
    cbSigned: TCheckBox;
    editDescription: TEdit;
    caImageList: TImageList;
    HexAndSignedPanel: TPanel;
    LabelType: TLabel;
    LabelDescription: TLabel;
    lblValue: TLabel;
    miCopyFinalAddressToClipboard: TMenuItem;
    miCopyValueToClipboard: TMenuItem;
    miAddOffsetAbove: TMenuItem;
    miAddOffsetBelow: TMenuItem;
    miRemoveOffset: TMenuItem;
    miSeparator: TMenuItem;
    miCut: TMenuItem;
    miCopy: TMenuItem;
    miPaste: TMenuItem;
    miAddAddressToList: TMenuItem;
    miCopyAddressToClipboard: TMenuItem;
    miUpdateOnReinterpretOnly: TMenuItem;
    miUpdateAfterInterval: TMenuItem;
    miUpdateSeparator: TMenuItem;
    pmPointerRow: TPopupMenu;
    pnlBitinfo: TPanel;
    cbunicode: TCheckBox;
    cbvarType: TComboBox;
    edtSize: TEdit;
    editAddress: TEdit;
    btnOk: TButton;
    btnCancel: TButton;
    cbPointer: TCheckBox;
    LabelAddress: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lengthlabel: TLabel;
    pnlExtra: TPanel;
    pmOffset: TPopupMenu;
    pmValue: TPopupMenu;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    RadioButton4: TRadioButton;
    RadioButton5: TRadioButton;
    RadioButton6: TRadioButton;
    RadioButton7: TRadioButton;
    RadioButton8: TRadioButton;
    Timer1: TTimer;
    Timer2: TTimer;
    procedure btnCancelClick(Sender: TObject);
    procedure cbCodePageChange(Sender: TObject);
    procedure cbHexChange(Sender: TObject);
    procedure cbSignedChange(Sender: TObject);
    procedure cbunicodeChange(Sender: TObject);
    procedure cbvarTypeChange(Sender: TObject);
    procedure editAddressChange(Sender: TObject);
    procedure cbPointerClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure miCopyFinalAddressToClipboardClick(Sender: TObject);
    procedure miCopyValueToClipboardClick(Sender: TObject);
    procedure miAddAddressToListClick(Sender: TObject);
    procedure miCopyAddressToClipboardClick(Sender: TObject);
    procedure miAddOffsetAboveClick(Sender: TObject);
    procedure miAddOffsetBelowClick(Sender: TObject);
    procedure miRemoveOffsetClick(Sender: TObject);
    procedure miCopyClick(Sender: TObject);
    procedure miCutClick(Sender: TObject);
    procedure miPasteClick(Sender: TObject);
    procedure miUpdateAfterIntervalClick(Sender: TObject);
    procedure miUpdateOnReinterpretOnlyClick(Sender: TObject);
    procedure pmOffsetPopup(Sender: TObject);
    procedure pnlExtraResize(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    { Private declarations }
    pointerinfo: TPointerInfo;
    fMemoryRecord: TMemoryRecord;
    delayedpointerresize: boolean;
    shown: boolean;
    loadedWidth: boolean;
    procedure offsetKeyPress(sender: TObject; var key:char);
    procedure processaddress;
    procedure ApplyMemoryRecord;
    procedure setMemoryRecord(rec: TMemoryRecord);
    procedure DelayedResize;
    procedure AdjustHeight;
    procedure PointerInfoResize(sender: TObject);

    procedure DisablePointerExternal(var m: TMessage); message WM_disablePointer;
    procedure setVarType(vt: TVariableType);
    function getVartype: TVariableType;
    procedure sLength(l: integer);
    function gLength: integer;
    procedure setStartbit(b: integer);
    function getStartbit: integer;
    procedure setUnicode(state: boolean);
    function getUnicode: boolean;
    procedure setCodePage(state: boolean);
    function getCodePage: boolean;
    procedure setDescription(s: string);
    function getDescription: string;
    procedure setAddress(var address: string; var offsets: TMemrecOffsetList);
  public
    { Public declarations }
    index: integer;
    index2: integer;
    focusDescription: boolean;
    property memoryrecord: TMemoryRecord read fMemoryRecord write setMemoryRecord;
    property vartype: TVariableType read getVartype write setVartype;
    property length: integer read gLength write sLength;
    property startbit: integer read getStartbit write setStartbit;
    property unicode: boolean read getUnicode write setUnicode;
    property codepage: boolean read getCodepage write setCodepage;
    property description: string read getDescription write setDescription;
  end;

  {%endregion TformAddressChange }

var
  formAddressChange: TformAddressChange;

implementation

uses MainUnit, formsettingsunit, ProcessHandlerUnit, Parsers, vartypestrings;

resourcestring
  rsThisPointerPointsToAddress = 'This pointer points to address';
  rsTheOffsetYouChoseBringsItTo = 'The offset you chose brings it to';
  rsResultOfNextPointer = 'Result of next pointer';
  rsAddressOfPointer = 'Address of pointer';
  rsOffsetHex = 'Offset (Hex)';
  rsFillInTheNrOfBytesAfterTheLocationThePointerPoints = 'Fill in the nr. of bytes after the location the pointer points to';
  rsIsNotAValidOffset = '%s is not a valid offset';
  rsNotAllOffsetsHaveBeenFilledIn = 'Not all offsets have been filled in';
  rsACAddOffset = 'Add Offset';
  rsACAddOffsetHint = 'Click: Add New Offset. Ctrl+Click: Add New Offset to the opposite location';
  rsACRemoveOffset = 'Remove Offset';
  rsACRemoveOffsetHint = 'Click: Remove Offset. Ctrl+Click: Remove Offset from the opposite location';


{%region TOffsetInfo }

procedure TOffsetInfo.RepeatClick(sender: TObject);
begin
  if repeatdirection=0 then
    DecreaseClick(nil)
  else
    IncreaseClick(nil);

  repeattimer.Interval:=max(10,500-((GetTickCount-repeatstart) div 10));
end;

procedure TOffsetInfo.DecreaseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if repeattimer<>nil then
    freeandnil(repeattimer);

  if ssCtrl in shift then
    stepsize:=1
  else if ssShift in shift then
    stepsize:=ifthen(processhandler.pointersize=8, 4, 8)
  else
    stepsize:=ifthen(istop, 4, processhandler.pointersize);

  repeatstart:=GetTickCount;
  repeatdirection:=0; //tell the timer to decrease

  repeattimer:=TTimer.Create(self.owner.owner);
  repeattimer.Interval:=500;
  repeattimer.OnTimer:=RepeatClick;

  DecreaseClick(sender);
end;

procedure TOffsetInfo.IncreaseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if repeattimer<>nil then
    freeandnil(repeattimer);

  if ssCtrl in shift then
    stepsize:=1
  else if ssShift in shift then
    stepsize:=ifthen(processhandler.pointersize=8, 4, 8)
  else
    stepsize:=ifthen(istop, 4, processhandler.pointersize);

  repeatstart:=GetTickCount;
  repeatdirection:=1; //tell the timer to increase
  repeattimer:=TTimer.Create(self.owner.owner);
  repeattimer.Interval:=500;
  repeattimer.OnTimer:=RepeatClick;

  IncreaseClick(sender);
end;

procedure TOffsetInfo.IncreaseDecreaseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //destroy the repeat timer
  if repeattimer<>nil then
    freeandnil(repeattimer);
end;


procedure TOffsetInfo.DecreaseClick(sender: TObject);
begin
  if not fspecial then
    offset:=offset-stepsize;
end;

procedure TOffsetInfo.IncreaseClick(sender: TObject);
begin
  if not fspecial then
    offset:=offset+stepsize;
end;


function TOffsetInfo.getAddressThisPointsTo(var address: ptruint): boolean;
var x: ptruint;
begin
  //use the baseaddress and offset to get to the address

  result:=false;
  if not invalidOffset then
  begin
    address:=0;
    result:=ReadProcessMemory(processhandle, pointer(fBaseAddress+fOffset), @address, processhandler.pointersize, x);
  end;
end;

procedure TOffsetInfo.UpdateLabels;
var Sbase: string;
  Soffset: string;
  Spointsto: string;
  sign: string;
  e: boolean;
  success: boolean;
  a: ptruint;
  newwidth: integer;
begin
  e:=false;
  if owner.error then
  begin
    Sbase:='????????';
    e:=true;
  end
  else
    Sbase:=inttohex(fBaseAddress,8);

  if invalidOffset then
  begin
    sign:='+';
    Soffset:='?';
    e:=true;
  end
  else
  begin
    if fOffset>=0 then
    begin
      sign:='+';
      Soffset:=inttohex(fOffset,1);
    end
    else
    begin
      sign:='-';
      Soffset:=inttohex(-fOffset,1);
    end;
  end;

  if not e then
  begin
    success:=getAddressThisPointsTo(a);
    if success then
      SPointsTo:=inttohex(a,8)
    else
      SPointsTo:='????????';
  end
  else
  begin
    SPointsTo:='????????';
  end;

  if istop then
  begin
    if e then
      lblPointerAddressToValue.Caption:=sbase+sign+soffset+' = ????????'
    else
    begin
      if processhandler.is64bit then
        lblPointerAddressToValue.Caption:=sbase+sign+soffset+' = '+inttohex(qword(fBaseAddress+offset),8)
      else
        lblPointerAddressToValue.Caption:=sbase+sign+soffset+' = '+inttohex(dword(fBaseAddress+offset),8)

    end;
  end
  else
    lblPointerAddressToValue.Caption:='['+sbase+sign+soffset+'] -> '+SPointsTo;

  //update positions
  {
  newwidth:=lblPointerAddressToValue.left+lblPointerAddressToValue.Width;
  if newwidth>owner.ClientWidth then
  begin
    owner.ClientWidth:=newwidth+16;
    owner.owner.ClientWidth:=owner.left+owner.ClientWidth;
  end;   }
end;


procedure TOffsetInfo.setOffset(o: integer); //obsolete, use offsetstring now
begin
  offsetString:=IntToHexSigned(o,1);
end;


function TOffsetInfo.parseOffset: boolean;
var
  e: boolean;
  stack: integer;
  luavm: Plua_state;
begin
  luavm:=GetLuaState;
  finvalidOffset:=true;
  fSpecial:=false;

  result:=true;

  try
    try
      //raise exception.create('bla');
      foffset:=StrToQWordEx(ConvertHexStrToRealStr(fOffsetString));
      finvalidOffset:=false;
    except
      if fOffsetString='' then exit(false);
      fspecial:=true;

      foffset:=symhandler.getAddressFromName(fOffsetString, false, e);
      if e then //try lua
      begin

        stack:=lua_gettop(luavm);
        try
          if luaL_loadstring(luavm, pchar('local memrec, address=... ; return '+fOffsetString))<>0 then exit(false);

          luaclass_newClass(luavm, owner.owner.memoryrecord);
          lua_pushinteger(luavm, fBaseAddress);
          if lua.lua_pcall(Luavm, 2, 1,0)<>0 then exit(false);
          if not lua_isnumber(luavm, -1) then exit(false);

          foffset:=lua_tointeger(Luavm, -1);

        finally
          lua_settop(luavm, stack);
        end;
      end;

      finvalidOffset:=false;
    end;

  finally
    if fInvalidOffset then
      edtOffset.Font.Color:=clRed
    else
      edtOffset.Font.Color:=clWindowtext;
  end;
end;

procedure TOffsetInfo.setOffsetString(os: string);
begin
  fOffsetString:=os;
  parseOffset;

  if (edtOffset.text<>os) then
  begin
    edtOffset.OnChange:=nil;
    edtOffset.text:=fOffsetString;
    edtOffset.OnChange:=offsetchange;
  end;

  owner.processAddress;
  UpdateLabels;
end;

procedure TOffsetInfo.setBaseAddress(address: ptruint);
begin
  fBaseAddress:=address;
  UpdateLabels;
end;

procedure TOffsetInfo.offsetchange(sender: TObject);
begin
  offsetstring:=edtOffset.Text; //raises an exception if invalid
end;

procedure TOffsetInfo.setTop;
begin
  AdjustEditBoxSize(edtOffset,owner.Canvas.GetTextWidth(' XXXX '));
  edtOffset.taborder:=owner.offsets.IndexOf(self);
  istop:=edtOffset.taborder=0;

  sbDecrease.Width:=edtOffset.Height;
  sbDecrease.Height:=edtOffset.Height;
  sbIncrease.Width:=edtOffset.Height;
  sbIncrease.Height:=edtOffset.Height;

end;

destructor TOffsetInfo.destroy;
var i: integer;
  before, after: TOffsetInfo;
begin
  if lblPointerAddressToValue<>nil then
    freeandnil(lblPointerAddressToValue);

  if sbIncrease<>nil then
    freeandnil(sbIncrease);

  if sbDecrease<>nil then
    sbDecrease.AnchorSideTop.Control:=nil;

  if edtOffset<>nil then
  begin
    //find myself in the list, and adjust the previous and next one to point to eachother
    i:=fowner.offsets.IndexOf(self);
    if i<>-1 then
    begin
      if i=0 then before:=nil else before:=fowner.offset[i-1];
      if i=fowner.offsetcount-1 then after:=nil else after:=fowner.offset[i+1];

      if after<>nil then
      begin
        if before=nil then
        begin
          after.edtOffset.AnchorSideTop.Control:=fowner;
          after.edtOffset.AnchorSideTop.Side:=asrTop;
        end
        else
        begin
          after.edtOffset.AnchorSideTop.Control:=before.edtOffset;
          after.edtOffset.AnchorSideTop.Side:=asrBottom;
        end;
      end
      else
      begin
        if before<>nil then
        begin
          fowner.baseAddress.AnchorSideTop.Control:=before.edtOffset;
          fowner.baseAddress.AnchorSideTop.side:=asrBottom;
        end;
      end;

    end;

    freeandnil(edtOffset);
  end;

  if sbDecrease<>nil then
    freeandnil(sbDecrease);

  fowner.offsets.Remove(self);
  inherited destroy;
end;

constructor TOffsetInfo.create(parentPointer: TPointerinfo);
begin
  stepsize:=4;
  fowner:=parentPointer;

  //create a pointeraddress label (visible if not first)
  lblPointerAddressToValue:=TLabel.Create(parentPointer);
  lblPointerAddressToValue.parent:=parentPointer;
  lblPointerAddressToValue.Caption:=' ';
  lblPointerAddressToValue.popupmenu:=parentPointer.owner.pmPointerRow;
  lblPointerAddressToValue.Tag:=ptruint(self);
  if ShouldAppsUseDarkMode() then
    lblPointerAddressToValue.Font.Color:=$ff7f00 //inccolor(clBlue,32)
  else
    lblPointerAddressToValue.Font.Color:=clBlue;
  lblPointerAddressToValue.Font.Underline:=true;

  //an offset editbox
  fOffset:=0;
  fOffsetString:='0';
  edtOffset:=Tedit.create(parentPointer);
  edtOffset.parent:=parentPointer;
  edtOffset.Text:='0';

  edtOffset.Alignment:=taCenter;
  edtOffset.OnChange:=OffsetChange;
  edtOffset.PopupMenu:=parentPointer.owner.pmOffset;
  edtOffset.Tag:=ptrint(self);


  //two buttons, one for + and one for -
  sbDecrease:=TSpeedButton.create(parentPointer);
  sbDecrease.parent:=parentPointer;

  sbDecrease.Height:=edtOffset.Height;
  sbDecrease.Width:=sbDecrease.Height;
  sbDecrease.AnchorSideTop.Control:=edtOffset;
  sbDecrease.AnchorSideTop.Side:=asrCenter;
  sbDecrease.AnchorSideLeft.Control:=parentPointer;
  sbDecrease.AnchorSideLeft.Side:=asrLeft;
  sbDecrease.caption:='<';
  sbDecrease.OnMouseDown:=DecreaseDown;
  sbDecrease.OnMouseUp:=IncreaseDecreaseUp;


  sbIncrease:=TSpeedButton.create(parentPointer);
  sbIncrease.parent:=parentPointer;
  sbIncrease.height:=sbDecrease.height;
  sbIncrease.width:=sbDecrease.width;
  sbIncrease.AnchorSideTop.Control:=edtOffset;
  sbIncrease.AnchorSideTop.Side:=asrCenter;
  sbIncrease.AnchorSideLeft.Control:=edtOffset;
  sbIncrease.AnchorSideLeft.Side:=asrRight;
  sbIncrease.Anchors:=[akTop, akLeft];
  sbIncrease.caption:='>';
  sbIncrease.OnMouseDown:=IncreaseDown;
  sbIncrease.OnMouseUp:=IncreaseDecreaseUp;

  edtOffset.width:=owner.canvas.GetTextWidth(' XXXX ');


  edtOffset.AnchorSideLeft.Control:=sbDecrease;
  edtOffset.AnchorSideLeft.Side:=asrRight;
  edtOffset.BorderSpacing.Bottom:=2;

  lblPointerAddressToValue.AnchorSideTop.Control:=edtOffset;
  lblPointerAddressToValue.AnchorSideTop.Side:=asrCenter;
  lblPointerAddressToValue.AnchorSideLeft.Control:=sbIncrease;
  lblPointerAddressToValue.AnchorSideLeft.Side:=asrRight;
  lblPointerAddressToValue.BorderSpacing.Left:=3;
end;

{%endregion TOffsetInfo }

{%region TPointerInfo }

procedure TPointerInfo.AddOffsetClick(sender: TObject);
var
  offsetVar, newOffset: TOffsetInfo;
  insertInsteadOfAdd: boolean;
begin

  //check if ctrl is pressed, if so, insert instead of append (or the other way depending on settings)

  insertInsteadOfAdd:=not formsettings.cbOldPointerAddMethod.checked; //append pointerline instead of insert

  if (((GetKeyState(VK_CONTROL) shr 15) and 1)=1) then
    insertInsteadOfAdd:=not insertInsteadOfAdd;

  newOffset:=TOffsetInfo.Create(self);

  if insertInsteadOfAdd then
  begin

    // Index from 0 to count-1 === Textboxes from Top to Bottom
    if offsets.Count>0 then
    begin

      offsetVar:=offsets[0];

      offsetVar.edtOffset.AnchorSideTop.control:=newOffset.edtOffset;
      offsetVar.edtOffset.AnchorSideTop.side:=asrBottom;
    end;

    newOffset.edtOffset.AnchorSideTop.Control:=self;
    newOffset.edtOffset.AnchorSideTop.Side:=asrTop;

    offsets.Insert(0, newOffset);
  end
  else
  begin

    if offsets.Count>0 then
    begin

      offsetVar:=offsets[offsets.Count-1];

      newOffset.edtOffset.AnchorSideTop.Control:=offsetVar.edtOffset;
      newOffset.edtOffset.AnchorSideTop.Side:=asrBottom;
    end;

    self.baseAddress.AnchorSideTop.Control:=newOffset.edtOffset;
    self.baseAddress.AnchorSideTop.side:=asrBottom;

    offsets.Add(newOffset);
  end;

  setupPositionsAndSizes;
end;

procedure TPointerInfo.RemoveOffsetClick(sender: TObject);
var insertinsteadofadd: boolean;
  o: TOffsetInfo;
begin
  insertinsteadofadd:=not formsettings.cbOldPointerAddMethod.checked; //append pointerline instead of insert
  if (((GetKeyState(VK_CONTROL) shr 15) and 1)=1) then
    insertinsteadofadd:=not insertinsteadofadd;

  if insertinsteadofadd then //remove the first offset in the list
  begin
    o:=TOffsetinfo(offsets[0]);
    baseAddress.AnchorSideRight.Control:=nil;
  end
  else
    o:=TOffsetInfo(offsets[offsets.Count-1]);

  o.free;

  if offsets.Count>0 then
  begin
    baseAddress.AnchorSideRight.Control:=offset[0].sbIncrease;
    setupPositionsAndSizes;
  end
  else
    selfdestruct;
end;

procedure TPointerInfo.selfdestruct;
begin
  postmessage(owner.handle, WM_disablePointer, 0,0);
end;

function TPointerInfo.getValueLeft: integer;
begin
  result:=baseValue.left;
end;

function TPointerInfo.getOffset(index: integer): TOffsetInfo;
begin
  result:=TOffsetInfo(offsets[index]);
end;

function TPointerInfo.getoffsetcount: integer;
begin
  result:=offsets.Count;
end;

function TPointerInfo.getAddressThisPointsTo(var address: ptruint): boolean;
var x: ptruint;
begin
  result:=false;
  if not InvalidBaseAddress then
  begin
    address:=0; //clear all bits
    result:=ReadProcessMemory(processhandle, pointer(fBaseAddress), @address, processhandler.pointersize, x);
  end;
end;



procedure TPointerInfo.basechange(sender: Tobject);
var e: boolean;
begin

  if (owner.memoryrecord<>nil) then
    e:=not owner.memoryrecord.parseAddressString(utf8toansi(baseAddress.text),fBaseAddress)
  else
    fBaseAddress:=symhandler.getAddressFromName(utf8toansi(baseAddress.text),false,e);

  fInvalidBaseAddress:=e;

  if fInvalidBaseAddress then
    baseAddress.Font.Color:=clRed
  else
    baseAddress.Font.Color:=clWindowtext;

  processAddress;
end;

procedure TPointerInfo.processAddress;
var base: PtrUInt;
  i: integer;
  e: boolean;
begin
  ferror:=not getAddressThisPointsTo(base);

  if error then
    baseValue.caption:='->????????'
  else
    baseValue.caption:='->'+inttohex(base,8);

  for i:=offsetcount-1 downto 1 do
  begin
    offset[i].baseaddress:=base;
    if offset[i].Special then
      offset[i].parseOffset;

    if not offset[i].getAddressThisPointsTo(base) then
      ferror:=true; //signal an error to all subsequent offsets
  end;

  //add the last offset
  offset[0].baseaddress:=base;
  offset[0].parseOffset;
  base:=base+offset[0].offset;

  if error then
    owner.editAddress.text:='????????'
  else
    owner.editAddress.text:=inttohex(base,8);
end;

procedure TPointerInfo.DoOnResize;
//resize editboxes so the full width is used
var minwidth: integer;
  i: integer;
  r: integer;
  rightmost: integer;
  grow: integer;

  neweditwidth: integer;
begin
  inherited DoOnResize;

  if offsetcount>0 then
  begin
    minwidth:=canvas.GetTextWidth(' XXXX ');

    rightmost:=0;
    for i:=0 to offsetcount-1 do
      rightmost:=max(rightmost,  offset[i].lblPointerAddressToValue.left+offset[i].lblPointerAddressToValue.Width);

    rightmost:=rightmost+canvas.GetTextWidth('  ');

    grow:=clientwidth-rightmost; //can be negative

    neweditwidth:=max(offset[0].edtOffset.Width+grow, minwidth);

    for i:=0 to offsetcount-1 do
      offset[i].edtOffset.width:=neweditwidth;
  end;
end;


procedure TPointerInfo.setupPositionsAndSizes;
var
  i: integer;
begin
  for i:=0 to offsets.count-1 do
    TOffsetInfo(offsets[i]).setTop();

  btnAddOffset.top:=baseAddress.top+baseAddress.Height+3;
  btnRemoveOffset.top:=btnAddOffset.top;

  processAddress;

  ClientHeight:=btnAddOffset.Top+btnAddOffset.Height+3;       //triggers onresize
  //Width will be set using the UpdateLabels method of individial offsets when the current offset is too small


  //update buttons of the form
  {
  with owner do
  begin
    ClientHeight:=btnOk.top+btnOk.Height+3;
    ClientWidth:=self.ClientWidth+self.Left;
  end; }


end;

procedure TPointerInfo.addOffsetAroundSelectedOffset(const addAbove: boolean; const selectedOffset: TOffsetInfo);
var
  offsetBeforeNew,newOffset,offsetAfterNew: TOffsetInfo;
  currentOffsetIndex: Integer;
begin

  newOffset:=TOffsetInfo.Create(self);

  offsetBeforeNew:=nil;
  offsetAfterNew:=nil;

  currentOffsetIndex:= offsets.IndexOf(selectedOffset);

  // Above is smaller index
  if addAbove then
  begin
    offsetAfterNew:=selectedOffset;

    if currentOffsetIndex-1  >= 0 then
    begin
      offsetBeforeNew:=offsets[currentOffsetIndex-1];
    end;

    offsets.Insert(currentOffsetIndex, newOffset);
  end
  else
  begin
    offsetBeforeNew:=selectedOffset;

    if (currentOffsetIndex+1)<(offsets.Count - 1) then
    begin
      offsetAfterNew:=offsets[currentOffsetIndex+1];
    end;

    offsets.Insert(currentOffsetIndex+1, newOffset);
  end;

  if offsetBeforeNew<>nil then
  begin
    newOffset.edtOffset.AnchorSideTop.Control:=offsetBeforeNew.edtOffset;
    newOffset.edtOffset.AnchorSideTop.Side:=asrBottom;
  end
  else
  begin
    newOffset.edtOffset.AnchorSideTop.Control:=self;
    newOffset.edtOffset.AnchorSideTop.Side:=asrTop;
  end;

  if offsetAfterNew<>nil then
  begin
    offsetAfterNew.edtOffset.AnchorSideTop.control:=newOffset.edtOffset;
    offsetAfterNew.edtOffset.AnchorSideTop.side:=asrBottom;
  end
  else
  begin
    baseAddress.AnchorSideTop.Control:=newOffset.edtOffset;
    baseAddress.AnchorSideTop.side:=asrBottom;
  end;

  setupPositionsAndSizes

end;

procedure TPointerInfo.appendOffset(newOffset: TOffsetInfo);
var
  offsetVar: TOffsetInfo;
begin

  if offsets.Count>0 then
  begin

    offsetVar:=offsets[offsets.Count-1];

    newOffset.edtOffset.AnchorSideTop.Control:=offsetVar.edtOffset;
    newOffset.edtOffset.AnchorSideTop.Side:=asrBottom;
  end;

  self.baseAddress.AnchorSideTop.Control:=newOffset.edtOffset;
  self.baseAddress.AnchorSideTop.side:=asrBottom;

  offsets.Add(newOffset);

end;

destructor TPointerInfo.destroy;
begin
  if offsets<>nil then
    while offsets.count>0 do //destruction of a offset removes it automagically from the list
      TOffsetInfo(offsets[0]).Free;

  owner.ClientHeight:=owner.btnOk.top+owner.btnOk.Height+3;

  if baseAddress<>nil then
  begin
    owner.editAddress.Text:=baseAddress.Text;
    freeandnil(baseAddress);
  end;

  if baseValue<>nil then
    freeandnil(baseValue);

  if btnAddOffset<>nil then
    freeandnil(btnAddOffset);

  if btnRemoveOffset<>nil then
    freeandnil(btnRemoveOffset);


  inherited Destroy;
end;

constructor TPointerInfo.create(owner: TformAddressChange);
var
    i: integer;
    m: dword;
    newOffset: TOffsetInfo;
begin
  //create the objects
  inherited create(owner);


  fowner:=owner;
  offsets:=tlist.create;
  parent:=owner;

  BevelOuter:=bvNone;
  //left:=owner.cbPointer.Left;
  //top:=owner.cbPointer.Top+owner.cbPointer.Height+3;

  taborder:=owner.cbPointer.TabOrder+1;

  baseAddress:=tedit.create(self);
  baseAddress.parent:=self;

  baseAddress.AnchorSideLeft.Control:=self;
  baseAddress.AnchorSideLeft.Side:=asrLeft;
  //baseAddress.left:=0;

  {$ifdef windows}
  if WindowsVersion>=wvVista then
    m:=sendmessage(baseAddress.Handle, EM_GETMARGINS, 0,0)
  else
  {$endif}
    m:=10;

  m:=(m shr 16)+(m and $ffff);

  if ProcessHandler.is64Bit then
    baseAddressMinWidth:=max(128, Canvas.TextWidth(' DDDDDDDDDDDDDDDD ')+m)
  else
    baseAddressMinWidth:=max(88, Canvas.TextWidth(' DDDDDDDD ')+m);

  baseAddress.ClientWidth:=baseAddressMinWidth;
  baseAddress.Constraints.MinWidth:=baseAddressMinWidth;

  baseAddress.Text:=owner.editAddress.Text;
  baseAddress.OnChange:=basechange;
//  baseAddress.OnResize:=baseaddressresize;;




  baseValue:=tlabel.create(self);
  baseValue.caption:=' ';
  baseValue.parent:=self;
  baseValue.AnchorSideLeft.Control:=baseAddress;
  baseValue.AnchorSideLeft.Side:=asrRight;
  baseValue.BorderSpacing.Left:=3;

  baseValue.AnchorSideTop.Control:=baseAddress;
  baseValue.AnchorSideTop.Side:=asrCenter;

//  baseValue.left:=baseAddress.left+baseAddress.Width+3;
//  baseValue.top:=baseAddress.Top+(baseAddress.Height div 2)-(baseValue.height div 2);

  btnAddOffset:=Tbutton.Create(self);
  btnAddOffset.caption:=rsACAddOffset;
  btnAddOffset.ShowHint:=true;
  btnAddOffset.Hint:=rsACAddOffsetHint;

  btnAddOffset.AnchorSideLeft.Control:=self;
  btnAddOffset.AnchorSideLeft.Side:=asrLeft;

  //btnAddOffset.Left:=0;
  btnAddOffset.Constraints.MinWidth:=owner.btnOk.Width;
  btnAddOffset.Constraints.MinHeight:=owner.btnOk.Height;
  btnAddOffset.OnClick:=AddOffsetClick;
  btnAddOffset.parent:=self;


  btnRemoveOffset:=TButton.create(self);
  btnRemoveOffset.caption:=rsACRemoveOffset;
  btnRemoveOffset.ShowHint:=true;
  btnRemoveOffset.Hint:=rsACRemoveOffsetHint;

  btnRemoveOffset.AnchorSideLeft.Control:=btnAddOffset;
  btnRemoveOffset.AnchorSideLeft.Side:=asrRight;
  btnRemoveOffset.BorderSpacing.Left:=owner.btnCancel.BorderSpacing.Left;


//  btnRemoveOffset.Left:=owner.btnCancel.left-owner.btnOk.left;
  btnRemoveOffset.Constraints.MinWidth:=owner.btnOk.Width;
  btnRemoveOffset.Constraints.MinHeight:=owner.btnOk.Height;
  btnRemoveOffset.OnClick:=RemoveOffsetClick;
  btnRemoveOffset.parent:=self;



  btnAddOffset.AutoSize:=true;
  btnRemoveOffset.autosize:=true;

  i:=owner.btnok.width;

  if btnAddOffset.Width>i then
    i:=btnAddOffset.width;

  if btnRemoveOffset.width>i then
    i:=btnRemoveOffset.Width;

  btnAddOffset.Constraints.MinWidth:=i;
  btnRemoveOffset.Constraints.MinWidth:=i;


  btnAddOffset.width:=i;
  btnRemoveOffset.width:=i;

  newOffset:=TOffsetInfo.Create(self);

  appendOffset(newOffset);

  baseAddress.AnchorSideRight.Control:=offset[0].sbIncrease;
  baseAddress.AnchorSideRight.side:=asrRight;
  baseAddress.Anchors:=[akLeft, akTop, akRight];


  setupPositionsAndSizes;
end;

{%endregion TPointerInfo }

{%region Tformaddresschange }

procedure Tformaddresschange.setAddress(var address: string; var offsets: TMemrecOffsetList);
var
  i: integer;
  newOffset: TOffsetInfo;
begin
  if system.length(offsets)=0 then
  begin
    //no pointer
    cbPointer.Checked:=false;
    editAddress.Text:=ansitoutf8(address);
  end
  else
  begin
    //pointer
    cbPointer.Checked:=true;
    pointerinfo.baseAddress.Text:=ansitoutf8(address);

    //create offsets
    for i:=pointerinfo.offsetcount to system.length(offsets)-1 do
    begin
      newOffset:=TOffsetInfo.create(pointerinfo);

      pointerinfo.appendOffset(newOffset);
    end;

    pointerinfo.setupPositionsAndSizes;

    for i:=0 to system.length(offsets)-1 do
    begin
      pointerinfo.offset[i].offsetString:=offsets[i].offsetText;
      pointerinfo.offset[i].UpdateInterval:=offsets[i].UpdateInterval;
      pointerinfo.offset[i].OnlyUpdateAfterInterval:=offsets[i].OnlyUpdateAfterInterval;
      pointerinfo.offset[i].OnlyUpdateWithReinterpret:=offsets[i].OnlyUpdateWithReinterpret;
    end;

    pointerinfo.processAddress;
  end;

end;



procedure Tformaddresschange.setDescription(s: string);
begin
  editDescription.Text:=s;
end;

function Tformaddresschange.getDescription: string;
begin
  result:=editDescription.Text;
end;

procedure Tformaddresschange.setUnicode(state: boolean);
begin
  cbunicode.checked:=state;
end;

function Tformaddresschange.getUnicode: boolean;
begin
  result:=cbunicode.checked;
end;

procedure Tformaddresschange.setCodePage(state: boolean);
begin
  cbCodePage.checked:=state;
end;

function Tformaddresschange.getCodePage: boolean;
begin
  result:=cbCodePage.checked;
end;

procedure Tformaddresschange.setStartbit(b: integer);
begin
  case b of
    0: RadioButton1.checked:=true;
    1: RadioButton2.checked:=true;
    2: RadioButton3.checked:=true;
    3: RadioButton4.checked:=true;
    4: RadioButton5.checked:=true;
    5: RadioButton6.checked:=true;
    6: RadioButton7.checked:=true;
    7: RadioButton8.checked:=true;
  end;
end;

function Tformaddresschange.getStartbit: integer;
begin
  result:=0;
  if RadioButton1.checked then
    result:=0
  else
  if RadioButton2.checked then
    result:=1
  else
  if RadioButton3.checked then
    result:=2
  else
  if RadioButton4.checked then
    result:=3
  else
  if RadioButton5.checked then
    result:=4
  else
  if RadioButton6.checked then
    result:=5
  else
  if RadioButton7.checked then
    result:=6
  else
  if RadioButton8.checked then
    result:=7;

end;

procedure Tformaddresschange.sLength(l: integer);
begin
  edtSize.text:=inttostr(l);
end;

function Tformaddresschange.gLength: integer;
begin
  result:=StrToIntDef(edtSize.Text,0)
end;

procedure Tformaddresschange.setVarType(vt: TVariableType);
begin
  cbvarType.onchange:=nil;
  case vt of
    vtBinary: cbvarType.ItemIndex:=0;
    vtByte: cbvarType.ItemIndex:=1;
    vtWord: cbvarType.ItemIndex:=2;
    vtDword: cbvarType.ItemIndex:=3;
    vtQword: cbvarType.ItemIndex:=4;
    vtSingle: cbvarType.ItemIndex:=5;
    vtDouble: cbvarType.ItemIndex:=6;
    vtString: cbvarType.ItemIndex:=7;
    vtByteArray: cbvarType.ItemIndex:=8;
  end;
  cbvarType.onchange:=cbvarTypeChange;
  cbvarTypeChange(cbvarType);
end;

function Tformaddresschange.getVartype: TVariableType;
var i: integer;
begin
  {
  Binary
  Byte
  2 Bytes
  4 Bytes
  8 Bytes
  Float
  Double
  Text
  Array of Bytes
  <custom types>
  }
  i:=cbvarType.ItemIndex;
  case i of
    0: result:=vtBinary;
    1: result:=vtByte;
    2: result:=vtWord;
    3: result:=vtDword;
    4: result:=vtQword;
    5: result:=vtSingle;
    6: result:=vtDouble;
    7: result:=vtString;
    8: result:=vtByteArray;
    else
      result:=vtCustom;
  end;
end;


procedure Tformaddresschange.processaddress;
var
  a: PtrUInt;
  e: boolean;
  s: string;
  wantedsize, size: integer;
  ct: TCustomType;
begin
  //read the address and display the value it points to

  if (memoryrecord<>nil) then
    e:=not memoryrecord.parseAddressString(utf8toansi(editAddress.Text),a)
  else
    a:=symhandler.getAddressFromName(utf8toansi(editAddress.Text),false,e);

  if (not e) and (cbvarType.ItemIndex<>-1) then
  begin
    //get the vartype and parse it

    wantedsize:=StrToIntDef(edtSize.text,1);
    size:=max(30,wantedsize);

    ct:=TcustomType(cbvarType.items.objects[cbvarType.ItemIndex]);
    if ct<>nil then
      size:=ct.bytesize;

    s:='='+readAndParseAddress(a
      , vartype
      , TcustomType(cbvarType.items.objects[cbvarType.ItemIndex])
      , (cbHex.Enabled and cbHex.Checked)
      , (cbSigned.Enabled and cbSigned.Checked)
      , size
    );

    if pnlExtra.visible and (size<>wantedsize) then
      s:=s+'...';

    lblValue.caption:=s;
  end
  else
    lblValue.caption:='=???';



end;


procedure Tformaddresschange.offsetKeyPress(sender: TObject; var key:char);
begin
{  if key<>'-' then hexadecimal(key);
  if cbpointer.Checked then timer1.Interval:=1;   }

end;


procedure TformAddressChange.cbvarTypeChange(Sender: TObject);
begin

  pnlExtra.visible:=cbvarType.itemindex in [0,7,8];
  pnlBitinfo.visible:=cbvarType.itemindex = 0;
  cbunicode.visible:=cbvarType.itemindex = 7;
  cbCodePage.visible:=cbunicode.Visible;

  cbHex.Enabled:=not (cbvarType.itemindex in [0,7]);
  cbSigned.Enabled:=not (cbvarType.itemindex in [0,5,6,7,8]);

  AdjustHeight;

  processaddress;

  Repaint;

 // autosize:=true;
end;

procedure TformAddressChange.btnCancelClick(Sender: TObject);
begin
  modalresult:=mrCancel;
end;

procedure TformAddressChange.cbCodePageChange(Sender: TObject);
begin
  if cbCodePage.checked then
    cbunicode.checked:=false;
end;

procedure TformAddressChange.cbHexChange(Sender: TObject);
begin
  processaddress;
end;

procedure TformAddressChange.cbSignedChange(Sender: TObject);
begin
  processaddress;
end;

procedure TformAddressChange.cbunicodeChange(Sender: TObject);
begin
  if cbunicode.checked then
    cbCodePage.checked:=false;
end;

procedure TformAddressChange.editAddressChange(Sender: TObject);
begin
  processaddress;
end;

procedure TformAddressChange.DelayedResize;
begin
  AdjustHeight;

  clientwidth:=clientwidth+1; //force an update
  clientwidth:=clientwidth-1;
end;

procedure TformAddressChange.PointerInfoResize(sender: TObject);
begin
  AdjustHeight;
end;

procedure TformAddressChange.cbPointerClick(Sender: TObject);
var i: integer;
    startoffset,inputoffset,rowheight: integer;

    a,b,c,d: integer;
    minwidth, grow: integer;
begin
  if cbpointer.checked then
  begin
    if pointerinfo=nil then
    begin
      pointerinfo:=TPointerInfo.create(self); //creation will do the gui update

     // pointerinfo.color:=clred;

      pointerinfo.AnchorSideLeft.Control:=LabelAddress;
      pointerinfo.AnchorSideLeft.side:=asrLeft;

      pointerinfo.AnchorSideTop.Control:=cbPointer;
      pointerinfo.AnchorSideTop.side:=asrBottom;

      pointerinfo.AnchorSideRight.Control:=self;
      pointerinfo.AnchorSideRight.Side:=asrRight;

      pointerinfo.Anchors:=[akLeft,akTop, akRight];

      pointerinfo.OnResize:=PointerInfoResize;

      pointerinfo.baseAddress.OnChange(pointerinfo.baseAddress);

    end;

    //editAddress.enabled:=false;
    editAddress.ReadOnly:=true;
    if ShouldAppsUseDarkMode() then
      editAddress.Color:=$505050
    else
      editAddress.Color:=clInactiveBorder;

    btnOk.AnchorSideTop.Control:=pointerinfo;
    btnCancel.AnchorSideTop.Control:=pointerinfo;


    minwidth:=pointerinfo.offset[0].lblPointerAddressToValue.BoundsRect.Right+canvas.TextWidth('  ');
    minwidth:=max(minwidth, pointerinfo.baseValue.BoundsRect.Right);
    minwidth:=max(minwidth, pointerinfo.btnRemoveOffset.BoundsRect.Right);

    inc(minwidth, pointerinfo.left);

    grow:=minwidth-clientwidth;
    if grow>0 then
      clientwidth:=clientwidth+grow;
  end
  else
  begin
    btnOk.AnchorSideTop.Control:=cbpointer;
    btnCancel.AnchorSideTop.Control:=cbpointer;

    //editAddress.enabled:=true;
    editAddress.ReadOnly:=false;
    editAddress.Color:=clWindow;

    if pointerinfo<>nil then
      freeandnil(pointerinfo);
  end;

  AdjustHeight;
end;

procedure TformAddressChange.DisablePointerExternal(var m: TMessage);
begin
  cbPointer.Checked:=false;
end;

procedure TformAddressChange.AdjustHeight;
begin
  constraints.MinHeight:=btncancel.top+btnCancel.height+6;
  constraints.MaxHeight:=btncancel.top+btnCancel.height+6;
  clientheight:=btncancel.top+btnCancel.height+6;
 // clientwidth:=
end;

procedure TFormAddressChange.ApplyMemoryRecord;
var i: integer;
    tmp:string;

    list: TMemrecOffsetList;
begin
  description:=fMemoryRecord.Description;
  vartype:=fMemoryRecord.VarType;

  setlength(list, fMemoryRecord.offsetCount);
  for i:=0 to fMemoryRecord.offsetCount-1 do
    list[i]:=fMemoryRecord.offsets[i];

  setAddress(fMemoryRecord.interpretableaddress, list);

  case fMemoryRecord.vartype of
    vtBinary:
    begin
      startbit:=fMemoryRecord.Extra.bitData.Bit;
      length:=fMemoryRecord.Extra.bitdata.bitlength;
    end;

    vtString:
    begin
      unicode:=fMemoryRecord.Extra.stringData.unicode;
      codepage:=fMemoryRecord.Extra.stringData.codepage;
      length:=fMemoryRecord.Extra.stringData.length;
    end;

    vtByteArray:
    begin
      length:=fMemoryRecord.Extra.byteData.bytelength;
    end;

    vtCustom:
      cbvarType.ItemIndex:=cbvarType.Items.IndexOf(fMemoryRecord.CustomTypeName);

  end;

  if (fMemoryRecord.vartype = vtByte)
     or (fMemoryRecord.vartype = vtWord)
     or (fMemoryRecord.vartype = vtDword)
     or (fMemoryRecord.vartype = vtQword)
     or (fMemoryRecord.vartype = vtSingle)
     or (fMemoryRecord.vartype = vtDouble)
     or (fMemoryRecord.vartype = vtByteArray)
     then
  begin
    cbHex.checked:=fMemoryRecord.ShowAsHex;
    cbSigned.checked:=fMemoryRecord.ShowAsSigned;
  end
  else
  begin
    cbHex.checked:=false;
    cbSigned.checked:=false;
  end;


  processaddress;
  AdjustHeight;

end;

procedure TformAddressChange.setMemoryRecord(rec: TMemoryRecord);
begin
  fMemoryRecord:=rec;
end;

procedure TformAddressChange.btnOkClick(Sender: TObject);
var bit: integer;
    address: string;
    err:integer;

    paddress: dword;
   // offsets: TIntegerDynArray;

    i: integer;
begin
  memoryrecord.Vartype:=vartype;
  memoryrecord.CustomTypeName:='';


  case vartype of
    vtBinary:
    begin
      memoryrecord.Extra.bitData.Bit:=startbit;
      memoryrecord.Extra.bitData.bitlength:=length;
    end;

    vtString:
    begin
      memoryrecord.Extra.stringData.length:=length;
      memoryrecord.Extra.stringData.unicode:=unicode;
      memoryrecord.Extra.stringData.codepage:=codepage;
    end;

    vtByteArray:
      memoryrecord.Extra.byteData.bytelength:=length;

    vtCustom:
      memoryrecord.CustomTypeName:=cbvarType.Caption;

  end;

  memoryrecord.Description:=description;

  if pointerinfo<>nil then
  begin
    memoryrecord.interpretableaddress:=pointerinfo.baseAddress.text;
    memoryrecord.offsetCount:=pointerinfo.offsetcount;
    for i:=0 to pointerinfo.offsetcount-1 do
    begin
      memoryrecord.offsets[i].setOffsetText(pointerinfo.offset[i].offsetString);
      memoryrecord.offsets[i].UpdateInterval:=pointerinfo.offset[i].UpdateInterval;
      memoryrecord.offsets[i].OnlyUpdateAfterInterval:=pointerinfo.offset[i].OnlyUpdateAfterInterval;
      memoryrecord.offsets[i].OnlyUpdateWithReinterpret:=pointerinfo.offset[i].OnlyUpdateWithReinterpret;
    end;
  end
  else
  begin
    memoryrecord.interpretableaddress:=editAddress.text;
    memoryrecord.offsetCount:=0;
  end;

  if (vartype<>vtString)
     and (vartype<>vtBinary)
     then
  begin
    memoryrecord.ShowAsHex:=cbHex.Checked;
    memoryrecord.ShowAsSigned:=cbSigned.Checked;
  end
  else
  begin
    memoryrecord.ShowAsHex:=false;
    memoryrecord.ShowAsSigned:=false;
  end;


  memoryrecord.ReinterpretAddress;


  modalresult:=mrok;
end;

procedure TformAddressChange.FormCreate(Sender: TObject);
var i: integer;
begin
  //fill the varlist with custom types
  cbvarType.Items.Clear;
  cbvarType.items.add(rs_vtBinary);
  cbvarType.items.add(rs_vtByte);
  cbvarType.items.add(rs_vtWord);
  cbvarType.items.add(rs_vtDword);
  cbvarType.items.add(rs_vtQword);
  cbvarType.items.add(rs_vtSingle);
  cbvarType.items.add(rs_vtDouble);
  cbvarType.items.add(rs_vtString);
  cbvarType.items.add(rs_vtByteArray);


  for i:=0 to customTypes.Count-1 do
    cbvarType.Items.AddObject(TCustomType(customtypes[i]).name, customtypes[i]);


  cbvarType.DropDownCount:=cbvarType.Items.Count;

  if LoadFormPosition(self) then
  begin
    loadedWidth:=true;
    autosize:=false;
  end;
end;

procedure TformAddressChange.FormDestroy(Sender: TObject);
begin
  if shown then
    SaveFormPosition(Self);

  if pointerinfo<>nil then
    freeandnil(pointerinfo);
end;

procedure TformAddressChange.FormResize(Sender: TObject);
var newwidth: integer;
begin
  newwidth:=clientwidth-editaddress.left-lblValue.Width-canvas.GetTextWidth('   ');
  newwidth:=min(cbvartype.width, newwidth);
  newwidth:=max(newwidth, canvas.TextWidth('DDDDDDDDDD'));

  editaddress.width:=newwidth;
end;

procedure TformAddressChange.FormShow(Sender: TObject);
var i: integer;
    m: dword;
    h: THandle;
    r: trect;
    w: integer;
begin
  {$ifdef windows}
  if WindowsVersion>=wvVista then
  begin
    zeromemory(@r, sizeof(r));
    sendmessage(radiobutton1.Handle, BCM_SETTEXTMARGIN , 0, ptruint(@r));
    sendmessage(radiobutton2.Handle, BCM_SETTEXTMARGIN , 0, ptruint(@r));
    sendmessage(radiobutton3.Handle, BCM_SETTEXTMARGIN , 0, ptruint(@r));
    sendmessage(radiobutton4.Handle, BCM_SETTEXTMARGIN , 0, ptruint(@r));
    sendmessage(radiobutton5.Handle, BCM_SETTEXTMARGIN , 0, ptruint(@r));
    sendmessage(radiobutton6.Handle, BCM_SETTEXTMARGIN , 0, ptruint(@r));
    sendmessage(radiobutton7.Handle, BCM_SETTEXTMARGIN , 0, ptruint(@r));
    sendmessage(radiobutton8.Handle, BCM_SETTEXTMARGIN , 0, ptruint(@r));

    m:=sendmessage(editAddress.Handle, EM_GETMARGINS, 0,0);
  end
  else
  {$endif}
    m:=10;

  m:=(m shr 16)+(m and $ffff);

  {$ifdef cpu32}
    editAddress.ClientWidth:=canvas.TextWidth('DDDDDDDD')+m;
  {$else}
    editAddress.ClientWidth:=canvas.TextWidth('DDDDDDDDDDDD')+m;
  {$endif}

  //calculate vartpe maxwidth (looks ugly if stretched too far)
  w:=editAddress.width;
  for i:=0 to cbvarType.Items.Count-1 do
    w:=max(w, canvas.TextWidth(cbvarType.Items[i]));

  cbvarType.Constraints.MaxWidth:=2*w;



  lblValue.Constraints.MinWidth:=canvas.TextWidth('=XXXXX');





  i:=80;
  btnOk.autosize:=true;
  btnCancel.autosize:=true;

  btnOk.autosize:=false;
  btnCancel.autosize:=false;

  if btnok.width>i then
    i:=btnok.width;

  if btnCancel.width>i then
    i:=btnCancel.width;

  btnok.width:=i;
  btncancel.width:=i;

  if autosize=false then //form position got loaded
    OnResize(self);

  if autosize then
  begin
    autosize:=false;
    autosize:=true;
    autosize:=false;
  end;


  if fMemoryRecord<>nil then
    ApplyMemoryRecord;

  processaddress;
  AdjustHeight;
  Repaint;

  shown:=true;

  HexAndSignedPanel.AutoSize:=false;
  HexAndSignedPanel.AutoSize:=true;
  if loadedWidth=false then
  begin
    //get the best width
    w:=max(cbvarType.left*2+cbvarType.width,pnlExtra.left*2+pnlExtra.width);
    w:=max(w,width);
    w:=max(w,HexAndSignedPanel.left*2+HexAndSignedPanel.width);
    w:=max(w,HexAndSignedPanel.left*2+cbSigned.Left+cbSigned.width+8);
    clientwidth:=w+BorderWidth*3;

    loadedWidth:=true;
  end;

  if focusDescription then
    editDescription.SetFocus;


   //autosize:=true;
end;

procedure TformAddressChange.miCopyFinalAddressToClipboardClick(Sender: TObject);
var e: boolean;
    a: ptruint;
begin
  if (memoryrecord<>nil) then
    e:=not memoryrecord.parseAddressString(utf8toansi(editAddress.Text),a)
  else
    a:=symhandler.getAddressFromName(utf8toansi(editAddress.Text),false,e);

  if not e then
    Clipboard.AsText:=inttohex(a,8);
end;

procedure TformAddressChange.miCopyValueToClipboardClick(Sender: TObject);
begin
  Clipboard.AsText:=copy(lblValue.Caption,2);
end;

procedure TformAddressChange.miAddAddressToListClick(Sender: TObject);
var
  oi: TOffsetInfo;
  a: ptruint;
  i: integer;
  index: integer;
  mr: TMemoryRecord;
begin
  if processhandler.is64bit then
    vartype:=vtQword
  else
    vartype:=vtDword;

  if pmPointerRow.PopupComponent is TLabel then
  begin
    oi:=TOffsetInfo(tlabel(pmPointerRow.PopupComponent).tag);

    index:=-1;
    for i:=0 to oi.owner.offsetcount-1 do
      if oi.owner.offset[i]=oi then
      begin
        index:=i;
        break;
      end;

    if oi.getAddressThisPointsTo(a) then
    begin
      //readable
      a:=oi.baseAddress+oi.offset;
      mr:=MainForm.addresslist.addaddress(editDescription.text+' offset '+inttostr(index), inttohex(a,8),[],0,vartype);

      if ssctrl in GetKeyShiftState then
      begin
        //the whole pointer up till this position
        mr.OffsetCount:=index+1;
        for i:=0 to index do
          mr.offsets[i].offsetText:=oi.owner.offset[i].edtOffset.text;
      end;
      mr.ShowAsHex:=true;
    end;
  end;
end;

procedure TformAddressChange.miCopyAddressToClipboardClick(Sender: TObject);
var
  oi: TOffsetInfo;
  a: ptruint;
  i: integer;
  index: integer;
  addressStr: string;
begin

  if processhandler.is64bit then
    vartype:=vtQword
  else
    vartype:=vtDword;

  if not (pmPointerRow.PopupComponent is TLabel) then
    exit;

  clipboard.Clear;

  oi:=TOffsetInfo(tlabel(pmPointerRow.PopupComponent).tag);

  index:=-1;
  for i:=0 to oi.owner.offsetcount-1 do
  begin
    if oi.owner.offset[i]=oi then
    begin
      index:=i;
      break;
    end;
  end;

  if oi.getAddressThisPointsTo(a) then
  begin

    a:=oi.baseAddress+oi.offset;

    addressStr:=inttohex(a,8);

    clipboard.AsText:=addressStr;

  end;

end;

procedure TformAddressChange.miAddOffsetAboveClick(Sender: TObject);
var
  selectedOffset: TOffsetInfo;
  pointerInfo: TPointerinfo;
  teditOffest: Tedit;
begin

  if not (pmOffset.PopupComponent is Tedit) then
    exit;

  teditOffest:=tedit(pmOffset.PopupComponent);

  selectedOffset:=TOffsetInfo(teditOffest.tag);

  pointerInfo:=selectedOffset.owner;

  pointerInfo.addOffsetAroundSelectedOffset(true, selectedOffset);

end;

procedure TformAddressChange.miAddOffsetBelowClick(Sender: TObject);
var
  selectedOffset: TOffsetInfo;
  pointerInfo: TPointerinfo;
  teditOffest: Tedit;
begin

  if not (pmOffset.PopupComponent is Tedit) then
    exit;

  teditOffest:=tedit(pmOffset.PopupComponent);

  selectedOffset:=TOffsetInfo(teditOffest.tag);

  pointerInfo:=selectedOffset.owner;

  pointerInfo.addOffsetAroundSelectedOffset(false, selectedOffset);

end;

procedure TformAddressChange.miRemoveOffsetClick(Sender: TObject);
  var
  o: TOffsetInfo;
  pointerInfo: TPointerinfo;
  teditOffest: Tedit;
begin

  if not (pmOffset.PopupComponent is Tedit) then
    exit;

  teditOffest:=tedit(pmOffset.PopupComponent);

  o:=TOffsetInfo(teditOffest.tag);

  pointerInfo:=o.owner;

  o.free;

  if pointerInfo.offsets.Count>0 then
    pointerInfo.setupPositionsAndSizes
  else
    pointerInfo.selfdestruct;

end;

procedure TformAddressChange.miCopyClick(Sender: TObject);
begin
  if (pmOffset.PopupComponent is Tedit) then tedit(pmOffset.PopupComponent).CopyToClipboard;
end;

procedure TformAddressChange.miCutClick(Sender: TObject);
begin
  if (pmOffset.PopupComponent is Tedit) then tedit(pmOffset.PopupComponent).CutToClipboard;
end;

procedure TformAddressChange.miPasteClick(Sender: TObject);
begin
  if (pmOffset.PopupComponent is Tedit) then tedit(pmOffset.PopupComponent).PasteFromClipboard;
end;

procedure TformAddressChange.miUpdateAfterIntervalClick(Sender: TObject);
var
  oi: TOffsetInfo;
  v: string;
begin

  if pmOffset.PopupComponent is TEdit then
  begin
    oi:=TOffsetInfo(tedit(pmOffset.PopupComponent).tag);
    if oi.OnlyUpdateAfterInterval=false then
    begin
      if oi.UpdateInterval=0 then
        oi.UpdateInterval:=1000;

      v:=inttostr(oi.UpdateInterval);
      if InputQuery('Offset update','Enter the interval in which the offset should be updated. In milliseconds', v) then
        oi.UpdateInterval:=strtoint(v);
    end;

    oi.OnlyUpdateAfterInterval:=miUpdateAfterInterval.Checked;
  end;
end;

procedure TformAddressChange.miUpdateOnReinterpretOnlyClick(Sender: TObject);
var oi: TOffsetInfo;
begin

  if pmOffset.PopupComponent is TEdit then
  begin
    oi:=TOffsetInfo(tedit(pmOffset.PopupComponent).tag);
    oi.OnlyUpdateWithReinterpret:=miUpdateOnReinterpretOnly.Checked;
  end;
end;

procedure TformAddressChange.pmOffsetPopup(Sender: TObject);
var oi: TOffsetInfo;
begin

  if pmOffset.PopupComponent is TEdit then
  begin
    oi:=TOffsetInfo(tedit(pmOffset.PopupComponent).tag);

    miUpdateSeparator.visible:=oi.special;
    miUpdateOnReinterpretOnly.visible:=oi.special;
    miUpdateAfterInterval.visible:=oi.special;

    miUpdateOnReinterpretOnly.Checked:=oi.fReinterpretUpdateOnly;
    miUpdateAfterInterval.Checked:=oi.fOnlyUpdateAfterInterval;

 //   clipboard.;
    miCut.enabled:=oi.edtOffset.SelLength>0;
    miCopy.enabled:=miCut.enabled;
    miPaste.enabled:=Clipboard.AsText<>'';

  end;
end;

procedure TformAddressChange.pnlExtraResize(Sender: TObject);
begin
  asm
  nop
  end;
end;

procedure TformAddressChange.Timer1Timer(Sender: TObject);
begin
{  if cbvarType.DroppedDown then
    autosize:=false
  else
  begin
    if autosize=false then
      autosize:=true;
  end; }


  timer1.Interval:=1000;
  if visible and cbpointer.checked then
    if pointerinfo<>nil then
      pointerinfo.processaddress;

  processaddress;
end;

procedure TformAddressChange.Timer2Timer(Sender: TObject);
begin
  //lazarus bug bypass for not setting proper width when the window is not visible, and no event to signal when it's finally visible (onshow isn't one of them)
  DelayedResize;

  timer2.enabled:=false;
end;

{%endregion Tformaddresschange }

initialization
  {$i formAddressChangeUnit.lrs}

end.
