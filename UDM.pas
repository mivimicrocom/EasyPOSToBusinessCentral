unit UDM;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.ExtCtrls,
  System.IniFiles,
  DateUtils,
  UrlMon,
  JPEG,
  WinApi.WinINet,
  WinApi.Windows,
  WinApi.Messages,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.SvcMgr,
  Vcl.Dialogs,
  Data.DB,
  System.NetEncoding,
  IBX.IBCustomDataSet,
  IBX.IBQuery,
  IBX.IBDatabase;

type
  TDM = class(TDataModule)
    DB: TIBDatabase;
    tr: TIBTransaction;
    QFetchWEBOrder: TIBQuery;
    tiTimer: TTimer;
    trInsert: TIBTransaction;
    QTemp: TIBQuery;
    procedure tiTimerTimer(Sender: TObject);
  private
    {Private declarations}
    glTimer: Integer;
    LocalDatabase: string;
    LocalUser: string;
    LocalPassword: string;
    LocalLogFileFolder: String;
    procedure LocalAddLog(lStr: String);
    procedure InitialilzeProgram;
    procedure DoHandleEksportToBusinessCentral;
  public
    {Public declarations}
    iniFile: TIniFile;
    mmoLog: TStringList;
  end;

var
  DM: TDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
{TDM}

procedure TDM.DoHandleEksportToBusinessCentral;
begin
  //This will check what to syncronize and do it.
end;

procedure TDM.InitialilzeProgram;
(*
  This routine will read global settings from the INI file.
  It will read the programs version.,
  All will be written to global logfile
*)
var
  PrgVers1, PrgVers2, PrgVers3, PrgVers4: Word;
  ii: Integer;
  lCustomer: string;
  lStr: string;
  ExeFolder: string;

  procedure GetBuildInfo(var V1, V2, V3, V4: Word);
  var
    VerInfoSize: DWord;
    JvVerInf: Pointer;
    VerValueSize: DWord;
    VerValue: PVSFixedFileInfo;
    Dummy: DWord;
  begin
    VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
    if VerInfoSize = 0 then
    begin
      Dummy := GetLastError;
    end; {if}
    GetMem(JvVerInf, VerInfoSize);
    GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, JvVerInf);
    VerQueryValue(JvVerInf, '\', Pointer(VerValue), VerValueSize);
    with VerValue^ do
    begin
      V1 := dwFileVersionMS shr 16;
      V2 := dwFileVersionMS and $FFFF;
      V3 := dwFileVersionLS shr 16;
      V4 := dwFileVersionLS and $FFFF;
    end;
    FreeMem(JvVerInf, VerInfoSize);
  end;

begin
  mmoLog.Clear;

  GetBuildInfo(PrgVers1, PrgVers2, PrgVers3, PrgVers4);

  glTimer := iniFile.ReadInteger('PROGRAM', 'TIMER', 300);
  LocalLogFileFolder := iniFile.ReadString('PROGRAM', 'LOGFILEFOLDER', '');
  ForceDirectories(LocalLogFileFolder);

  LocalAddLog('EasyPOS Service to synconize data from EasyPOS to BUsiness Central: ' + IntToStr(PrgVers1) + '.' + IntToStr(PrgVers2) + '.' + IntToStr(PrgVers3) + '.' + IntToStr(PrgVers4));
  LocalAddLog(' ');

  LocalAddLog('Program timer (i sekunder): ' + IntToStr(glTimer));
  LocalAddLog('LogFileFolder: ' + LocalLogFileFolder);
  LocalAddLog('INI File: ' + ExtractFilePath(ParamStr(0)) + 'Settings.INI');

  LocalDatabase := iniFile.ReadString('PROGRAM', 'DATABASE', '');
  LocalUser := iniFile.ReadString('PROGRAM', 'USER', '');
  LocalPassword := iniFile.ReadString('PROGRAM', 'PASSWORD', '');
  LocalAddLog('Database: ' + LocalDatabase);
  LocalAddLog('User: xxx');
  LocalAddLog('Password: xxx');

  LocalAddLog(' ');

  LocalAddLog('Initialize done  ');
  LocalAddLog('  ');

  tiTimer.Interval := glTimer * 1000;
end;

procedure TDM.LocalAddLog(lStr: String);
(*
  This will write into the local customer log
*)
var
  DumpFil: TextFile;
  DumpFilNavn: String;
  lStr2: String;
begin // WriteDumpFil
  try
    DumpFilNavn := LocalLogFileFolder;
    if (not(DirectoryExists(DumpFilNavn))) then
      CreateDir(DumpFilNavn);
    DumpFilNavn := LocalLogFileFolder + 'Log' + FormatDateTime('yyyymmdd', NOW) + '.Txt';
    AssignFile(DumpFil, DumpFilNavn);
    if (NOT(FileExists(DumpFilNavn))) then
    begin
      Rewrite(DumpFil);
    end
    else
    begin
      Append(DumpFil);
    end;
    lStr2 := FormatDateTime('dd-mm-yyyy hh:mm:ss', NOW) + ' - ' + lStr;
    WriteLn(DumpFil, lStr2);
    Flush(DumpFil);
    CloseFile(DumpFil);
  except
    on E: Exception do
    begin
    end;
  end;
  mmoLog.Add(lStr2);
end;

procedure TDM.tiTimerTimer(Sender: TObject);
begin
  tiTimer.Enabled := FALSE;
  DoHandleEksportToBusinessCentral;
  tiTimer.Interval := glTimer * 1000;
  tiTimer.Enabled := TRUE;
end;

end.
