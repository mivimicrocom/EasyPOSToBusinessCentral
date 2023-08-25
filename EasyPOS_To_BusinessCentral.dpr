program EasyPOS_To_BusinessCentral;

uses
{$IFDEF APPMODE}
  forms,
  System.SysUtils,
{$ELSE}
  Vcl.SvcMgr,
{$ENDIF }
  uEasyPOSToBC in 'uEasyPOSToBC.pas' {EasyPOSToBusinessCentralService: TService} ,
  UDM in 'UDM.pas' {DM: TDataModule} ,
{$IFDEF APPMODE}
  uMain in 'uMain.pas' {frmMain} ,
{$ENDIF }
  uBusinessCentralIntegration in 'Business-Central\uBusinessCentralIntegration.pas' {$R *.RES},
  uSendEMail in 'AfsendMail\uSendEMail.pas';

{$R *.RES}


begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
{$IFDEF APPMODE}
  ReportMemoryLeaksOnShutdown := TRUE;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TfrmMain, frmMain);
{$ELSE}
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TEasyPOSToBusinessCentralService, EasyPOSToBusinessCentralService);
{$ENDIF}
  Application.Run;

end.
