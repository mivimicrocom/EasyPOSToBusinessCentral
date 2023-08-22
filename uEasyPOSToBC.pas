unit uEasyPOSToBC;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.SvcMgr,
  Vcl.Dialogs;

type
  TEasyPOSToBusinessCentralService = class(TService)
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  EasyPOSToBusinessCentralService: TEasyPOSToBusinessCentralService;

implementation

{$R *.dfm}


uses
  Registry,
  INIFiles,
  UDM;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  EasyPOSToBusinessCentralService.Controller(CtrlCode);
end;

function TEasyPOSToBusinessCentralService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TEasyPOSToBusinessCentralService.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('\SYSTEM\CurrentControlSet\Services\' + Name, false) then
    begin
      Reg.WriteString('Description', 'EasyPOS Service to synconize data from EasyPOS to BUsiness Central.');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TEasyPOSToBusinessCentralService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  DM.iniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Settings.INI');
  DM.tiTimer.Interval := 2000;
  DM.tiTimer.Enabled := TRUE;
end;

procedure TEasyPOSToBusinessCentralService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  try
    DM.iniFile.Free;
  except

  end;
end;

end.
