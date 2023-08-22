unit uMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls;

type
  TfrmMain = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}


uses
  inifiles,
  UDM;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  DM.tiTimer.Interval := 2000;
  DM.tiTimer.Enabled := TRUE;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DM.iniFile.Free;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DM.iniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Settings.INI');
end;

end.
