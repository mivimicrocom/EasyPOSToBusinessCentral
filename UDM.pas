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
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.VCLUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  FireDAC.Phys.IBBase;

type
  TDM = class(TDataModule)
    tiTimer: TTimer;
    dbMain: TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    trnMain: TFDTransaction;
    qryFetchData: TFDQuery;
    procedure tiTimerTimer(Sender: TObject);
  private
    { Private declarations }
    glTimer: Integer;
    LocalDatabase: string;
    LocalUser: string;
    LocalPassword: string;
    LocalLogFileFolder: String;
    procedure LocalAddLog(aStringToWriteToLogFile: String);
    procedure InitialilzeProgram;
    procedure DoHandleEksportToBusinessCentral;
    function ConnectToDB: Boolean;
    procedure DisconnectFromDB;
    procedure DoClearLogFolder;
    procedure DoSyncronizeFinansCialRecords;
  public
    { Public declarations }
    iniFile: TIniFile;
  end;

var
  DM: TDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
{ TDM }

uses
  System.IOUtils;

const
  NumberOfDays = 21;

procedure TDM.LocalAddLog(aStringToWriteToLogFile: String);
(*
  This will write into the local log
*)
var
  lLogFileName: String;
  lTextToWriteToLogFile: String;
begin // LocalAddLog
  try
    ForceDirectories(LocalLogFileFolder);
    lLogFileName := LocalLogFileFolder + 'Log' + FormatDateTime('yyyymmdd', NOW) + '.Txt';

    lTextToWriteToLogFile := FormatDateTime('dd-mm-yyyy hh:mm:ss', NOW) + ' - ' + aStringToWriteToLogFile + #13#10;
    TFile.AppendAllText(lLogFileName, lTextToWriteToLogFile)

  except
    on E: Exception do
    begin
    end;
  end;
end;

function TDM.ConnectToDB: Boolean;
(*
  This will open a connection to a database
*)
var
  lServer: string;
  lDatabase: string;
begin
  try
    LocalAddLog('Connecting to database');

    lServer := Copy(LocalDatabase, 1, POS(':', LocalDatabase) - 1);
    lDatabase := Copy(LocalDatabase, POS(':', LocalDatabase) + 1, length(LocalDatabase) - POS(':', LocalDatabase));

    dbMain.Close;
    dbMain.Params.Clear;
    dbMain.Params.Add('DriverID=FB');
    dbMain.Params.Add('Server=' + lServer);
    dbMain.Params.Add('Database=' + lDatabase);
    dbMain.Params.Add('User_Name=' + LocalUser);
    dbMain.Params.Add('Password=' + LocalPassword);
    dbMain.Open;

    Result := TRUE;
    LocalAddLog('Connected to database');
  except
    on E: Exception do
    begin
      Result := FALSE;
      LocalAddLog('ERROR (Connect DB)!');
      LocalAddLog(E.Message);
    end;
  end;
end;

procedure TDM.DisconnectFromDB;
(*
  This will commit transaction and disconnect from database
*)
begin
  try
    if (trnMain.Active) then
      trnMain.Commit;
    dbMain.Close;
    LocalAddLog('Disconnected to database');
  except
    on E: Exception do
    begin
      LocalAddLog('ERROR (Disconnect DB)!');
      LocalAddLog(E.Message);
    end;
  end;
end;

procedure TDM.DoClearLogFolder;
var
  lFilSti: string;
  lFilNavn: string;
  FileAttrs: Integer;
  sr: TSearchRec;
