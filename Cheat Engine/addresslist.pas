unit addresslist;

{$warn 3057 off}

{$mode DELPHI}



interface

uses
  LCLIntf, LCLType, Classes, SysUtils, controls, stdctrls, comctrls, ExtCtrls, graphics,
  math, MemoryRecordUnit, FPCanvas, CEFuncProc, NewKernelHandler, menus,dom,
  XMLRead,XMLWrite, symbolhandler, AddresslistEditor, inputboxtopunit,
  frmMemrecComboboxUnit, commonTypeDefs, multilineinputqueryunit, LazUTF8, StringHashList, betterControls;

type
  TTreeviewWithScroll=class(TTreeview)
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  published
    property ScrolledTop;
  end;

type
  TDropByListviewEvent=procedure(sender: TObject; node: TTreenode; attachmode: TNodeAttachMode) of object;
  TCompareRoutine=function(a: tmemoryrecord; b: tmemoryrecord): integer of object;
  TMemRecChangeEvent=function(sender: TObject; memrec: TMemoryRecord):boolean of object;



  TAddresslist=class(TPanel)
  private
    lastSelected: integer;

    header: THeaderControl;
    headerpopup: TPopupMenu;
    miSortOnClick: TMenuItem;
    Treeview: TTreeviewWithScroll; //TTreeview;//WithScroll;
    CurrentlyDraggedOverNode: TTreenode;
    CurrentlyDraggedOverBefore: boolean; //set to true if inserting before
    CurrentlyDraggedOverAfter: boolean; //set to true if inserting after
    fOnDropByListview: TDropByListviewEvent;
    fOnAutoAssemblerEdit: TMemRecChangeEvent;

    activesortdirection: boolean;
    descriptionsortdirection: boolean;
    addresssortdirection: boolean;
    valuetypesortdirection: boolean;
    valuesortdirection: boolean;

    AddressListEditor: TAddressListEditor;

    fCheckboxActiveSelectedColor: TColor;
    fCheckboxActiveColor: TColor;

    fCheckboxSelectedColor: TColor;
    fCheckboxColor: TColor;
    fSelectedBackgroundColor: TColor;
    fSelectedSecondaryBackgroundColor: TColor;
    fExpandSignColor: TColor;
    fDecreaseArrowColor: TColor;
    fIncreaseArrowColor: TColor;

    fOnDescriptionChange: TMemRecChangeEvent;
    fOnAddressChange: TMemRecChangeEvent;
    fOnTypeChange: TMemRecChangeEvent;
    fOnValueChange: TMemRecChangeEvent;

    animationtimer: TTimer;
    expandsignsize: integer;

    sortlevel0only: boolean;

    descriptionhashlist: TStringhashList;

    procedure doAnimation(sender: TObject);

    function getTreeNodes: TTreenodes;
    procedure setTreeNodes(t: TTreenodes);

    //Rendering happens here...
    procedure AdvancedCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
    //^^^

    procedure SelectionUpdate(sender: TObject);
    procedure sectiontrack(HeaderControl: TCustomHeaderControl; Section: THeaderSection; Width: Integer; State: TSectionTrackState);
    procedure sectionClick(HeaderControl: TCustomHeaderControl; Section: THeaderSection);
    procedure FocusChange(sender: TObject);
    procedure TVDragOver(Sender, Source: TObject; X,Y: Integer; State: TDragState; var Accept: Boolean);
    procedure TVDragDrop(Sender, Source: TObject; X,Y: Integer);
    procedure TVDragEnd(Sender, Target: TObject; X,Y: Integer);
    procedure TreeviewOnCollapse(Sender: TObject; Node: TTreeNode; var AllowCollapse: Boolean);
    procedure TreeviewOnExpand(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
    procedure TreeviewDblClick(Sender: TObject);
    procedure TreeviewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

   // procedure TreeviewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure EditorDoubleclick(sender: tobject); //callback
    procedure MultiEdit(memrec: Tmemoryrecord);

    procedure descriptiondblclick(node: TTreenode);
    procedure addressdblclick(node: TTreenode);
    procedure typedblclick(node: TTreenode);
    procedure valuedblclick(node: TTreenode);
    procedure valueclick(node: TTreenode);
    function GetCount: integer;
    function GetSelcount: integer;
    function GetMemRecItemByIndex(i: integer): TMemoryRecord;
    procedure setPopupMenu(menu: TPopupMenu);
    {$warn 3057 off}
    function getPopupMenu: TPopupMenu; //on purpose
    function getSelectedRecord: TMemoryRecord;
    procedure setSelectedRecord(memrec: TMemoryrecord);

    function hasSelectedParent(memrec: TMemoryRecord): boolean;

    function CheatTableNodeHasOnlyAutoAssemblerScripts(CheatTable: TDOMNode): boolean; //helperfunction
    procedure CheatTableNodeCheckForRelativeAddress(CheatTable: TDOMNode; var hasRelative, allRelative: boolean); //helperprocedure


    procedure sort(firstnode: ttreenode; compareRoutine: TTreeNodeCompare; direction: boolean);
    procedure SymbolsLoaded(sender: TObject);
    procedure miSortOnClickClick(sender: TObject);
  public
    //needsToReinterpret: boolean;
    procedure rebuildDescriptionCache;
    procedure MemrecDescriptionChange(memrec: TMemoryRecord; olddescription, newdescription: string);
    procedure getAddressList(list: Tstrings);

    function focused:boolean; override;

    function activecompare(_a: TTreenode; _b: TTreenode): integer;
    procedure sortByActive;
    function descriptioncompare(_a: TTreenode; _b: TTreenode): integer;
    function descriptioncomparecasesensitive(_a: TTreenode; _b: TTreenode): integer;
    procedure sortByDescription;
    function addresscompare(_a: TTreenode; _b: TTreenode): integer;
    procedure sortByAddress;
    function valuetypecompare(_a: TTreenode; _b: TTreenode): integer;
    procedure sortByValueType;
    function valuecompare(_a: TTreenode; _b: TTreenode): integer;
    procedure sortByValue;

    procedure RefreshCustomTypes;
    procedure ReinterpretAddresses;
    procedure ApplyFreeze;
    procedure refresh;
    procedure SelectAll;
    procedure saveTableXMLToNode(CheatEntries: TDOMNode; selectedOnly: boolean=false);
    procedure loadTableXMLFromNode(CheatEntries: TDOMNode);
    function GetTableXMLAsText(selectedonly: boolean): string;
    procedure AddTableXMLAsText(xml: string; simpleCopyPaste: boolean=true);
    procedure DeleteSelected(ask: boolean=true);
    procedure ActivateSelected(FreezeType: TFreezeType=ftFrozen); //activates all selected entries in the addresslist
    procedure DeactivateSelected;
    procedure CreateGroup(groupname: string; withAddress: boolean=false);
    procedure addAutoAssembleScript(script: string);
    function addAddressManually(initialaddress: string=''; vartype: TVariableType=vtDword; CustomTypeName: string=''; focusOnDescription: boolean=false): TMemoryRecord;
    function addaddress(description: string; address: string; const offsets: array of integer; offsetcount: integer; vartype: TVariableType; customtypename: string=''; length: integer=0; startbit: integer=0; unicode: boolean=false; node: TTreenode=nil; attachmode: TNodeAttachMode=naAdd): TMemoryRecord;
    function getRecordWithDescription(description: string): TMemoryRecord;
    function getRecordWithID(id: integer): TMemoryRecord;

    function GetUniqueMemrecId: integer;

    procedure doDescriptionChange;
    procedure doAddressChange;
    procedure doTypeChange;
    procedure doValueChange;

    procedure disableAllWithoutExecute;
    function getMouseHighlightedRecord: TMemoryRecord;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Items: TTreeNodes read getTreeNodes write SetTreeNodes;

    procedure clear;

    function getLoadedTableVersion: integer;


    property MemRecItems[Index: Integer]: TMemoryRecord read GetMemRecItemByIndex; default;

    property OnDropByListview: TDropByListviewEvent read FOnDropByListview write FOnDropByListview;

    procedure DoAutoSize; override;


    property headers: THeaderControl read header;
  published
    property LoadedTableVersion: integer read getLoadedTableVersion;

    property Count: Integer read GetCount;
    property SelCount: Integer read GetSelCount;
    property SelectedRecord: TMemoryRecord read getSelectedRecord write setSelectedRecord;
    property PopupMenu: TpopupMenu read getPopupMenu write setPopupMenu;

    property checkboxActiveSelectedColor: TColor read fCheckboxActiveSelectedColor write fCheckboxActiveSelectedColor;
    property CheckboxActiveColor: TColor read fCheckboxActiveColor write fCheckboxActiveColor;

    property CheckboxSelectedColor: TColor read fCheckboxSelectedColor write fCheckboxSelectedColor;
    property CheckboxColor: TColor read fCheckboxColor write fCheckboxColor;
    property SelectedBackgroundColor: TColor read fSelectedBackgroundColor write fSelectedBackgroundColor;
    property SelectedSecondaryBackgroundColor: TColor read fSelectedSecondaryBackgroundColor write fSelectedSecondaryBackgroundColor;
    property ExpandSignColor: TColor read fExpandSignColor write fExpandSignColor;
    property IncreaseArrowColor: TColor read fIncreaseArrowColor write fIncreaseArrowColor;
    property DecreaseArrowColor: TColor read fDecreaseArrowColor write fDecreaseArrowColor;
    property MouseHighlightedRecord: TMemoryRecord read getMouseHighlightedRecord;
    property OnDescriptionChange: TMemRecChangeEvent read fOnDescriptionChange write fOnDescriptionChange;
    property OnAddressChange: TMemRecChangeEvent read fOnAddressChange write fOnAddressChange;
    property OnTypeChange: TMemRecChangeEvent read fOnTypeChange write fOnTypeChange;
    property OnValueChange: TMemRecChangeEvent read fOnValueChange write fOnValueChange;
    property OnAutoAssemblerEdit: TMemRecChangeEvent read fOnAutoAssemblerEdit write fOnAutoAssemblerEdit;
  end;

implementation

uses dialogs, formAddressChangeUnit, TypePopup, PasteTableentryFRM, MainUnit,
  ProcessHandlerUnit, frmEditHistoryUnit, globals, Filehandler, ceregistry,
  memrecDataStructures, opensave;

resourcestring
  rsDoYouWantToDeleteTheSelectedAddress = 'Do you want to delete the selected address?';
  rsDoYouWantToDeleteTheSelectedAddresses = 'Do you want to delete the selected addresses?';
  rsChangeDescription = 'Change Description';
  rsWhatWillBeTheNewDescription = 'What will be the new description?';
  rsChangeValue = 'Change Value';
  rsWhatValueToChangeThisTo = 'what value to change this to?';
  rsTheValueCouldNotBeParsed = 'The value %s could not be parsed';
  rsNotAllValueTypesCouldHandleTheValue = 'Not all value types could handle '
    +'the value %s';
  rsActive = 'Active';
  rsDescription = 'Description';
  rsAddress = 'Address';
  rsType = 'Type';
  rsValue = 'Value';
  rsScript = '<script>';
  rsALAddAddress = 'Add address';
  rsALNoDescription = 'No description';
  rsALAutoAssembleScritp = 'Auto Assemble script';
  rsSortOnClick = 'Sort on click';

var
  ForbiddenSearchDescriptions: TStringHashList;

procedure TTreeviewWithScroll.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  n: TTreenode;
begin
  //retarded solution for dealing with the expand click
  n:=GetNodeAt(X, Y);
  if n<>nil then
  begin
    if (x<n.DisplayTextLeft) then //before the text
      x:=x+n.DisplayTextLeft+4; //click on the text instead

  end;

  inherited MouseDown(button, shift, x,y);
end;

procedure TAddresslist.refresh;
begin
  if treeview<>nil then
    treeview.Refresh;
end;

procedure TAddresslist.clear;
var
  i: integer;
  item: TMemoryRecord;
begin
  //first check if it's being edited/or busy
  if self=nil then exit;

  for i:=0 to count-1 do
    if (MemRecItems[i].isBeingEdited) or (memrecitems[i].AsyncProcessing) then exit;

  //still here so nothing is being edited, so, delete
  descriptionhashlist.clear;

  while count>0 do
  begin
    item:=MemRecItems[0];
    if item<>nil then
      item.Free;
  end;

  lastLoadedTableVersion:=CurrentTableVersion;
end;

procedure TAddresslist.RefreshCustomTypes;
var i: integer;
begin
  for i:=0 to count-1 do
    MemRecItems[i].RefreshCustomType;
end;

procedure TAddresslist.ReinterpretAddresses;
var i: integer;
  tn: TTreeNode;
begin
 // if symhandler.isloaded and (needsToReinterpret) then
  begin
    RefreshCustomTypes;

    //update 12/31/2011. Reinterpretaddress now also calls it automatically for it's children. So only call for the level 1 entries
    tn:=treeview.Items.GetFirstNode;
    while tn<>nil do
    begin
      TMemoryRecord(tn.data).ReinterpretAddress;
      tn:=tn.GetNextSibling;
    end;

    //needsToReinterpret:=false;
  end;

  //if symhandler.isloaded=false then
  //  needsToReinterpret:=true;
end;

procedure TAddresslist.setPopupMenu(menu: TPopupMenu);
begin
  treeview.popupmenu:=menu;
end;

function TAddresslist.getPopupMenu: TPopupMenu;
begin
  result:=treeview.popupmenu;
end;

function TAddresslist.hasSelectedParent(memrec: TMemoryRecord): boolean;
begin
  if memrec.parent=nil then
    result:=false
  else
  begin
    if memrec.parent.isSelected then
      result:=true
    else
      result:=hasSelectedParent(memrec.parent);
  end;
end;

procedure TAddresslist.setSelectedRecord(memrec: TMemoryrecord);
var i: integer;
begin
  for i:=0 to count-1 do
    if memrecitems[i]=memrec then
    begin
      treeview.Items.SelectOnlyThis(memrecitems[i].treenode);
      memrecitems[i].isSelected:=true;
    end
    else
      memrecitems[i].isSelected:=false;
end;

function TAddresslist.getSelectedRecord: TMemoryRecord;
var i: integer;
begin
  result:=nil;
  if treeview.selected<>nil then
    result:=TMemoryRecord(treeview.selected.data)
  else
  begin
    for i:=0 to count-1 do
      if MemRecItems[i].isSelected then
        result:=MemRecItems[i];
  end;
end;

function TAddresslist.GetSelcount: integer;
var i: integer;
begin
  result:=0;
  for i:=0 to count-1 do
    if MemRecItems[i].isSelected then
      inc(result);
end;

function TAddresslist.GetCount: integer;
begin
  if treeview<>nil then
    result:=treeview.items.count
  else
    result:=0;
end;

function TAddresslist.GetMemRecItemByIndex(i: integer): TMemoryRecord;
begin
  if i<treeview.Items.Count then
    result:=TMemoryRecord(treeview.items[i].data)
  else
    result:=nil;
end;

procedure TAddresslist.ActivateSelected(FreezeType: TFreezeType=ftFrozen);
var
  i: integer;
  allowinc: boolean;
  allowdec: boolean;
begin
  //note, I should upgrade the memoryrecord class with this type instead of two booleans
  for i:=0 to count-1 do
    if memrecitems[i].isSelected then
    begin
      memrecitems[i].allowIncrease:=FreezeType=ftAllowIncrease;
      memrecitems[i].allowDecrease:=FreezeType=ftAllowDecrease;
      memrecitems[i].active:=true;
    end;
end;

procedure TAddresslist.DeactivateSelected;
var i: integer;
begin
  i:=0;
  while i<count do
  begin
    if memrecitems[i].isSelected then
      memrecitems[i].active:=false;    //this will also reset the allow* booleans
    i:=i+1
  end;
end;





procedure TAddresslist.SelectAll;
var i: integer;
begin
  for i:=0 to count-1 do
    MemRecItems[i].isSelected:=true;

  refresh;
end;

procedure TAddresslist.DeleteSelected(ask: boolean=true);
var i: integer;
question: string;
oldindex: integer;
begin

  if count=0 then exit;

  if selcount=0 then exit;
  if selcount=1 then question:=rsDoYouWantToDeleteTheSelectedAddress else question:=rsDoYouWantToDeleteTheSelectedAddresses;

  oldindex:=selectedRecord.treenode.AbsoluteIndex;


  if (not ask) or (messagedlg(question, mtConfirmation, [mbyes, mbno], 0) = mryes) then
  begin
    i:=0;
    while i<count do
    begin
      if MemRecItems[i].isSelected and (MemRecItems[i].isBeingEdited=false) and (MemRecItems[i].AsyncProcessing=false) then
        MemRecItems[i].Free //Free also cleans up it's associated treenode, and all it's children
      else
        inc(i);
    end;
  end;

  if oldindex>=treeview.items.count then
    oldindex:=treeview.items.count-1;

  if oldindex>-1 then
    treeview.items[oldindex].Selected:=true

end;

procedure TAddresslist.ApplyFreeze;
{Freeze all the records that are active}
var
  i: integer;
  oldlogWrites: boolean;
begin
  if GetCurrentThreadId=MainThreadID then
  begin
    oldlogWrites:=logwrites;
    logwrites:=false;
    //oldlogWrites:=false;
    blockfilehandlerpopup:=true;
  end;

  try
    for i:=0 to count-1 do
      memrecitems[i].ApplyFreeze;
  finally
    if GetCurrentThreadId=MainThreadID then
    begin
      logWrites:=oldlogWrites;
      blockfilehandlerpopup:=false;
    end;
  end;
end;

procedure TAddresslist.saveTableXMLToNode(CheatEntries: TDOMNode; selectedOnly: boolean=false);
var tn: TTreenode;
p: TTreenode;
m: TMemoryRecord;
begin
  tn:=treeview.Items.GetFirstNode;
  while tn<>nil do
  begin
    TMemoryRecord(tn.data).getXMLNode(CheatEntries,selectedonly);

    if selectedonly then //go through all entries, not just the main
      tn:=tn.GetNext
    else
      tn:=tn.GetNextSibling;
  end;
end;

procedure TAddresslist.loadTableXMLFromNode(CheatEntries: TDOMNode);
var currentEntry: TDOMNode;
memrec: TMemoryRecord;
i: integer;
begin

  currentEntry:=CheatEntries.FirstChild;
  while currententry<>nil do
  begin
    if tdomelement(currententry).TagName='CheatEntry' then
    begin
      //create a blank entry
      memrec:=TMemoryRecord.create(self);
      memrec.treenode:=Treeview.Items.AddObject(nil,'',memrec);

      //fill the entry with the node info
      memrec.setXMLnode(currentEntry);
    end;
    currentEntry:=currentEntry.NextSibling;
  end;

  for i:=0 to count-1 do
    if MemRecItems[i].ID=-1 then
      MemRecItems[i].ID:=GetUniqueMemrecId;
end;

function TAddresslist.GetTableXMLAsText(selectedonly: boolean): string;
var
  doc: TXMLDocument;
  cheattable,CheatEntries: TDOMNode;
  i: integer;
  ms: TMemoryStream;
begin
  result:='';
  doc:=TXMLDocument.Create;

  ms:=TMemorystream.Create;

  cheattable:=doc.CreateElement('CheatTable');
  doc.AppendChild(cheattable);

  CheatEntries:=doc.CreateElement('CheatEntries');
  cheattable.AppendChild(CheatEntries);

  try
    saveTableXMLToNode(CheatEntries, selectedOnly);
    WriteXMLFile(doc,ms);
    ms.WriteByte(0);

    ms.Position:=0;

    result:=pchar(ms.Memory); //s.UnicodeDataString;
  finally
    doc.free;
    ms.free;
  end;
end;

function TAddresslist.CheatTableNodeHasOnlyAutoAssemblerScripts(CheatTable: TDOMNode): boolean;
{
private
checks if the given xml document contains cheatentries that aren't aa scripts
}
var CheatEntries, currentEntry: TDOMNode;
  vtnode: TDOMNode;
begin
  result:=true;
  //go through the list untill one is found that has the custom type
  CheatEntries:=CheatTable.FindNode('CheatEntries');
  if cheatentries<>nil then
  begin
    currentEntry:=CheatEntries.FirstChild;
    while currententry<>nil do
    begin
      vtnode:=currententry.findnode('VariableType');
      if (vtnode=nil) or (StringToVariableType(vtnode.TextContent)<>vtAutoAssembler) then
      begin
        result:=false;
        exit;
      end;
      currentEntry:=currentEntry.NextSibling;
    end;
  end;
end;

procedure __CheatTableNodeCheckForRelativeAddress(CheatTable: TDOMNode; var hasRelative, allRelative: boolean);
var CheatEntries, currentEntry: TDOMNode;
  addrnode: TDOMNode;
  s: string;
begin
  
  CheatEntries:=CheatTable.FindNode('CheatEntries');
  if cheatentries<>nil then
  begin
    currentEntry:=CheatEntries.FirstChild;
    while currententry<>nil do
    begin
      addrnode:=currententry.findnode('Address');
      if (addrnode<>nil) and (addrnode.TextContent<>'') then
      begin
        s:=trim(addrnode.TextContent);
        if (s<>'') and (s[1] in ['-', '+']) then
          hasRelative:=true
        else
          allRelative:=false;
      end;

      if hasRelative and (not allRelative) then exit;

      if currententry.findnode('CheatEntries')<>nil then
        __CheatTableNodeCheckForRelativeAddress(currentEntry, hasRelative, allRelative);

      currentEntry:=currentEntry.NextSibling;
    end;
  end;
end;

procedure TAddresslist.CheatTableNodeCheckForRelativeAddress(CheatTable: TDOMNode; var hasRelative, allRelative: boolean);
{
private
checks if the given xml document contains cheatentries without relative Address
}
begin
  hasRelative:=false;
  allRelative:=true;
  __CheatTableNodeCheckForRelativeAddress(CheatTable, hasRelative, allRelative);
end;

procedure TAddresslist.AddTableXMLAsText(xml: string; simpleCopyPaste: boolean=true);
var doc: TXMLDocument;
    insertafter: TTreenode;
    memrec: TMemoryRecord;

    CheatTable: TDOMNode;
    CheatEntries: TDOMNode;

    currentEntry: TDOMNode;

    s: TMemoryStream;

    replace_find: string;
    replace_with: string;
    changeoffsetstring: string;
    changepointerlastoffsetstring: string;
    changeoffset: int64;
    changepointerlastoffset: int64;
    i: integer;
    childrenaswell: boolean;
    relativeaswell: boolean;
    hasRelative, allRelative: boolean;


begin
  doc:=nil;
  s:=nil;
  relativeaswell:=false;

  s:=TMemoryStream.Create;
  s.WriteBuffer(xml[1],length(xml));
  s.position:=0;


  try
    try
      ReadXMLFile(doc, s);

      insertafter:=treeview.Selected;

      CheatTable:=doc.FindNode('CheatTable');
      if cheattable<>nil then
      begin
        CheatEntries:=CheatTable.FindNode('CheatEntries');
        if CheatEntries<>nil then
        begin
          currentEntry:=CheatEntries.FirstChild;
          if currententry<>nil then //valid
          begin
            frmPasteTableentry:=TfrmPasteTableentry.create(self);
            try
              if not simplecopypaste then
              begin
                //check if it's needed (is at least one address not an auto assembler script ?
                if not CheatTableNodeHasOnlyAutoAssemblerScripts(CheatTable) then
                  if frmpastetableentry.showmodal=mrcancel then exit;
              end;

              replace_find:=frmpastetableentry.edtFind.text;
              replace_with:=frmpastetableentry.edtReplace.text;
              changeoffsetstring:='$'+stringreplace(frmpastetableentry.edtOffset.Text,'-','-$',[rfReplaceAll]);
              changeoffsetstring:=stringreplace(changeoffsetstring,'$-','-',[rfReplaceAll]);
              changepointerlastoffsetstring:='$'+stringreplace(frmpastetableentry.edtPointerLastOffset.Text,'-','-$',[rfReplaceAll]);
              changepointerlastoffsetstring:=stringreplace(changepointerlastoffsetstring,'$-','-',[rfReplaceAll]);

              if not TryStrToInt64(changeoffsetstring,changeoffset) then changeoffset:=0;
              if not TryStrToInt64(changepointerlastoffsetstring,changepointerlastoffset) then changepointerlastoffset:=0;

              childrenaswell:=frmPasteTableentry.cbChildrenAsWell.Checked;
            finally
              freeandnil(frmPasteTableentry);
            end;

            CheatTableNodeCheckForRelativeAddress(CheatTable, hasRelative, allRelative);

            if (changeoffset<>0) and hasRelative then
              if allRelative then
                relativeaswell:=true
              else
                relativeaswell:=messagedlg(rsAdjustMRwithRelativeAddress, mtConfirmation, [mbyes, mbno], 0) = mryes;
          end;

          while currententry<>nil do
          begin
            if tdomelement(currententry).TagName='CheatEntry' then
            begin

              //create a blank entry
              memrec:=TMemoryRecord.create(self);
              memrec.treenode:=Treeview.Items.AddObject(nil,'',memrec);
              if insertAfter<>nil then
                memrec.treenode.MoveTo(insertafter, naInsertBehind);

              insertAfter:=memrec.treenode;

              //fill the entry with the node info
              memrec.setXMLnode(currentEntry);


              memrec.adjustAddressBy(changeoffset, changepointerlastoffset, childrenaswell, relativeaswell);
              memrec.replaceDescription(replace_find, replace_with, childrenaswell);
            end;
            currentEntry:=currentEntry.NextSibling;
          end;

          rebuildDescriptionCache;
        end;
      end;
    finally
      if doc<>nil then
        doc.free;

      if s<>nil then
        s.free;
    end;
  except
    //don't complain
  end;

  //update id's if necessary
  for i:=0 to count-1 do
    if MemRecItems[i].ID=-1 then
      MemRecItems[i].ID:=GetUniqueMemrecId;

end;

procedure TAddresslist.CreateGroup(groupname: string; withAddress: boolean=false);
var
  memrec: TMemoryRecord;
  n: TTreenode;
begin

  memrec:=TMemoryrecord.Create(self);
  memrec.id:=GetUniqueMemrecId;
  memrec.isGroupHeader:=true;
  memrec.isAddressGroupHeader:=withAddress;
  memrec.Description:=groupname;

  if SelectedRecord<>nil then
    memrec.treenode:=Treeview.Items.InsertObjectBehind(SelectedRecord.treenode,'', memrec)
  else
    memrec.treenode:=Treeview.Items.AddObject(nil,'',memrec);


  memrec.treenode.DropTarget:=true;
  MainForm.editedsincelastsave:=true;
end;

procedure TAddresslist.addAutoAssembleScript(script: string);
var
  memrec: TMemoryRecord;
begin
  memrec:=TMemoryrecord.Create(self);
  memrec.id:=GetUniqueMemrecId;
  memrec.isGroupHeader:=false;
  memrec.Description:=rsALAutoAssembleScritp;
  memrec.AutoAssemblerData.script:=tstringlist.create;
  memrec.AutoAssemblerData.script.text:=script;

  memrec.VarType:=vtAutoAssembler;

  memrec.treenode:=Treeview.Items.AddObject(nil,'',memrec);
  memrec.treenode.DropTarget:=true;
  MainForm.editedsincelastsave:=true;
end;

function TAddresslist.GetUniqueMemrecId: integer;
var i: integer;
begin
  result:=-1;
  for i:=0 to count-1 do
    result:=max(result, memrecitems[i].id);

  inc(result);
end;

function TAddresslist.getRecordWithID(id: integer): TMemoryRecord;
var i: integer;
begin
  result:=nil;
  for i:=0 to count-1 do
    if MemRecItems[i].id=id then
    begin
      result:=MemRecItems[i];
      exit;
    end;

end;

procedure TAddresslist.rebuildDescriptionCache;
var i: integer;
begin
  descriptionhashlist.Clear;

  for i:=0 to count-1 do
    if ForbiddenSearchDescriptions.Data[MemRecItems[i].description]=nil then
      descriptionhashlist[MemRecItems[i].description]:=MemRecItems[i];
end;

procedure TAddresslist.MemrecDescriptionChange(memrec: TMemoryRecord; olddescription, newdescription: string);
begin
  if olddescription<>'' then
    descriptionhashlist.Remove(olddescription);

  if newdescription<>'' then
  begin
    if ForbiddenSearchDescriptions.Data[newdescription]=nil then
      descriptionhashlist[newdescription]:=memrec;
  end;
end;

function TAddresslist.getRecordWithDescription(description: string): TMemoryRecord;
begin
  result:=descriptionhashlist.Data[description]
end;

function TAddresslist.addAddressManually(initialaddress: string=''; vartype: TVariableType=vtDword; CustomTypeName: string=''; focusOnDescription: boolean=false): TMemoryRecord;
var mr: TMemoryRecord;
    edited: boolean;
begin
  result:=nil;
  edited:=mainform.editedsincelastsave;


  Treeview.BeginUpdate;
  mr:=addaddress(rsALNoDescription,initialaddress,[],0, vartype, CustomTypeName);
  mr.visible:=false;
  Treeview.EndUpdate;


  //changevalue, if cancel, delete
  with TFormaddresschange.Create(self) do
  begin
    caption:=rsALAddAddress;
    memoryrecord:=mr;

    focusDescription:=focusOnDescription;

    if showmodal<>mrok then
    begin
      mr.free; //not ok, delete
      mr:=nil;
      mainform.editedsincelastsave:=edited;
    end
    else
    begin
      mr.ReinterpretAddress(true);
      mr.visible:=true;
      mainform.editedsincelastsave:=true;
    end;

    free;
  end;

  //treeview.EndUpdate;


  result:=mr;
end;

function TAddresslist.addaddress(description: string; address: string; const offsets: array of integer; offsetcount: integer; vartype: TVariableType; customtypename: string=''; length: integer=0; startbit: integer=0; unicode: boolean=false; node: TTreenode=nil; attachmode: TNodeAttachMode=naAdd): TMemoryRecord;
var
  memrec: TMemoryRecord;
  i: integer;
  t: TTreenode;
begin
  memrec:=TMemoryRecord.create(self);

  memrec.id:=GetUniqueMemrecId;

  memrec.Description:=description;
  memrec.interpretableaddress:=address;


  memrec.VarType:=vartype;
  memrec.CustomTypeName:=customtypename;

  memrec.offsetCount:=offsetcount;
  for i:=0 to offsetcount-1 do
    memrec.offsets[i].offset:=offsets[i];

  case vartype of
    vtString:
    begin
      memrec.extra.stringData.unicode:=unicode;
      memrec.Extra.stringData.length:=length;
    end;

    vtUnicodeString:
    begin
      memrec.vartype:=vtString;
      memrec.extra.stringData.unicode:=true;
      memrec.Extra.stringData.length:=length;
    end;

    vtCodePageString:
    begin
      memrec.vartype:=vtString;
      memrec.extra.stringData.codepage:=true;
      memrec.Extra.stringData.length:=length;
    end;

    vtBinary:
    begin
      memrec.Extra.bitData.Bit:=startbit;
      memrec.Extra.bitData.bitlength:=length;
    end;

    vtByteArray:
    begin
      memrec.showAsHex:=true; //aob's are hex by default
      memrec.Extra.byteData.bytelength:=length;
    end;

    vtPointer:
    begin
      if processhandler.is64Bit then
        memrec.vartype:=vtQword
      else
        memrec.vartype:=vtDword;

      memrec.showAsHex:=true;
    end;
  end;

  memrec.ReinterpretAddress;

  memrec.treenode:=Treeview.Items.AddObject(nil,'',memrec);
  if node<>nil then
    memrec.treenode.MoveTo(node, attachmode);

  result:=memrec;

  MainForm.editedsincelastsave:=true;

end;

procedure TAddresslist.setTreeNodes(t: TTreenodes);
begin
  TreeView.Items:=t;
end;

function TAddresslist.getTreeNodes: TTreenodes;
begin
  result:=TreeView.Items;
end;

procedure TAddresslist.doDescriptionChange;
begin
  if treeview.selected<>nil then
    descriptiondblclick(treeview.selected);
end;

procedure TAddresslist.doAddressChange;
begin
  if treeview.selected<>nil then
    addressdblclick(treeview.selected);
end;

procedure TAddresslist.doTypeChange;
begin
  if treeview.selected<>nil then
    typedblclick(treeview.selected);
end;

procedure TAddresslist.doValueChange;
begin
  if treeview.selected<>nil then
  begin
    if SelCount=1 then
      valueclick(treeview.selected)
    else
      valuedblclick(treeview.selected);
  end;
end;

function TAddresslist.getMouseHighlightedRecord: TMemoryRecord;
var
  p: tpoint;
  node: TTreenode;
begin
  p:=treeview.ScreenToClient(mouse.CursorPos);
  node:=treeview.GetNodeAt(p.x,p.y);
  if node<>nil then
    result:=tmemoryrecord(node.Data)
  else
    result:=nil;
end;

procedure TAddresslist.disableAllWithoutExecute;
var i: integer;
begin
  for i := 0 to Count - 1 do
    if (MemRecItems[i].VarType = vtAutoAssembler) and (MemRecItems[i].active) then
      MemRecItems[i].disablewithoutexecute;
end;

procedure TAddresslist.descriptiondblclick(node: TTreenode);
var i: integer;
    description: string;
begin
  if assigned(fOnDescriptionChange) and fOnDescriptionChange(self,tmemoryrecord(node.data)) then exit;


  description:=tmemoryrecord(node.data).description;

  if InputQuery(rsChangeDescription, rsWhatWillBeTheNewDescription, description) then
  begin
    if tmemoryrecord(node.data).description<>description then
      MainForm.editedsincelastsave:=true;

    for i:=0 to items.count-1 do
      if (MemRecItems[i].isSelected) then
        MemRecItems[i].description:=description;



//    tmemoryrecord(node.data).description:=description;
  end;


  treeview.Update;
//  node.update;
end;

procedure TAddresslist.addressdblclick(node: TTreenode);
begin
  if assigned(fOnAddressChange) and fOnAddressChange(self,tmemoryrecord(treeview.selected.Data)) then exit;

  if TMemoryRecord(node.data).isGroupHeader and not TMemoryRecord(node.data).isAddressGroupHeader then exit;

  with TFormaddresschange.Create(self) do
  begin
    memoryrecord:=TMemoryRecord(node.data);
    if showmodal=mrok then
      MainForm.editedsincelastsave:=true;

    free;

    memoryrecord.ReinterpretAddress(true);
    node.update;
  end;
end;

procedure TAddresslist.typedblclick(node: TTreenode);
var
  i, j: integer;
  newtype,oldType: TVariableType;
  memrec: TMemoryRecord;
  extra:  TMemRecExtraData;
  CustomTypeName: string;
begin
  TypeForm.RefreshCustomTypes;
  memrec:=TMemoryRecord(node.data);

  if assigned(fOnTypeChange) and fOnTypeChange(self,memrec) then exit;



  if memrec.isGroupHeader then exit;

  OldType:=memrec.Vartype;

  TypeForm.RefreshFieldsByMemoryRecord(memrec);

  typeform.MemoryRecord:=memrec;
  if TypeForm.Showmodal=mrNo then exit;

  newtype:=memrec.VarType;
  extra:=memrec.Extra;
  CustomTypeName:=memrec.customtypename;

  for i:=0 to count-1 do
  begin
    if (MemRecItems[i].isSelected) then
    begin
      MemRecItems[i].active:=false;

      if memrecitems[i].vartype<>newtype then
        MainForm.editedsincelastsave:=true;

      MemRecItems[i].VarType:=newtype;
      MemRecItems[i].Extra:=extra;
      MemRecItems[i].CustomTypeName:=customtypename;

      MemRecItems[i].treenode.update;
    end;
  end;

end;

procedure Taddresslist.MultiEdit(memrec: TMemoryrecord);
var
  someerror: boolean;
  allError: boolean;
  i: integer;
  oldvalue, value: string;

  canceled: boolean;

  list: TStringList;

  frmMemrecCombobox: TfrmMemrecCombobox;
begin
  try
    if memrec.DropDownCount=0 then
    begin
      value:=AnsiToUtf8(memrec.value);


      if memrec.VarType=vtString then
        canceled:=not MultilineInputQuery(rsChangeValue, rsWhatValueToChangeThisTo, value)
      else
        canceled:=not InputQuery(rsChangeValue, rsWhatValueToChangeThisTo, value);


      value:=TrimRight(Utf8ToAnsi(value));
    end
    else
    begin
      frmMemrecCombobox:=TfrmMemrecCombobox.Create(memrec);
      canceled:=frmMemrecCombobox.showmodal<>mrok;

      if memrec.DropDownReadOnly and memrec.DropDownDescriptionOnly and memrec.DisplayAsDropDownListItem and (frmMemrecCombobox.value='*') then
        canceled:=true;

      if not canceled then
        value:=utf8toansi(frmMemrecCombobox.value);

      frmMemrecCombobox.free;
    end;

    if not canceled  then
    begin


      allError:=true;
      someError:=false;
      for i:=0 to count-1 do
        if memrecitems[i].isSelected then
        begin
          try
            memrecitems[i].SetValue(value);
            memrecitems[i].treenode.update;
            allError:=false;
          except
            someError:=true;
          end;
        end;

      if AllError then raise exception.create(Format(rsTheValueCouldNotBeParsed, [value]));
      if SomeError then raise exception.create(Format(rsNotAllValueTypesCouldHandleTheValue, [value]));
    end;

  except
    on e:Exception do
      MessageDlg(e.message,mtError,[mbok],0);
  end;
end;

procedure TAddresslist.EditorDoubleclick(sender: tobject);
begin
  multiedit(TAddressListEditor(sender).memrec);
end;

procedure TAddresslist.valuedblclick(node: TTreenode);
{
Doubeclcik on the value
This results in showing the value editor mode
}
var
  value: string;
  memrec: TMemoryRecord;
  i: integer;

begin
  memrec:=TMemoryRecord(node.data);

  if assigned(fOnValueChange) and fOnValueChange(self,memrec) then exit;


  value:=memrec.GetValue;

  if (selcount=1) and (selectedRecord.VarType=vtAutoAssembler) then
  begin
    //if it's an autoassemblerscript then spawn the autoassembler script editor that the owner might want to use
    if assigned(fOnAutoAssemblerEdit) then
      fOnAutoAssemblerEdit(self, self.selectedRecord);

    exit;
  end;


  if (not memrec.isGroupHeader) and (not memrec.IsReadableAddress) then
  begin
    beep; //my favourite sound
    exit;
  end;


  //multiple selections, use an input box for this


  multiedit(memrec);
 // end;
end;

procedure TAddresslist.ValueClick(node: TTreenode);
var memrec: TMemoryrecord;
begin
  memrec:=TMemoryRecord(node.data);
  if assigned(fOnValueChange) and fOnValueChange(self,memrec) then exit;



  if (memrec.VarType<>vtAutoAssembler) and (selcount<=1) and (memrec.DropDownCount=0) then
  begin


    if AddressListEditor<>nil then
      freeandnil(AddressListEditor);

    AddressListEditor:=TAddresslisteditor.create(treeview, memrec, header.Sections[4].Left);
    AddressListEditor.OnDblClick:=EditorDoubleclick;
  end
  else
    valuedblclick(node);
end;

procedure TAddresslist.TreeviewOnExpand(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
var r: TMemoryRecord;
begin
  AllowExpansion:=true;

  r:=TMemoryRecord(node.data);
  if ((moHideChildren in r.options) and (not r.active)) and (not (moAllowManualCollapseAndExpand in r.options)) then //if not active then don't allow expanding
    AllowExpansion:=false;
end;

procedure TAddresslist.TreeviewOnCollapse(Sender: TObject; Node: TTreeNode; var AllowCollapse: Boolean);
var r: TMemoryRecord;
begin
  AllowCollapse:=false;
  r:=TMemoryRecord(node.data);
  if ((moHideChildren in r.options) and (not r.active)) or  (moManualExpandCollapse in r.options) or (moAllowManualCollapseAndExpand in r.options) or (moAlwaysHideChildren in r.options)  then //if not active then allow collapse, or if it's allowed to collapse
    AllowCollapse:=true;
end;

procedure TAddresslist.TreeviewDblClick(Sender: TObject);
var
  textrect, linerect: TRect;
  node, n: TTreenode;
  i: integer;
  p: tpoint;
begin
  p:=treeview.ScreenToClient(mouse.cursorpos);

  node:=treeview.GetNodeAt(p.x,p.y);
  if node<>nil then
  begin
    //at least something was clicked

    textrect:=node.DisplayRect(true);
    linerect:=node.DisplayRect(false);

    n:=node;
    while n<>nil do
    begin
      if moManualExpandCollapse in  TMemoryRecord(n.data).Options then
        inc(textrect.left,expandsignsize+1);
      n:=n.parent;
    end;

    // compare x with arrowEnd (arrowEnd = checkboxEnd+9 = ...; see TreeviewMouseDown)
    // prevents double click
    if p.x<=textrect.left+(linerect.bottom-linerect.top)+8 then exit;

    for i:=0 to header.Sections.count-1 do
      if inrange(p.x,header.Sections[i].Left,header.Sections[i].right) then
      begin
        //if GroupHeaderWithAddress do the description, address, value dblclick
        if TMemoryRecord(node.data).isAddressGroupHeader then
        begin
          case i of
            0: ; //frozen doubleclick
            1: descriptiondblclick(node);
            2: addressdblclick(node);
            3: ; //typedblclick(node);
            4: valuedblclick(node);
          end;
        end
        else
        //if it's a auto assemble script only do the description and value
        if (TMemoryRecord(node.data).VarType=vtAutoAssembler) or (TMemoryRecord(node.data).isGroupHeader) then
        begin
          case i of
            0: ; //frozen doubleclick
            1: descriptiondblclick(node);
            2: ; //addressdblclick(node);
            3: ; //typedblclick(node);
            4: valuedblclick(node);
          end;
        end
        else
        begin
          case i of
            0: ; //frozen doubleclick
            1: descriptiondblclick(node);
            2: addressdblclick(node);
            3: typedblclick(node);
            4: valuedblclick(node);
          end;
        end;

        break;
      end;
  end;
end;

procedure TAddresslist.TreeviewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  linerect,textrect: TRect;
  node: TTreenode;

  checkboxstart, checkboxend: integer;

  oldstate: boolean;

  mr: TMemoryRecord;

  n: ttreenode;

  i: integer;
  p: tpoint;
begin
//  self.Parent;



  p:=treeview.ScreenToClient(mouse.cursorpos);
  x:=p.x;
  y:=p.y;

  node:=treeview.GetNodeAt(x,y);
  if node<>nil then
  begin
    if button<>mbleft then exit;

    mr:=TMemoryRecord(node.data);

    textrect:=node.DisplayRect(true);
    linerect:=node.DisplayRect(false);
    //check if the checkbox is clicked

    n:=node.parent;
    while n<>nil do
    begin
      if moManualExpandCollapse in  TMemoryRecord(n.data).Options then
      begin
        inc(textrect.left,expandsignsize+1);
      end;

      n:=n.parent;
    end;

    if moManualExpandCollapse in mr.options then
    begin
      //check for expand/collapse sign click
      if inrange(x, textrect.left, textrect.left+expandsignsize) then
      begin
        treeview.OnCollapsing:=nil;
        if node.Expanded then
          node.Collapse(false)
        else
          node.Expand(false);

        treeview.OnCollapsing:=TreeviewOnCollapse;
      end;
      inc(textrect.left,expandsignsize+1);
    end;

    checkboxstart:=textrect.left+1;

    checkboxend:=checkboxstart+(linerect.bottom-linerect.top)-2;
    if inrange(x, checkboxstart, checkboxend ) then
    begin
      //checkbox click
      //oldstate:=TMemoryRecord(node.data).Active;

     // SelectionUpdate(nil);

      TMemoryRecord(node.data).Active:=not TMemoryRecord(node.data).Active;
     {
      if oldstate then
        DeActivateSelected
      else
        ActivateSelected;}

    end;

    if TMemoryRecord(node.data).Active then
    begin
      //arrow spot is clicked
      //nothing->increased->decreased->nothing->...
      if inrange(x, checkboxend+1, checkboxend+9) then
      begin
        if TMemoryRecord(node.data).allowIncrease then TMemoryRecord(node.data).allowDecrease:=true
        else
        if TMemoryRecord(node.data).allowDecrease then TMemoryRecord(node.data).allowDecrease:=false
        else
          TMemoryRecord(node.data).allowIncrease:=true

      end;
    end;



    //todo: Add setting to enable/disable this
    {
    if (button=mbLeft) and (inrange(x,header.Sections[4].Left,header.Sections[4].right)) then
    begin
      //check if text of the value is clicked

      if mr.IsReadableAddress then
      begin
        SelectionUpdate(Treeview);
        if (x<header.Sections[4].Left+treeview.canvas.TextWidth(mr.DisplayValue)) and (SelCount<=1) then
          valueclick(node); //initiate the value change routine

      end;
    end;
    }
  end
  else
  begin

    if not ((ssShift in shift) or (ssctrl in shift)) then
    begin
      treeview.Selected:=nil;
      for i:=0 to Count-1 do
        MemRecItems[i].isSelected:=false;
    end;

  end;
end;

{
procedure TAddresslist.TreeviewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if key=VK_DELETE then
    deleteSelected;
end;   }



procedure TAddresslist.sort(firstnode: ttreenode; compareRoutine: TTreeNodeCompare; direction: boolean );
{
  sort from the first node till there is no more sibling
}
var
  currentnode: ttreenode;
  i: integer;
  list: TList;

  basenode: TMemoryrecord;
begin

  treeview.BeginUpdate;
  try
    if firstnode.level>0 then
    begin
      sortlevel0only:=false;
      firstnode.Parent.CustomSort(compareroutine)
    end
    else
    begin
      sortlevel0only:=true;
      treeview.CustomSort(compareroutine);
      //treeview.items.SortTopLevelNodes(compareroutine); //broken right now
    end;



  finally
    treeview.EndUpdate;
  end;
end;

function TAddresslist.activecompare(_a: TTreenode; _b: TTreenode): integer;
var
  ra, rb: integer;
  a,b: TMemoryRecord;
begin
  if sortlevel0only and (_a.level<>0) and (_b.level<>0) then exit(0);

  a:=TMemoryRecord(_a.data);
  b:=TMemoryRecord(_b.data);
  if not a.active then ra:=0 else
    if a.allowdecrease then ra:=1 else
      if a.allowincrease then ra:=2 else
        ra:=3;

  if not b.active then rb:=0 else
    if b.allowdecrease then rb:=1 else
      if b.allowincrease then rb:=2 else
        rb:=3;

  result:=rb-ra;

  if not activesortdirection then
    result:=-result;
end;

procedure TAddresslist.sortByActive;
type TCompareState=(inactive, allowincrease, allowdecrease, active);
var n: TTreenode;
begin

  if count=0 then exit;

  if treeview.Selected<>nil then n:=treeview.Selected else n:=treeview.Items[0];
  sort(n, activecompare, activesortdirection);
  activesortdirection:=not activesortdirection;
end;

function TAddresslist.descriptioncomparecasesensitive(_a: TTreenode; _b: TTreenode): integer;
var
  a,b: TMemoryRecord;
begin
  if sortlevel0only and (_a.level<>0) and (_b.level<>0) then exit(0);

  a:=TMemoryRecord(_a.data);
  b:=TMemoryRecord(_b.data);
  result:=0; //equal
  if b.description>a.description then
    result:=1;
  if b.description<a.description then
    result:=-1;

  if not descriptionsortdirection then
    result:=-result;
end;

function TAddresslist.descriptioncompare(_a: TTreenode; _b: TTreenode): integer;
var
  a,b: TMemoryRecord;
begin
  if sortlevel0only and (_a.level<>0) and (_b.level<>0) then exit(0);

  a:=TMemoryRecord(_a.data);
  b:=TMemoryRecord(_b.data);
  result:=0; //equal
  if uppercase(b.description)>uppercase(a.description) then
    result:=1;
  if uppercase(b.description)<uppercase(a.description) then
    result:=-1;

  if not descriptionsortdirection then
    result:=-result;
end;

procedure TAddresslist.sortByDescription;
var n: TTreenode;
begin
  if count=0 then exit;

  if treeview.Selected<>nil then n:=treeview.Selected else n:=treeview.Items[0];

  if ssCtrl in GetKeyShiftState then
    sort(n, descriptioncomparecasesensitive, descriptionsortdirection)
  else
    sort(n, descriptioncompare, descriptionsortdirection);

  descriptionsortdirection:=not descriptionsortdirection;
end;

function TAddresslist.addresscompare(_a: TTreenode; _b: TTreenode): integer;
var
  a,b: TMemoryRecord;
begin
  if sortlevel0only and (_a.level<>0) and (_b.level<>0) then exit(0);

  a:=TMemoryRecord(_a.data);
  b:=TMemoryRecord(_b.data);
  result:=b.getRealAddress-a.GetRealAddress;

  if not addresssortdirection then
    result:=-result;
end;

procedure TAddresslist.sortByAddress;
var n: TTreenode;
begin
  if count=0 then exit;

  if treeview.Selected<>nil then n:=treeview.Selected else n:=treeview.Items[0];
  sort(n, addresscompare, addresssortdirection);
  addresssortdirection:=not addresssortdirection;
end;

function TAddresslist.valuetypecompare(_a: TTreenode; _b: TTreenode): integer;
var
  a,b: TMemoryRecord;
begin
  if sortlevel0only and (_a.level<>0) and (_b.level<>0) then exit(0);

  a:=TMemoryRecord(_a.data);
  b:=TMemoryRecord(_b.data);
  result:=integer(b.VarType)-integer(a.VarType);

  if not valuetypesortdirection then
    result:=-result;
end;

procedure TAddresslist.sortByValueType;
var n: TTreenode;
begin
  if count=0 then exit;

  if treeview.Selected<>nil then n:=treeview.Selected else n:=treeview.Items[0];
  sort(n, valuetypecompare, valuetypesortdirection );
  valuetypesortdirection:=not valuetypesortdirection;
end;

function TAddresslist.valuecompare(_a: TTreenode; _b: TTreenode): integer;
var
  va, vb: double;
  a,b: TMemoryRecord;

  s1,s2: widestring;
begin
  if sortlevel0only and (_a.level<>0) and (_b.level<>0) then exit(0);

  a:=TMemoryRecord(_a.data);
  b:=TMemoryRecord(_b.data);
  if not TryStrToFloat(a.value, va) then va:=0;
  if not TryStrToFloat(b.value, vb) then vb:=0;

  if (a.VarType in [vtString, vtUnicodeString]) and
     (b.VarType in [vtString, vtUnicodeString]) then
  begin
    s1:=a.value;
    s2:=b.value;
    result:=strcomp(pwidechar(s1),pwidechar(s2));
  end
  else
  begin
    result:=0;
    if vb>va then
      result:=1;

    if vb<va then
      result:=-1;
  end;

  if not valuesortdirection then
    result:=-result;

end;


procedure TAddresslist.sortByValue;
var n: TTreenode;
begin
  if count=0 then exit;

  if treeview.Selected<>nil then n:=treeview.Selected else n:=treeview.Items[0];
  sort(n, valuecompare, valuesortdirection);
  valuesortdirection:=not valuesortdirection;
end;

procedure TAddresslist.sectionClick(HeaderControl: TCustomHeaderControl; Section: THeaderSection);
begin
  if miSortOnClick.checked then
  begin
    //sort the addresslist based on the clicked section
    case section.Index of
      0: sortByActive;
      1: sortByDescription;
      2: sortByAddress;
      3: sortByValueType;
      4: sortByValue;
    end;
  end;
end;

procedure TAddresslist.sectiontrack(HeaderControl: TCustomHeaderControl; Section: THeaderSection; Width: Integer; State: TSectionTrackState);
begin
  treeview.Refresh;
end;

procedure TAddresslist.FocusChange(sender: TObject);
begin
  treeview.refresh;
end;

procedure TAddresslist.TVDragEnd(Sender, Target: TObject; X,Y: Integer);
begin
  CurrentlyDraggedOverNode:=nil;
end;

procedure TAddresslist.TVDragOver(Sender, Source: TObject; X,Y: Integer; State: TDragState; var Accept: Boolean);
var t: integer;
begin
  CurrentlyDraggedOverNode:=TreeView.GetNodeAt(x,y);
  CurrentlyDraggedOverBefore:=false;
  CurrentlyDraggedOverAfter:=false;


  if (CurrentlyDraggedOverNode<>nil) then //if something focused AND not a groupheader
  begin

    t:=treeview.ScrolledTop+y;

   // outputdebugstring(inttostr(t-(CurrentlyDraggedOverNode.top)));
    CurrentlyDraggedOverBefore:=(t-CurrentlyDraggedOverNode.top)<(CurrentlyDraggedOverNode.height div 3); //it's before if the offset into the node is smaller than half the height - 2
    CurrentlyDraggedOverAfter:=(t-CurrentlyDraggedOverNode.top)>(CurrentlyDraggedOverNode.height div 3)*2;
  end; //groupheaders are always perfect targets


  accept:=true;
  treeview.refresh;
end;

procedure TAddresslist.TVDragDrop(Sender, Source: TObject; X,Y: Integer);
var
  node: TTreenode;
  i: integer;

  selectednodelist: array of TTreenode;
begin
  setlength(selectednodelist,0);
  for i:=0 to treeview.items.count-1 do
    if TMemoryRecord(treeview.items[i].data).isSelected then
    begin
      //only move it if it has no parent that is selected
      if hasSelectedParent(TMemoryRecord(treeview.items[i].data))=false then
      begin
        setlength(selectednodelist,length(selectednodelist)+1);
        selectednodelist[length(selectednodelist)-1]:=treeview.items[i];
      end;
    end;

  node:=TreeView.GetNodeAt(x,y);




  if node<>nil then
  begin
    if not (CurrentlyDraggedOverBefore or CurrentlyDraggedOverAfter) then //add it
    begin
      //add it to this entry at the end

      if source=treeview then //just be sure
        for i:=0 to length(selectednodelist)-1 do
          selectednodelist[i].MoveTo(node,naAddChild);

      if source is TListView then
        if assigned(fOnDropByListview) then
          fOnDropByListview(self, node, naAddChild);

    end
    else
    begin
      //else place it before or after this object   depending on the x,y pos
      if CurrentlyDraggedOverBefore then //before
      begin
        if source=treeview then
          for i:=0 to length(selectednodelist)-1 do
            selectednodelist[i].MoveTo(node, naInsert); //in front of destination


        if source is TListView then
          if assigned(fOnDropByListview) then
            fOnDropByListview(self, node, naInsert);
      end
      else
      begin  //after
        if source=treeview then
          for i:=length(selectednodelist)-1 downto 0 do
            selectednodelist[i].MoveTo(node, naInsertBehind); //after

        if source is Tlistview then
        begin
          //just insert it before the next node if possible
          if node.GetNextSibling<>nil then
          begin
            node:=node.GetNextSibling;

            if assigned(fOnDropByListview) then
              fOnDropByListview(self, node, naInsert);
          end
          else
            fOnDropByListview(self, node, naAdd);
        end;
      end;
    end;
  end else
  begin
    //place it at the very end

    if source=treeview then
      for i:=length(selectednodelist)-1 downto 0 do
        selectednodelist[i].MoveTo(nil, naAdd); //last sibling


    if source is Tlistview then
      if assigned(fOnDropByListview) then
        fOnDropByListview(self, node, naInsertBehind);

  end;

  treeview.DropTarget:=nil;
  treeview.refresh;
end;

function hasNonExpandedParent(parent: ttreenode): boolean;
begin
  if parent=nil then
    result:=false
  else
  begin
    result:=parent.Expanded=false; //becomes true if not expanded
    if not result then
      result:=hasNonExpandedParent(parent.parent);
  end;
end;

procedure TAddresslist.SelectionUpdate(sender: TObject);
var shift:TShiftState;
    i: integer;
   // firstnode, lastNode: TTreenode;
begin
  //Because the multiselect of lazarus is horribly broken in the build I use, I've just implemented it myself

  shift:=GetKeyShiftState;

  if (GetKeyState(VK_RBUTTON) and $8000)<>0 then
    Include(shift,ssRight);

  if Treeview.Selected<>nil then
  begin
    if ssShift in shift then
    begin
      //if shift is held then unselect the old selection and select everything between the last selection and the current selection as selected , and don't update the last selection
      //deselect everything
      for i:=0 to Count-1 do
        MemRecItems[i].isSelected:=false;

      //select verything inbetween (assuming it's visible)

      for i:=min(lastselected,treeview.selected.absoluteIndex) to max(lastselected,treeview.selected.absoluteIndex) do
      begin
        //check if any parent is not expanded, if so, isselected should be false
        MemRecItems[i].isSelected:=not hasNonExpandedParent(memrecitems[i].treenode.parent);
      end;
    end
    else
    if (ssCtrl in shift)  then //ctrl only works when used with left mouse
    begin
      //if control is held then leave everything selected and add the current item to the selected list
      TMemoryRecord(Treeview.Selected.data).isSelected:=not TMemoryRecord(Treeview.Selected.data).isSelected;

      lastSelected:=Treeview.Selected.AbsoluteIndex;

      if not TMemoryRecord(Treeview.Selected.data).isSelected then
        Treeview.Selected:=nil;

    end
    else
    begin
      //else unselect all old selections (and select the current item)
      //unless it's a rightclick on something that is already selected
      if not ((ssRight in shift) and (TMemoryRecord(Treeview.Selected.data).isSelected) ) then
      begin
        for i:=0 to Count-1 do
          MemRecItems[i].isSelected:=false;

        TMemoryRecord(Treeview.Selected.data).isSelected:=true;
        lastSelected:=Treeview.Selected.AbsoluteIndex;
      end;
    end;
  end;
end;

procedure TAddresslist.doAnimation(sender: TObject);
var
  i: integer;
  updated: boolean;
  start,stop: integer;
begin
  updated:=false;

  start:=0;
  stop:=treeview.Items.Count-1;

   {

  if treeview.TopItem<>nil then
    start:=treeview.TopItem.Index
  else
    start:=0;

  if treeview.BottomItem<>nil then
    stop:=treeview.BottomItem.Index
  else
    stop:=count-1; }

  for i:=start to stop do
  begin
    if TMemoryRecord(Treeview.items[i].data).isProcessing then
    begin
      memrecitems[i].treenode.Update;
      updated:=true;
    end;
  end;

  if not updated then
    animationtimer.enabled:=false;
end;

procedure TAddresslist.AdvancedCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
var
  textrect: trect;
  linerect: trect;
  fulltextline: trect;
  memrec: TMemoryRecord;

  checkbox: trect;
  oldbrushcolor: TColor;
  pointertag: string;
  oldpenmode: TFPPenMode;
  oldpencolor: tcolor;

  descriptionstart: integer;

  linetop: integer;

  expandsign: Trect;

  expandsignlineborderspace: integer;

  n: Ttreenode;
  t:integer;
  cx,cy: integer;
  x,y: single;
  r: single;

  bordersize: integer;

  tempstring: string;

  c: Tcolor;
begin
  //multiselect implementation





  DefaultDraw:=true;
  PaintImages:=true;

  if stage=cdPostPaint then
  begin
    oldbrushcolor:=sender.Canvas.Brush.Color;
    textrect:=node.DisplayRect(true);
    linerect:=node.DisplayRect(false);
    fulltextline:=linerect;
    fulltextline.Left:=textrect.Left;

    memrec:=TMemoryRecord(Node.data);


    sender.Canvas.Brush.color:=sender.Color;
    fulltextline.left:=0;
    sender.Canvas.FillRect(fulltextline); //whipe the original text

    //exit;

    if not memrec.visible then //don't render it
      exit;


    bordersize:=1*trunc(fontmultiplication);

    if expandsignsize=0 then
    begin
      expandsignsize:=treeview.indent div 2;
      if expandsignsize mod 2=0 then
        dec(expandsignsize);    //has to be uneven

      if expandsignsize<9 then
        expandsignsize:=9;
    end;



    if memrec.isSelected then
    begin
      if node.Selected then
        sender.Canvas.Brush.Color:=ColorToRGB(SelectedBackgroundColor)  //SelectedBackgroundColor //clHighlight
      else
        sender.Canvas.Brush.Color:=ColorToRGB(SelectedSecondaryBackgroundColor); //clActiveCaption;

      oldpenmode:=sender.Canvas.Pen.Mode;
      sender.Canvas.Pen.Mode:=pmMask;
      sender.canvas.pen.color:=sender.Canvas.Brush.Color;

      sender.Canvas.Rectangle(linerect);
      sender.Canvas.Pen.Mode:=oldpenmode;
    end;


    if memrec.isSelected then
    begin
      sender.canvas.pen.color:=clWindowtext;
      sender.Canvas.Font.Color:=INVERTCOLOR(ColorToRGB(SelectedBackgroundColor));//  InvertColor(memrec.Color)
    end
    else
    begin
      sender.canvas.pen.color:=clWindowtext;
      sender.Canvas.Font.Color:=memrec.Color;
    end;

    n:=node.parent;
    while n<>nil do
    begin
      if moManualExpandCollapse in TMemoryRecord(n.Data).Options then
        inc(textrect.left,expandsignsize+1);


      n:=n.Parent;
    end;

    sender.canvas.Pen.JoinStyle:=pjsMiter;
    sender.canvas.Pen.EndCap:=pecFlat;
    sender.canvas.pen.Width:=1;

    if moManualExpandCollapse in memrec.Options then
    begin
      //draw the expand sign (+/-)  (taken and modified from treeview.inc)
      oldpencolor:=sender.canvas.pen.color;
      sender.canvas.pen.color:=expandSignColor;



      expandsignlineborderspace:=expandsignsize div 4;

      if expandsignsize mod 4>2 then //round up
        inc(expandsignlineborderspace);


      expandsign:=Rect(textrect.left, textrect.top+((textrect.bottom-textrect.top) div 2-(expandsignsize div 2)), textrect.left+expandsignsize, textrect.top+((textrect.bottom-textrect.top) div 2+(expandsignsize div 2))+1);
      sender.canvas.Rectangle(expandsign);

      //horizontal line
      sender.canvas.MoveTo(expandsign.Left + expandsignlineborderspace, textrect.top+(textrect.bottom-textrect.top) div 2);
      sender.canvas.LineTo(expandsign.Right - expandsignlineborderspace, textrect.top+(textrect.bottom-textrect.top) div 2);


      if memrec.treenode.Expanded then
      begin
        //vertical line
        sender.canvas.MoveTo(expandsign.left+expandsignsize div 2, expandsign.Top + expandsignlineborderspace);
        sender.canvas.LineTo(expandsign.left+expandsignsize div 2, expandsign.Bottom - expandsignlineborderspace);
      end;
      inc(textrect.left,expandsignsize+1);

      sender.canvas.pen.color:=oldpencolor;
    end;

    sender.canvas.pen.Width:=bordersize;
    sender.canvas.pen.EndCap:=pecFlat;


    //draw checkbox
    oldpencolor:=sender.canvas.pen.color;
    checkbox.Left:=textrect.left+1; //(header.Sections[0].Width div 2)-((linerect.bottom-linerect.top) div 2)+1;
    checkbox.Right:=checkbox.left+(linerect.bottom-linerect.top)-2; //(header.Sections[0].Width div 2)+((linerect.bottom-linerect.top) div 2)-1;
    checkbox.Top:=linerect.top+1;
    checkbox.Bottom:=linerect.bottom-1;



    if not memrec.AsyncProcessing then
    begin




      sender.canvas.pen.color:=oldpencolor;

      if memrec.Active then //draw a check
      begin
        oldpencolor:=sender.canvas.pen.color;

        if memrec.isSelected then
          sender.canvas.pen.color:=checkboxActiveSelectedColor
        else
          sender.canvas.pen.color:=checkboxActiveColor;




   {
        //default: this is good
        sender.canvas.Line(checkbox.left+1,checkbox.Top+1, checkbox.Right-1,checkbox.bottom-1);
        sender.canvas.line(checkbox.left+1,checkbox.bottom-2, checkbox.right-1,checkbox.top);  }

        sender.canvas.Line(checkbox.left,checkbox.Top, checkbox.Right-1,checkbox.bottom-1);
        sender.canvas.line(checkbox.left,checkbox.bottom-1, checkbox.right-1,checkbox.top);

        sender.canvas.pen.color:=oldpencolor;


        if (not memrec.isGroupHeader) and (memrec.VarType<>vtAutoAssembler) then
        begin
          //draw the arrow up/down, unless it's a group or auto assembler type
          if memrec.allowIncrease then
          begin
            sender.Canvas.Pen.Color:=increaseArrowColor; //clGreen
            sender.canvas.line(checkbox.right+5, checkbox.bottom-1, checkbox.right+5,checkbox.top+1);
            sender.canvas.line(checkbox.right+5,checkbox.top+1,checkbox.Right+5-4,checkbox.top+1+4);
            sender.canvas.line(checkbox.right+5,checkbox.top+1,checkbox.Right+5+4,checkbox.top+1+4);
            sender.canvas.pen.color:=oldpencolor;
          end;

          if memrec.allowDecrease then
          begin
            sender.Canvas.Pen.Color:=decreaseArrowColor; //clRed;
            sender.canvas.line(checkbox.right+5, checkbox.bottom-1, checkbox.right+5,checkbox.top+1);
            sender.canvas.line(checkbox.right+5,checkbox.bottom-1,checkbox.Right+5-4,checkbox.bottom-1-4);
            sender.canvas.line(checkbox.right+5,checkbox.bottom-1,checkbox.Right+5+4,checkbox.bottom-1-4);
            sender.canvas.pen.color:=oldpencolor;
          end;
        end;

      end;

      //draw the rectangle over the cross
      if memrec.isSelected then
        sender.canvas.pen.color:=checkboxSelectedColor
      else
        sender.canvas.pen.color:=checkboxColor;


      sender.Canvas.Brush.Style:=bsClear;
      sender.Canvas.Rectangle(checkbox);
      sender.Canvas.Brush.Style:=bsSolid;

    end
    else
    begin
      //draw a clock
      if memrec.isSelected then
        sender.canvas.pen.color:=checkboxSelectedColor
      else
        sender.canvas.pen.color:=checkboxColor;

      sender.Canvas.Ellipse(checkbox);

      r:=(checkbox.right-checkbox.left) div 2;
      cx:=trunc(checkbox.left+r);
      cy:=trunc(checkbox.top+r);

      t:=memrec.AsyncProcessingTime mod 1000; //every time t=0 the line should be up (value 0)
      t:=trunc(t*0.36); //every second is a full rotation

      x:=cx+cos(pi*(270+t mod 360)/180)*r*ifthen(memrec.Active,-1,1);
      y:=cy+sin(pi*(270+t mod 360)/180)*r;

      sender.Canvas.Line(cx,cy,trunc(x),trunc(y));


      if memrec.isSelected then
        sender.canvas.pen.color:=IncreaseArrowColor
      else
        sender.canvas.pen.color:=DecreaseArrowColor;

      t:=(memrec.AsyncProcessingTime div 1000) mod 60; //every 60 seconds (t=0) the second handle should be up
      t:=t*6;

      x:=cx+cos(pi*(270+t mod 360)/180)*r*ifthen(memrec.Active,-1,1);
      y:=cy+sin(pi*(270+t mod 360)/180)*r;

      sender.Canvas.Line(cx,cy,trunc(x),trunc(y));


      sender.canvas.pen.color:=oldpencolor;

      if animationtimer=nil then
      begin
        animationtimer:=TTimer.Create(self);
        animationtimer.interval:=16;
        animationtimer.OnTimer:=DoAnimation;
      end;

      animationtimer.enabled:=true;
    end;
    descriptionstart:=max(checkbox.right+10,header.Sections[1].Left);




    linetop:=textrect.Top+1; ;//+((textrect.Bottom-textrect.Top) div 2)-(sender.canvas.TextHeight('DDDD') div 2);


    if (not memrec.isGroupHeader or memrec.isAddressGroupHeader) and (memrec.VarType<>vtAutoAssembler) then //if it's not a groupheader of auto assemble script then show the extra data
    begin
      //limit how far the texts go depending on the sections
      sender.Canvas.TextRect(rect(descriptionstart, textrect.Top, header.Sections[1].right, textrect.bottom), descriptionstart, linetop, memrec.description);

      //if this is not the currently dragged over node
      //or if it is and either CurrentlyDraggedOverBefore or CurrentlyDraggedOverAfter is set then draw the rest
      if not ((node=CurrentlyDraggedOverNode) and (not (CurrentlyDraggedOverBefore or CurrentlyDraggedOverAfter))) then //don't draw the rest on insert drag/drop
      begin
        //address
        sender.Canvas.TextRect(rect(header.Sections[2].left, textrect.Top, header.Sections[2].right, textrect.bottom),header.Sections[2].Left, linetop, ansitoutf8(memrec.addressString));

        if not memrec.isGroupHeader then
        begin
          //type
          case memrec.vartype of
            vtCustom: sender.Canvas.TextRect(rect(header.Sections[3].left, textrect.Top, header.Sections[3].right, textrect.bottom),header.sections[3].left, linetop, memrec.CustomTypeName);
            vtString:
            begin
              if not (memrec.Extra.stringData.unicode or memrec.Extra.stringData.codepage) then
                sender.Canvas.TextRect(rect(header.Sections[3].left, textrect.Top, header.Sections[3].right, textrect.bottom),header.sections[3].left, linetop, VariableTypeToTranslatedString(memrec.VarType)+'['+inttostr(memrec.Extra.stringData.length)+']')
              else if memrec.Extra.stringData.unicode then
                sender.Canvas.TextRect(rect(header.Sections[3].left, textrect.Top, header.Sections[3].right, textrect.bottom),header.sections[3].left, linetop, VariableTypeToTranslatedString(vtUnicodeString)+'['+inttostr(memrec.Extra.stringData.length)+']')
              else
                sender.Canvas.TextRect(rect(header.Sections[3].left, textrect.Top, header.Sections[3].right, textrect.bottom),header.sections[3].left, linetop, VariableTypeToTranslatedString(vtCodePageString)+'['+inttostr(memrec.Extra.stringData.length)+']');
            end;
            vtBinary:
            begin
              if memrec.Extra.bitData.bitlength=0 then
                sender.Canvas.TextRect(rect(header.Sections[3].left, textrect.Top, header.Sections[3].right, textrect.bottom),header.sections[3].left, linetop, VariableTypeToTranslatedString(memrec.VarType)+':'+inttostr(memrec.Extra.bitData.Bit)+'->idiot')
              else
                sender.Canvas.TextRect(rect(header.Sections[3].left, textrect.Top, header.Sections[3].right, textrect.bottom),header.sections[3].left, linetop, VariableTypeToTranslatedString(memrec.VarType)+':'+inttostr(memrec.Extra.bitData.Bit)+'->'+inttostr(memrec.Extra.bitData.Bit+memrec.Extra.bitData.bitlength-1));
            end
            else
            begin

              sender.Canvas.TextRect(rect(header.Sections[3].left, textrect.Top, header.Sections[3].right, textrect.bottom),header.sections[3].left, linetop, VariableTypeToTranslatedString(memrec.VarType));
            end
          end;


          //value
          sender.Canvas.TextRect(rect(header.Sections[4].left, textrect.top, header.Sections[4].right, textrect.bottom),header.sections[4].left, linetop, memrec.DisplayValue);
        end;
      end;
    end
    else
    begin
      sender.Canvas.TextOut(descriptionstart, linetop, memrec.description); //no limit on how far

      if (memrec.VarType=vtAutoAssembler) then //give it the <script> text for value
      begin
        tempstring:=rsScript;
        if assigned(memrec.OnGetDisplayValue) then
        begin
          if memrec.OnGetDisplayValue(memrec, tempstring) = false then
            tempstring:=rsscript; //undo, it returned false
        end;

        sender.Canvas.TextRect(rect(header.Sections[4].left, textrect.Top, header.Sections[4].right, textrect.bottom), header.sections[4].left, linetop, tempstring);
      end;

    end;

    if node=CurrentlyDraggedOverNode then
    begin
      if CurrentlyDraggedOverBefore then //draw before
        sender.Canvas.Line(0,max(0,linerect.top-1),linerect.right,max(0,linerect.top-1))
      else
      if CurrentlyDraggedOverAfter then //raw after
        sender.Canvas.Line(0,linerect.bottom-1,linerect.right,linerect.bottom-1)
      else  //draw inside
        sender.Canvas.Line(descriptionstart+sender.canvas.textwidth(memrec.description)+1,(linerect.top+linerect.Bottom) div 2,linerect.right,(linerect.top+linerect.Bottom) div 2)
    end;


    if sender.Focused and node.Selected then
      sender.Canvas.DrawFocusRect(linerect);

    sender.Canvas.Brush.Color:=oldbrushcolor;
  end;


end;


procedure TAddresslist.SymbolsLoaded(sender: TObject);
begin
  ReinterpretAddresses;
end;


function TAddresslist.focused: boolean;
begin
  result:=inherited focused;
  if not result then result:=treeview.Focused;
end;

function TAddresslist.getLoadedTableVersion: integer;
begin
  result:=lastLoadedTableVersion;
end;

procedure TAddresslist.getAddressList(list: Tstrings);
{
Gets the addresslist in lines formatted :  address=description
main usage: pointerscan and scandata.addresslist files
}
var i: integer;
begin
  for i:=0 to Count-1 do
  begin
    if MemRecItems[i].AddressString<>'' then
      list.add(MemRecItems[i].AddressString+'='+MemRecItems[i].Description);
  end;
end;

procedure TAddressList.DoAutoSize;
begin
  DisableAutoSizing;
  header.Height:=header.canvas.GetTextHeight('D')+4;

  treeview.Indent:=Treeview.DefaultItemHeight; //checkbox.Bottom-checkbox.Top;

  EnableAutoSizing;

  inherited DoAutoSize;
end;

procedure TAddresslist.miSortOnClickClick(Sender: TObject);
begin
  cereg.writeBool('Addresslist: sort on click', miSortOnClick.Checked);
end;

constructor TAddresslist.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

 // ShowHint:=true;

  descriptionhashlist:=TStringHashList.Create(false);

  treeview:=TTreeviewWithScroll.create(self); //TTreeview.create(self);
  treeview.name:='List';

  treeview.BorderStyle:=bsNone;
  treeview.BorderWidth:=0;;

  treeview.RowSelect:=true;
  treeview.ReadOnly:=true;
  treeview.ShowRoot:=false;
 // treeview.multiselect:=true;  bad
  Treeview.RightClickSelect:=true;

  treeview.DragMode:=dmAutomatic;
  treeview.HideSelection:=false;

  treeview.ShowButtons:=true;
 // treeview.ShowHint:=true;




  treeview.AutoExpand:=true;
  treeview.Options:=treeview.options+[tvoAutoExpand, tvoNoDoubleClickExpand ];


  treeview.OnAdvancedCustomDrawItem:=AdvancedCustomDrawItem;
  treeview.OnSelectionChanged:=SelectionUpdate;
  treeview.OnExit:=Focuschange;
  treeview.OnEnter:=Focuschange;

  treeview.OnDragOver:=TVDragOver;
  treeview.OnDragDrop:=TVDragDrop;
  treeview.OnEndDrag:=TVDragEnd;
 // treeview.OnKeyDown:=treeviewkeydown;
//  treeview.Indent:=32;

  treeview.OnCollapsing:=TreeviewOnCollapse;
  treeview.OnExpanding:=TreeviewOnExpand;

  treeview.OnMouseDown:=TreeviewMouseDown;
  treeview.OnDblClick:=TreeviewDblClick;

  //treeview.Options:=treeview.Options+[tvoAllowMultiselect];    Horribly broken

  treeview.parent:=self;

  treeview.Options:=treeview.options-[tvoAutoItemHeight];
  treeview.Options:=treeview.options+[tvoAutoItemHeight];




  header:=THeaderControl.Create(self);
  header.name:='Header';
  header.parent:=self;
  header.Align:=alTop;
  header.Height:=header.font.GetTextHeight('D')+4;

  with header.Sections.Add do
  begin
    Text:=rsActive;
    Width:=40;
    MinWidth:=5;
  end;

  with header.Sections.Add do
  begin
    Text:=rsDescription;
    Width:=160;
    MinWidth:=5;
  end;

  with header.Sections.Add do
  begin
    Text:=rsAddress;
    Width:=85;
    MinWidth:=5;
  end;

  with header.Sections.Add do
  begin
    Text:=rsType;
    Width:=60;
    MinWidth:=5;
  end;

  with header.Sections.Add do
  begin
    Text:=rsValue;
    Width:=9000000;
    MinWidth:=5;
  end;

  header.OnSectionTrack:=SectionTrack;

  header.OnSectionClick:=SectionClick;
  header.AutoSize:=true;


  headerpopup:=TPopupmenu.Create(header);
  miSortOnClick:=TMenuItem.Create(headerpopup);
  miSortOnClick.Caption:=rsSortOnClick;
  miSortOnClick.ShowAlwaysCheckable:=true;
  miSortOnClick.Checked:=cereg.readBool('Addresslist: sort on click', true);
  miSortOnClick.AutoCheck:=true;
  miSortOnClick.OnClick:=miSortOnClickClick;
  headerpopup.Items.Add(miSortOnClick);

  header.PopupMenu:=headerpopup;


  treeview.ScrollBars:=ssVertical;
  treeview.Align:=alClient;

  symhandler.AddFinishedLoadingSymbolsNotification(SymbolsLoaded);



  checkboxActiveSelectedColor:=clRed;
  CheckboxActiveColor:=clRed;
  CheckboxSelectedColor:=clWindowtext;
  CheckboxColor:=clWindowtext;
  SelectedBackgroundColor:=clHighlight;
  SelectedSecondaryBackgroundColor:=clActiveCaption;
  expandSignColor:=clWindowText;
  increaseArrowColor:=clGreen;
  decreaseArrowColor:=clRed;


end;

destructor TAddresslist.Destroy;
begin
  clear;

  symhandler.RemoveFinishedLoadingSymbolsNotification(SymbolsLoaded);
  inherited destroy;
end;

initialization
  registerclass(TAddresslist);       //yes...

  ForbiddenSearchDescriptions:=TStringHashList.Create(false);
  ForbiddenSearchDescriptions.Add('BYTE',pointer(-1));
  ForbiddenSearchDescriptions.Add('WORD',pointer(-1));
  ForbiddenSearchDescriptions.Add('DWORD',pointer(-1));
  ForbiddenSearchDescriptions.Add('QWORD',pointer(-1));
  ForbiddenSearchDescriptions.Add('UINT64',pointer(-1));
  ForbiddenSearchDescriptions.Add('CHAR',pointer(-1));
  ForbiddenSearchDescriptions.Add('SHORT',pointer(-1));
  ForbiddenSearchDescriptions.Add('LONG',pointer(-1));
  ForbiddenSearchDescriptions.Add('LONGLONG',pointer(-1));
  ForbiddenSearchDescriptions.Add('INT64',pointer(-1));

  ForbiddenSearchDescriptions.Add('INT',pointer(-1));
  ForbiddenSearchDescriptions.Add('FLOAT',pointer(-1));

  ForbiddenSearchDescriptions.Add('DOUBLE',pointer(-1));
  ForbiddenSearchDescriptions.Add('DOUBLE32L',pointer(-1));
  ForbiddenSearchDescriptions.Add('DOUBLE32H',pointer(-1));


end.
