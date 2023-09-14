program EP_To_BC_Editor;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := TRUE;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