begin
  LocalAddLog('Do clear log folders');
  lFilSti := LocalLogFileFolder;
  // Set log file wildcard
  lFilNavn := lFilSti + 'Log*.*';
  FileAttrs := faAnyFile;
  // Find first logfile
  if FindFirst(lFilNavn, FileAttrs, sr) = 0 then
  begin
    if (sr.TimeStamp < NOW - NumberOfDays) then
    begin
      if (not(DeleteFile(PChar(lFilSti + sr.Name)))) then
      begin
        LocalAddLog('  Could NOT delete: ' + lFilSti + sr.Name);
      end
      else
      begin
        LocalAddLog('  File deleted: ' + lFilSti + sr.Name);
      end;
    end;
  end;
  // Find next logfile
  while (FindNext(sr) = 0) do
  begin
    // If file is older than 31 days delete it-
    if (sr.TimeStamp < NOW - NumberOfDays) then
    begin
      if (not(DeleteFile(PChar(lFilSti + sr.Name)))) then
      begin
        LocalAddLog('  Could NOT delete: ' + lFilSti + sr.Name);
      end
      else
      begin
        LocalAddLog('  File deleted: ' + lFilSti + sr.Name);
      end;
    end;
  end;
  LocalAddLog('Log folder has been cleared');
end;

procedure TDM.DoSyncronizeFinansCialRecords;
begin
  LocalAddLog('DoSyncronizeFinansCialRecords - BEGIN');
  LocalAddLog('DoSyncronizeFinansCialRecords - END');
end;

procedure TDM.DoHandleEksportToBusinessCentral;
var
  lSyncroniseFinancialRecords: Boolean;
  lItems: Boolean;
  lSalesTransactions: Boolean;
  lMovementsTransactions: Boolean;
begin
  // This will check what to syncronize and do it.
  try
    DM.InitialilzeProgram;
    DoClearLogFolder;

    lSyncroniseFinancialRecords := iniFile.ReadBool('SYNCRONIZE', 'FinancialRecords', FALSE);
    lItems := iniFile.ReadBool('SYNCRONIZE', 'Items', FALSE);
    lSalesTransactions := iniFile.ReadBool('SYNCRONIZE', 'SalesTransactions', FALSE);
    lMovementsTransactions := iniFile.ReadBool('SYNCRONIZE', 'MovementsTransactions', FALSE);

    LocalAddLog(Format('Syncronize financial records: %s',[lSyncroniseFinancialRecords.ToString(TRUE)]));
    LocalAddLog(Format('Syncronize Items: %s',[lItems.ToString(TRUE)]));
    LocalAddLog(Format('Syncronize Sales Transactions: %s',[lSalesTransactions.ToString(TRUE)]));
    LocalAddLog(Format('Syncronize Movements Transaction: %s',[lMovementsTransactions.ToString(TRUE)]));

    if lSyncroniseFinancialRecords then
    begin
      DoSyncronizeFinansCialRecords;
    end;

    if lItems then
    begin

    end;

    if lSalesTransactions then
    begin

    end;

    if lMovementsTransactions then
    begin

    end;

    if (ConnectToDB) then
    begin
      DisconnectFromDB;
    end
    else
    begin
    end;
  except
  end;
end;

procedure TDM.InitialilzeProgram;
(*
  This routine will read global settings from the INI file.
  It will read the programs version.,
  All will be written to global logfile
*)
var
  PrgVers1, PrgVers2, PrgVers3, PrgVers4: Word;

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
    end; { if }
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
  GetBuildInfo(PrgVers1, PrgVers2, PrgVers3, PrgVers4);

  glTimer := iniFile.ReadInteger('PROGRAM', 'TIMER', 300);
  LocalLogFileFolder := iniFile.ReadString('PROGRAM', 'LOGFILEFOLDER', '');
  LocalLogFileFolder := 'c:\EasyPOSToBC\Logs\';
  ForceDirectories(LocalLogFileFolder);

  LocalAddLog('EasyPOS Service to synconize data from EasyPOS to BUsiness Central: ' +
              IntToStr(PrgVers1) + '.' + IntToStr(PrgVers2) + '.' + IntToStr(PrgVers3) + '.' + IntToStr(PrgVers4));
  LocalAddLog(' ');
  LocalAddLog('INI file: '+iniFile.FileName);
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

procedure TDM.tiTimerTimer(Sender: TObject);
begin
  tiTimer.Enabled := FALSE;
  DoHandleEksportToBusinessCentral;
  tiTimer.Interval := glTimer * 1000;
  tiTimer.Enabled := TRUE;
end;

end.
