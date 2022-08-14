unit addressedit;

{$mode delphi}

interface

uses
  Classes, SysUtils, StdCtrls, Graphics, betterControls;


type
  TAddressEdit=class(Tedit)
  private
    finvalidAddress: boolean;
    finvalidcolor: Tcolor;
    fValidColor: TColor;
    function getAddress: ptruint;
  protected
    procedure Change; override;
  public
    property invalidAddress: boolean read fInvalidAddress;
    property address: ptruint read getAddress;
    constructor Create(AOwner: TComponent); override;
  published
    property invalidColor: Tcolor read fInvalidColor write fInvalidColor;
    property validColor: TColor read fValidColor write fValidColor;
  end;


implementation

uses symbolhandler, newkernelhandler, ProcessHandlerUnit{$ifdef darwin},macport{$endif};

function TAddressEdit.getAddress: ptruint;
var
  a: ptruint;
  b: byte;
  br: ptruint;
begin
  a:=symhandler.getAddressFromName(Text, false, finvalidaddress);
  if finvalidaddress=false then
  begin
    result:=a;
    finvalidaddress:=not readprocessmemory(processhandle, pointer(a),@b,1,br);
  end
  else
    result:=0;

  if finvalidaddress then
    Font.Color:=invalidColor
  else
    Font.Color:=fValidColor;


end;

procedure TAddressEdit.change;
begin
  //get the string in the editbox and parse it. On error, indicate with red text
  getAddress;

  inherited change;
end;

constructor TAddressEdit.Create(AOwner: TComponent);
begin
  inherited create(AOwner);
  fInvalidColor:=clRed;
  fValidColor:=clWindowtext;
end;

end.

