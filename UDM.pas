{$IFDEF RELEASE}
{$ENDIF}
{$IFDEF DEBUG}
{$ENDIF}
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
    tnMain: TFDTransaction;
    QFetchFinancialRecords: TFDQuery;
    QFinansTemp: TFDQuery;
    GetNextTransactionIDToBC: TFDStoredProc;
    GetNextTransactionIDToBCTRANSID: TIntegerField;
    QFetchItems: TFDQuery;
    QItemsTemp: TFDQuery;
    QFetchSalesTransactions: TFDQuery;
    QSalesTransactionsTemp: TFDQuery;
    INS_Sladre: TFDQuery;
    QFetchMovementsTransactions: TFDQuery;
    QMovementsTransactionsTemp: TFDQuery;
    QFetchStockRegulationsTransactions: TFDQuery;
    QStockRegulationsTransationsTemp: TFDQuery;
    QSetEksportedValueOnSaleTrans: TFDQuery;
    trSetEksportedValueOnSaleTrans: TFDTransaction;
    QSetEksportedValueOnMovementsTrans: TFDQuery;
    trSetEksportedValueOnMovementsTrans: TFDTransaction;
    QSetEksportedValueOnStockTrans: TFDQuery;
    trSetEksportedValueOnStockTrans: TFDTransaction;
    QSetEksportedValueOnFinancialTrans: TFDQuery;
    trSetEksportedValueOnFinancialTrans: TFDTransaction;
    procedure tiTimerTimer(Sender: TObject);
  private
    { Private declarations }
    glTimer: Integer;

    EasyPOS_Database: string;
    EasyPOS_Database_User: string;
    EasyPOS_Database_Password: string;
    LogFileFolder: String;
    SQLLogFileFolder: String;

    EasyPOS_Department: String;
    EasyPOS_Machine: string;

    OnlyTestRoutine: Boolean;

    LF_BC_BASEURL: String;
    LF_BC_PORT_Int: Integer;
    LF_BC_PORT_Str: String;
    LF_BC_COMPANY_URL: String;
    LF_BC_USERNAME: String;
    LF_BC_PASSWORD: String;
    LF_BC_ACTIVECOMPANYID: String;
    LF_BC_Environment: string;
    LF_BC_Online: Boolean;
    LF_BC_Version: Integer; // 0: Current local based BC witrh basic authentication.   2: BC IN the sky with OAuth2 authentication

    function InitialilzeProgram: Boolean;
    procedure DoHandleEksportToBusinessCentral;
    function ConnectToDB: Boolean;
    procedure DisconnectFromDB;
    procedure DoClearFolder(aFolder: string; aFile: string);
    procedure DoSyncronizeFinansCialRecords;
    procedure DoSyncronizeItems;
    procedure DoSyncronizeMovemmentsTransaction;
    procedure DoSyncronizeSalesTransactions;
    function FetchBCSettings: Boolean;
    Function FetchNextTransID(aTransactionIDUSedFor: String): Integer;
    procedure AddToErrorLog(aStringToWriteToLogFile: String; aFileName: String);
    function SendErrorMail(aFileToAttach: string; aSection: string; aText: String): Boolean;
    procedure InsertTracingLog(aArt: Integer; aDateFrom: TDateTime; aDateTo: TDateTime; aTransID: Integer);
    procedure DoSyncronizeStockRegulationTransaction;
  public
    { Public declarations }
    iniFile: TIniFile;
    procedure AddToLog(aStringToWriteToLogFile: String);
  end;

var
  DM: TDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
{ TDM }

uses
  System.IOUtils,
  MVCFramework,
  MVCFramework.Serializer.Defaults,
  MVCFramework.Serializer.Commons,
  MVCFramework.Serializer.JsonDataObjects,
  uBusinessCentralIntegration,
  uSendEMail;

const
  NumberOfDays = 21;

function TDM.SendErrorMail(aFileToAttach: string; aSection: string; aText: String): Boolean;
var
  lSendEMailMailSetup: TSendEMailMailSetup;
  lSendEMailSMTPSetup: TSendEMailSMTPSetup;
  lSendEMail: TSendEMail;
  lFromName: string;
  lFromMail: string;
  lReplyName: string;
  lReplyMail: string;
  lRecipient: string;
  lSubject: string;
  lHost: string;
  lPort: Integer;
  lUsername: string;
  lPassword: string;
  MailContent: TStringList;
  aError: string;
  lUseTSL: Boolean;

  procedure SetupMailSettings(var aSMTPSetup: TSendEMailSMTPSetup; var aMailSetup: TSendEMailMailSetup);
  begin
    aMailSetup.ReceivingEMail := lRecipient;
    aMailSetup.ReplyToEMail := lReplyMail;
    aMailSetup.ReplyToName := lReplyName;
    aMailSetup.SenderEMail := lFromMail;
    aMailSetup.SenderName := lFromName;
    aMailSetup.EmailSubject := lSubject;
    aMailSetup.Attachment := '';
    aMailSetup.SendCopyToself := FALSE;

    aSMTPSetup.SMTPServer := lHost;
    aSMTPSetup.SMTPPort := lPort;
    aSMTPSetup.SMTPUsername := lUsername;
    aSMTPSetup.SMTPPassword := lPassword;
    aSMTPSetup.UseTLS := lUseTSL;
  end;

begin
  AddToLog('  DoMailFile - START');

  lFromName := iniFile.ReadString('MAIL', 'From name', '');
  lFromMail := iniFile.ReadString('MAIL', 'From mail', '');
  lReplyName := iniFile.ReadString('MAIL', 'Reply name', '');
  lReplyMail := iniFile.ReadString('MAIL', 'Reply mail', '');
  lRecipient := iniFile.ReadString('MAIL', 'Recipient Mail', '');
  lSubject := iniFile.ReadString('MAIL', 'Subject', '');
  lHost := iniFile.ReadString('MAIL', 'Host', '');
  lPort := iniFile.ReadInteger('MAIL', 'Port', 587);
  lUsername := iniFile.ReadString('MAIL', 'Username', '');
  lPassword := iniFile.ReadString('MAIL', 'Password', '');
  lUseTSL := iniFile.ReadBool('MAIL', 'UseTSL', FALSE);

  AddToLog('    Filename: ' + aFileToAttach);
  AddToLog('    Port: ' + lPort.ToString);
  AddToLog('    Host: ' + lHost);
  AddToLog('    MailFromName: ' + lFromName);
  AddToLog('    MailFromMail: ' + lFromMail);
  AddToLog('    MailReplyToName: ' + lReplyName);
  AddToLog('    MailReplyToMail: ' + lReplyMail);
  AddToLog('    MailSubject: ' + lSubject);
  AddToLog('    MailReciever: ' + lRecipient);

  Result := FALSE;
  if (lRecipient <> '') AND (lHost <> '') then
  begin
    // CReate mail
    AddToLog('    Create mailsetup');
    lSendEMailMailSetup := TSendEMailMailSetup.Create(nil);
    try
      // Create SMTP
      AddToLog('    Create smtpsetup');
      lSendEMailSMTPSetup := TSendEMailSMTPSetup.Create(nil);
      try
        // Set values.
        AddToLog('    SetupMailSettings');
        SetupMailSettings(lSendEMailSMTPSetup, lSendEMailMailSetup);

        AddToLog('    Set reply to, receiver, subject and attachment');
        lSendEMailMailSetup.ReplyToEMail := lReplyMail;
        lSendEMailMailSetup.ReplyToName := lReplyName;
        lSendEMailMailSetup.ReceivingEMail := lRecipient;
        lSendEMailMailSetup.EmailSubject := lSubject + ' - ' + aSection;
        lSendEMailMailSetup.Attachment := aFileToAttach;
        MailContent := TStringList.Create;
        try
          AddToLog('    Set content of mail');
          MailContent.Add(aText);
          lSendEMailMailSetup.EmailContent := MailContent;

          // Create Send mail
          AddToLog('    Create mail');
          lSendEMail := TSendEMail.Create(lSendEMailSMTPSetup);
          try
            try
              AddToLog(Format('    Send mail to %s', [lRecipient]));
              Result := lSendEMail.SendEMail(lSendEMailMailSetup, aError);
              if Result then
              begin
                AddToLog(Format('    Mail sendt', []));
              end
              else
              begin
                AddToLog(Format('    Error: %s', [aError]));
              end;
            except
              On E: Exception do
              begin
                AddToLog('  FEJL. Kan ikke afsende mail. ');
                AddToLog(E.Message);
              end;
            end;

          finally
            lSendEMail.Free;
          end;
        finally
          MailContent.Free;
        end;
      finally
        lSendEMailSMTPSetup.Free;
      end;
    finally
      lSendEMailMailSetup.Free;
    end;
  end
  else
  begin
    AddToLog('  Host or reciever not set');
  end;
  AddToLog('  DoMailFile - SLUT');
end;

procedure TDM.AddToLog(aStringToWriteToLogFile: String);
// This will write into the local log
var
  lLogFileName: String;
  lTextToWriteToLogFile: String;
begin
  try
    ForceDirectories(LogFileFolder);
    lLogFileName := LogFileFolder + 'Log' + FormatDateTime('yyyymmdd', NOW) + '.Txt';

    lTextToWriteToLogFile := FormatDateTime('dd-mm-yyyy hh:mm:ss', NOW) + ' - ' + aStringToWriteToLogFile + #13#10;
    TFile.AppendAllText(lLogFileName, lTextToWriteToLogFile, TEncoding.UTF8)

  except
    on E: Exception do
    begin
    end;
  end;
end;

procedure TDM.AddToErrorLog(aStringToWriteToLogFile: String; aFileName: String);
// This will write into the local error log
var
  lTextToWriteToLogFile: String;
begin
  try
    ForceDirectories(LogFileFolder);
    lTextToWriteToLogFile := FormatDateTime('dd-mm-yyyy hh:mm:ss', NOW) + ' - ' + aStringToWriteToLogFile + #13#10;
    TFile.AppendAllText(LogFileFolder + aFileName, lTextToWriteToLogFile, TEncoding.UTF8)
  except
    on E: Exception do
    begin
    end;
  end;
end;

function TDM.ConnectToDB: Boolean;
// This will open a connection to a database
var
  lServer: string;
  lDatabase: string;
begin
  try
    AddToLog('  Connecting to database');

    lServer := Copy(EasyPOS_Database, 1, POS(':', EasyPOS_Database) - 1);
    lDatabase := Copy(EasyPOS_Database, POS(':', EasyPOS_Database) + 1, length(EasyPOS_Database) - POS(':', EasyPOS_Database));

    dbMain.Close;
    dbMain.Params.Clear;
    dbMain.Params.Add('DriverID=FB');
    dbMain.Params.Add('Server=' + lServer);
    dbMain.Params.Add('Database=' + lDatabase);
    dbMain.Params.Add('User_Name=' + EasyPOS_Database_User);
    dbMain.Params.Add('Password=' + EasyPOS_Database_Password);
    dbMain.Open;
    AddToLog('  Connected to database');
    if (FetchBCSettings) then
    begin
      Result := TRUE;
    end
    else
    begin
      Result := FALSE;
      AddToLog('  Business Central settings not set');
    end;
  except
    on E: Exception do
    begin
      Result := FALSE;
      AddToLog('  ERROR (Connect DB)!');
      AddToLog(E.Message);
    end;
  end;
end;

procedure TDM.DisconnectFromDB;
// This will commit transaction and disconnect from database
begin
  try
    if (tnMain.Active) then
      tnMain.Commit;
    dbMain.Close;
    AddToLog('  Disconnected to database');
  except
    on E: Exception do
    begin
      AddToLog('  ERROR (Disconnect DB)!');
      AddToLog(E.Message);
    end;
  end;
end;

procedure TDM.InsertTracingLog(aArt: Integer; aDateFrom: TDateTime; aDateTo: TDateTime; aTransID: Integer);
Const
  TillagArt: Integer = 3000;
begin
  AddToLog(Format('Insert tracing log in DB. ART:%s,  Transaction ID: %s', [IntToStr(TillagArt + +aArt), aTransID.ToString]));
  try
    if (NOT(tnMain.Active)) then
      tnMain.StartTransaction;

    INS_Sladre.ParamByName('PDato').AsDateTime := NOW;
    INS_Sladre.ParamByName('PArt').AsInteger := TillagArt + aArt;
    INS_Sladre.ParamByName('PEkspedient').AsString := '99999';
    INS_Sladre.ParamByName('PVareFrvStrNr').AsString := '';
    Case aArt of
      1:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Eksport af vare til Business Central OK (Service). ';
        end;
      2:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Eksport af vare til Business Central IKKE OK (Service). ';
        end;
      3:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Eksport af leverandør faktura til Business Central OK (Service)';
        end;
      4:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Eksport af leverandør faktura IKKE OK';
        end;
      5:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Salg synk. med Business Central OK (Service) (' +
            FormatDateTime('dd-mm-yy hh:mm', aDateFrom) + '-' +
            FormatDateTime('dd-mm-yy hh:mm', aDateTo) + ')';
        end;
      6:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Salgstransaktioner IKKE sykroniseret med Business Central (Servive) ';
        end;
      7:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Tilg synk. med til Business Central OK (Service) ' +
            FormatDateTime('dd-mm-yy hh:mm', aDateFrom) + '-' +
            FormatDateTime('dd-mm-yy hh:mm', aDateTo) + ')';
        end;
      8:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Tilgangstransaktioner IKKE sykroniseret med Business Central (Servive) ';
        end;
      9:
        begin
          // if (KaldtFra = 3) then
          // Ins_Sladre.ParamByName('PBonText').AsString := 'Stat synk. med Nav. (' + FormatDateTime('ddmmyy hhmm', NOW) + ' for afdeling: ' + GemtAfdNr + ')'
          // else
          INS_Sladre.ParamByName('PBonText').AsString := 'Stat synk. til Business Central OK (Service) ' +
            FormatDateTime('dd-mm-yy hh:mm', aDateFrom) + '-' +
            FormatDateTime('dd-mm-yy hh:mm', aDateTo) + ')';
        end;
      10:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Statustransaktioner IKKE sykroniseret med Business Central (Servive) ';
        end;
      11:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Flyt synk. til Business Central OK (Service) ' +
            FormatDateTime('dd-mm-yy hh:mm', aDateFrom) + '-' +
            FormatDateTime('dd-mm-yy hh:mm', aDateTo) + ')';
        end;
      12:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Flytningstransaktioner IKKE sykroniseret med Business Central (Servive) ';
        end;
      13:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Lagerbeholdning synkroniseret til Business Central OK (Service) ';
        end;
      14:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Lagerbeholdning IKKE synkroniseret med Business Central (Servive) ';
        end;
      15:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Finansposter synkroniseret til Business Central OK (Service) ';
        end;
      16:
        begin
          INS_Sladre.ParamByName('PBonText').AsString := 'Finansposter IKKE synkroniseret med Business Central (Servive) ';
        end;
    end;
    AddToLog('  ' + INS_Sladre.ParamByName('PBonText').AsString);

    INS_Sladre.ParamByName('PLevNavn').AsString := 'TransID: Vare: ' + IntToStr(aTransID);
    INS_Sladre.ParamByName('PVareGrpId').AsString := '';

    INS_Sladre.ParamByName('PAfdeling_ID').AsString := '001';
    INS_Sladre.ParamByName('PUAfd_Navn').AsString := '';
    INS_Sladre.ParamByName('PUAfd_Grp_Navn').AsString := '';
    INS_Sladre.ExecSQL;

    if (tnMain.Active) then
      tnMain.Commit;
  except
    on E: Exception do
    begin
      AddToLog(Format('ERROR. %s', [E.Message]));
      if (tnMain.Active) then
        tnMain.Rollback;
    end;
  end;
end;

Function TDM.FetchNextTransID(aTransactionIDUSedFor: String): Integer;
begin
  AddToLog(Format('  Fetching next transaction ID for %s.', [aTransactionIDUSedFor]));
  GetNextTransactionIDToBC.ParamByName('Step').AsInteger := 1;
  GetNextTransactionIDToBC.ExecProc;
  Result := GetNextTransactionIDToBC.ParamByName('TransID').AsInteger;
  AddToLog(Format('    Transaction ID: %d.', [Result]))
end;

function TDM.FetchBCSettings: Boolean;
begin
  AddToLog('  Fetching Business Central settings from INI file');

  LF_BC_BASEURL := iniFile.ReadString('BUSINESS CENTRAL', 'BC_BASEURL', '');
  LF_BC_PORT_Int := iniFile.ReadInteger('BUSINESS CENTRAL', 'BC_PORT', 0);
  LF_BC_PORT_Str := LF_BC_PORT_Int.ToString;
  if LF_BC_PORT_Str = '0' then
    LF_BC_PORT_Str := '';
  LF_BC_COMPANY_URL := iniFile.ReadString('BUSINESS CENTRAL', 'BC_COMPANY_URL', '');
  LF_BC_Environment := iniFile.ReadString('BUSINESS CENTRAL', 'BC_ENVIRONMENT', '');
  LF_BC_USERNAME := iniFile.ReadString('BUSINESS CENTRAL', 'BC_USERNAME', '');
  LF_BC_PASSWORD := iniFile.ReadString('BUSINESS CENTRAL', 'BC_PASSWORD', '');
  LF_BC_ACTIVECOMPANYID := iniFile.ReadString('BUSINESS CENTRAL', 'BC_ACTIVECOMPANYID', '');
  LF_BC_Online := iniFile.ReadBool('BUSINESS CENTRAL', 'Online Business Central', FALSE);
  if LF_BC_Online then
  begin
    LF_BC_Version := 2;
  end
  else
  begin
    LF_BC_Version := 0;
  end;

  if (LF_BC_BASEURL = '') AND
    (LF_BC_PORT_Int = 0) AND
    (LF_BC_COMPANY_URL = '') AND
    (LF_BC_USERNAME = '') AND
    (LF_BC_PASSWORD = '') AND
    (LF_BC_ACTIVECOMPANYID = '') then
  begin
    AddToLog('  Nothing set in INI file. Fetching from database');

    QFinansTemp.SQL.Clear;
    QFinansTemp.SQL.Add('Select ');
    QFinansTemp.SQL.Add('  UNDERAFDELING.BC_BASEURL, ');
    QFinansTemp.SQL.Add('  UNDERAFDELING.BC_PORT, ');
    QFinansTemp.SQL.Add('  UNDERAFDELING.BC_COMPANY_URL, ');
    QFinansTemp.SQL.Add('  UNDERAFDELING.BC_USERNAME, ');
    QFinansTemp.SQL.Add('  UNDERAFDELING.BC_PASSWORD, ');
    QFinansTemp.SQL.Add('  UNDERAFDELING.BC_ACTIVECOMPANYID ');
    QFinansTemp.SQL.Add('from underafdeling where afdeling_ID=:PAfdeling_ID And Navn=:PNavn;');
    QFinansTemp.ParamByName('PAfdeling_ID').AsString := EasyPOS_Department;
    QFinansTemp.ParamByName('PNavn').AsString := EasyPOS_Machine;
    QFinansTemp.Open;
    LF_BC_BASEURL := QFinansTemp.FieldByName('BC_BASEURL').AsString;
    LF_BC_PORT_Int := QFinansTemp.FieldByName('BC_PORT').AsInteger;
    LF_BC_PORT_Str := LF_BC_PORT_Int.ToString;
    if LF_BC_PORT_Str = '0' then
      LF_BC_PORT_Str := '';
    LF_BC_COMPANY_URL := QFinansTemp.FieldByName('BC_COMPANY_URL').AsString;
    LF_BC_USERNAME := QFinansTemp.FieldByName('BC_USERNAME').AsString;
    LF_BC_PASSWORD := QFinansTemp.FieldByName('BC_PASSWORD').AsString;
    LF_BC_ACTIVECOMPANYID := QFinansTemp.FieldByName('BC_ACTIVECOMPANYID').AsString;
    QFinansTemp.Close;
  end;

  AddToLog('  LF_BC_BASEURL: ' + LF_BC_BASEURL);
  AddToLog('  LF_BC_PORT: ' + LF_BC_PORT_Str);
  AddToLog('  LF_BC_COMPANY_URL: ' + LF_BC_COMPANY_URL);
  AddToLog('  LF_BC_Environment: ' + LF_BC_Environment);
  AddToLog('  LF_BC_USERNAME: ' + LF_BC_USERNAME);
  AddToLog('  LF_BC_PASSWORD: ' + LF_BC_PASSWORD);
  AddToLog('  LF_BC_ACTIVECOMPANYID: ' + LF_BC_ACTIVECOMPANYID);
  AddToLog('  LF_BC_Online: ' + LF_BC_Online.ToString(TRUE) + '   LF_BC_Version: ' + LF_BC_Version.ToString);
  AddToLog(Format('Business Central version: %s (0: Current local based BC witrh basic authentication.   2: BC IN the sky with OAuth2 authentication) ', [LF_BC_Version.ToString]));

  Result :=
    ((LF_BC_BASEURL <> '') AND
    // (LF_BC_PORT <> 0) AND
    (LF_BC_COMPANY_URL <> '') AND
    (LF_BC_USERNAME <> '') AND
    (LF_BC_PASSWORD <> '') AND
    (LF_BC_ACTIVECOMPANYID <> ''));
end;

procedure TDM.DoClearFolder(aFolder: string; aFile: string);
var
  lFilSti: string;
  lFilNavn: string;
  FileAttrs: Integer;
  sr: TSearchRec;
begin
  AddToLog(Format('Do clear folder %s for files %s', [aFolder, aFile]));
  lFilSti := aFolder;
  // Set log file wildcard
  lFilNavn := lFilSti + aFile;
  FileAttrs := faAnyFile;
  // Find first logfile
  if FindFirst(lFilNavn, FileAttrs, sr) = 0 then
  begin
    if (sr.TimeStamp < NOW - NumberOfDays) then
    begin
      if (not(DeleteFile(PChar(lFilSti + sr.Name)))) then
      begin
        AddToLog('  Could NOT delete: ' + lFilSti + sr.Name);
      end
      else
      begin
        AddToLog('  File deleted: ' + lFilSti + sr.Name);
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
        AddToLog('  Could NOT delete: ' + lFilSti + sr.Name);
      end
      else
      begin
        AddToLog('  File deleted: ' + lFilSti + sr.Name);
      end;
    end;
  end;
  AddToLog('Log folder has been cleared');
  AddToLog('  ');
end;

procedure TDM.DoSyncronizeFinansCialRecords;
const
  lErrorFileName: String = 'FinancialErrors.txt';
var
  lFromDateAndTime: TDateTime;
  lToDateAndTime: TDateTime;
  lBusinessCentralSetup: TBusinessCentralSetup;
  lBusinessCentral: TBusinessCentral;
  lResponse: TBusinessCentral_Response;
  lExportCounter: Integer;
  lErrorCounter: Integer;
  lText: string;
  lDaysToLookAfterRecords: Integer;
  BC_TransactionID: Integer;
  lDateAndTimeOfLastRun: TDateTime;
  RoutineCanceled: Boolean;

  function CreateAndExportFinancialRecord: Boolean;
  var
    lkmCashstatement: TkmCashstatement;
    lStr: string;
    ExponGV: Boolean;
    lFinansEKsportFileName: string;
    lExportFile: TextFile;
    Delimiter: string;
    lErrotString: string;
    lJSONStr: string;
    DoContinue: Boolean;
    DoContinueWithInsert: Boolean;
    lGetResponse: TBusinessCentral_Response;

    function GetButiksID(lAfdNr: String): String;
    begin
      QFinansTemp.SQL.Clear;
      QFinansTemp.SQL.Add('Select NAVISION_IDX from afdeling where afdelingsnummer=:P1;');
      QFinansTemp.ParamByName('P1').AsString := lAfdNr;
      QFinansTemp.Open;
      Result := QFinansTemp.FieldByName('Navision_Idx').AsString;
      QFinansTemp.Close;
    end;

    procedure WriteEksportedRecordToTextfile;
    begin
      try
        if (not(DirectoryExists(LogFileFolder + 'FinansEksport\'))) then
          CreateDir(LogFileFolder + 'FinansEksport\');
        lFinansEKsportFileName := LogFileFolder + 'FinansEksport\' + 'EkspFinancialRecordsToBC' + FormatDateTime('yyyymmddhh', NOW) + '.Txt';
        AssignFile(lExportFile, lFinansEKsportFileName);
        Delimiter := ';';

        if (not(FileExists(lFinansEKsportFileName))) then
        begin
          ReWrite(lExportFile);
          WriteLn(lExportFile, 'EpID' + Delimiter + 'TransID' + Delimiter + 'TransDato' + Delimiter + 'TransTid' + Delimiter + 'BogføringsDato' + Delimiter + 'BogføringsTid' +
            Delimiter + 'Bilagsnummer' + Delimiter + 'Tekst' + Delimiter + 'Type' +
            Delimiter + 'ID' + Delimiter + 'Maskine' + Delimiter + 'Afdeling' + Delimiter + 'Butik' + Delimiter + 'Beløb');
        end
        else
        begin
          Append(lExportFile);
        end;

        WriteLn(lExportFile, IntToStr(lkmCashstatement.epId) + Delimiter + IntToStr(lkmCashstatement.transId) + Delimiter + lkmCashstatement.transDato + Delimiter +
          lkmCashstatement.transTid + Delimiter + lkmCashstatement.bogfRingsDato + Delimiter +
          lkmCashstatement.kasseOpgRelsestidspunkt + Delimiter + lkmCashstatement.bilagsnummer + Delimiter + lkmCashstatement.text + Delimiter + lkmCashstatement.type_ + Delimiter
          + lkmCashstatement.id + Delimiter + lkmCashstatement.kasse + Delimiter
          + lkmCashstatement.afdeling + Delimiter + lkmCashstatement.butik + Delimiter + FormatFloat('#,#0.00', lkmCashstatement.belB));

        CloseFile(lExportFile);
      except
      end;
    end;

    function MarkRecordAsHandled(aID: Integer): Boolean;
    begin
      if NOT(OnlyTestRoutine) then
      begin
{$IFDEF RELEASE}
        try
          if NOT trSetEksportedValueOnFinancialTrans.Active then
          begin
            trSetEksportedValueOnFinancialTrans.StartTransaction;
          end;

          AddToLog('  Mark selected records as handled');
          QSetEksportedValueOnFinancialTrans.SQL.Clear;

          QSetEksportedValueOnFinancialTrans.SQL.Add('UPDATE Posteringer SET ');
          QSetEksportedValueOnFinancialTrans.SQL.Add('    Behandlet = Behandlet + 1 ');
          QSetEksportedValueOnFinancialTrans.SQL.Add('WHERE ');
          QSetEksportedValueOnFinancialTrans.SQL.Add('    Posteringer.id = :PID');

          QSetEksportedValueOnFinancialTrans.ParamByName('PID').AsInteger := aID;
          QSetEksportedValueOnFinancialTrans.ExecSQL;

          if trSetEksportedValueOnFinancialTrans.Active then
          begin
            trSetEksportedValueOnFinancialTrans.Commit;
          end;
          Result := TRUE;
        except
          On E: Exception do
          begin
            Result := FALSE;
            lErrotString := 'Unexpected error when marking financial record exported in EasyPOS ' + #13#10 +
              '  EP ID: ' + aID.ToString + #13#10 +
              '  Message: ' + E.Message;
            AddToLog(lErrotString);
            AddToErrorLog(lErrotString, lErrorFileName);
          end;
        end;
{$ENDIF}
{$IFDEF DEBUG}
        AddToLog('  Will not mark records as handled. Only debug');
        Result := TRUE;
{$ENDIF}
      end
      else
      begin
        Result := TRUE;
      end;
    end;

  begin
    AddToLog(Format('  Checking ID %s in Business Central', [QFetchFinancialRecords.FieldByName('ID').AsString]));
    lBusinessCentralSetup.FilterValue := Format('epId eq %s', [QFetchFinancialRecords.FieldByName('ID').AsString]);
    // Mine order værdier.-
    lBusinessCentralSetup.OrderValue := '';
    // Select fields
    lBusinessCentralSetup.SelectValue := '';
    // Hent dem.
    DoContinueWithInsert := lBusinessCentral.GetkmCashstatements(lBusinessCentralSetup, lGetResponse, LF_BC_Version);

    if DoContinueWithInsert then
    begin
      if (lGetResponse as TkmCashstatements).Value.Count = 0 then
      begin
        lkmCashstatement := TkmCashstatement.Create;
        try
          lkmCashstatement.transId := BC_TransactionID;
          lkmCashstatement.epId := QFetchFinancialRecords.FieldByName('ID').AsInteger;

          lkmCashstatement.transDato := FormatDateTime('dd-mm-yyyy', NOW);
          lkmCashstatement.transTid := FormatDateTime('hh:mm:ss', NOW);

          lkmCashstatement.bogfRingsDato := FormatDateTime('dd-mm-yyyy', QFetchFinancialRecords.FieldByName('Dato').AsDateTime);

          if (length(QFetchFinancialRecords.FieldByName('Tekst').AsString) > 50) then
            lkmCashstatement.text := Copy(QFetchFinancialRecords.FieldByName('Tekst').AsString, 1, 50)
          else
            lkmCashstatement.text := QFetchFinancialRecords.FieldByName('Tekst').AsString;

          // 0=Finans,1=Debitor,2=Bank,3=Gavekort,4=Tilgodeseddel
          Case QFetchFinancialRecords.FieldByName('POstType').AsInteger of
            0, 25: // Oms. / Fragt
              begin
                lkmCashstatement.type_ := '0';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
              end;
            1: // Debitor
              begin
                lkmCashstatement.type_ := '1';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
              end;
            3: // Indbetalinger
              begin
                lkmCashstatement.type_ := '1';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
              end;
            4: // Udbetalinger
              begin
                lkmCashstatement.type_ := '0';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
                // Vil det være muligt at lave en ”fedtmule” løsning, hvor der under eksport af finansposter til BC kunne laves en konvertering fra F til K hvis
                // kontonummeret er 86123444?
                if (lkmCashstatement.id = '86123444') then
                begin
                  lkmCashstatement.type_ := '2';
                end;
              end;
            5: // Afr.
              begin
                lkmCashstatement.type_ := '0';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
              end;
            7: // Diff.
              begin
                lkmCashstatement.type_ := '0';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
              end;
            8: // Forskydning
              begin
                lkmCashstatement.type_ := '0';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
              end;
            21: // Aconto
              begin
                lkmCashstatement.type_ := '1';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
              end;
            22: // Tilgodeseddel
              begin
                if (QFetchFinancialRecords.FieldByName('Sortering').AsInteger = 50) then
                begin
                  // Modtaget en tilgodeseddel
                  // ÆNdret i samarbejde med Berit 19-05-2016 i flg ticket #4952
                  lkmCashstatement.type_ := '0';
                  // Kontonummer eller debitornummer
                  lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
                end
                else
                begin
                  // Udstedt en tilgodeseddel

                  // ÆNdret i samarbejde med Berit 19-05-2016 i flg ticket #4952
                  lkmCashstatement.type_ := '0';
                  // Kontonummer eller debitornummer
                  // ÆNdret i samarbejde med Berit 19-05-2016 i flg ticket #4952
                  lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
                end;
              end;
            23: // Gavekort
              begin
                if (QFetchFinancialRecords.FieldByName('Sortering').AsInteger = 120) then
                begin
                  // Modtaget et gavekort
                  ExponGV := (Trim('8372') = Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString)) OR
                    (Trim('8370') = Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString));
                  if (ExponGV) then
                    lkmCashstatement.type_ := '0'
                  else
                    lkmCashstatement.type_ := '3';

                  // Dette bliver det scannede gavekortsnummer
                  lStr := Trim(QFetchFinancialRecords.FieldByName('Tekst').AsString);
                  While (POS('GV ', lStr) > 0) do
                    Delete(lStr, POS('GV ', lStr), 3);

                  if (ExponGV) then
                  begin
                    lkmCashstatement.bilagsnummer := lStr;
                    lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
                  end
                  else
                  begin
                    lkmCashstatement.bilagsnummer := QFetchFinancialRecords.FieldByName('BilagsNr').AsString;;
                    lkmCashstatement.id := lStr;
                  end;

                  lkmCashstatement.text := QFetchFinancialRecords.FieldByName('Tekst').AsString;
                end
                else
                begin
                  // Udstedt et gavekort
                  ExponGV := (Trim('8372') = Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString)) OR
                    (Trim('8370') = Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString));
                  if (ExponGV) then
                  begin
                    // Gamle elektroniske (8370) eller nye (8372)
                    lkmCashstatement.type_ := '0';
                    lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
                    if ((Trim('8372') = Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString))) then
                      lkmCashstatement.bilagsnummer := Trim(QFetchFinancialRecords.FieldByName('BilagsNr2').AsString)
                    else
                      lkmCashstatement.bilagsnummer := QFetchFinancialRecords.FieldByName('BilagsNr').AsString;

                  end
                  else
                  begin
                    lkmCashstatement.type_ := '3';
                    // Rettet efter Oles anvisning.
                    lkmCashstatement.id := QFetchFinancialRecords.FieldByName('KontoNr').AsString;
                  end;
                end;

              end;
            99: // Int. afd. salg
              begin
                lkmCashstatement.type_ := '0';
                // Kontonummer eller debitornummer
                lkmCashstatement.id := Trim(QFetchFinancialRecords.FieldByName('KontoNr').AsString);
              end;
          end;

          lkmCashstatement.bilagsnummer := QFetchFinancialRecords.FieldByName('BilagsNr').AsString;

          lkmCashstatement.afdeling := QFetchFinancialRecords.FieldByName('Afdeling').AsString;
          lkmCashstatement.kasse := QFetchFinancialRecords.FieldByName('UAfd_Navn').AsString;
          lkmCashstatement.belB := QFetchFinancialRecords.FieldByName('Belob').AsFloat;
          lkmCashstatement.butik := GetButiksID(QFetchFinancialRecords.FieldByName('Afdeling_ID').AsString);
          lkmCashstatement.status := '0';

          lJSONStr := GetDefaultSerializer.SerializeObject(lkmCashstatement);

          INC(lExportCounter);

          // Add to log
          AddToLog(Format('  Financial record to transfer: %d - %s', [lExportCounter, lJSONStr]));
          if OnlyTestRoutine then
          begin
            DoContinue := TRUE;
          end
          else
          begin
            DoContinue := (lBusinessCentral.PostkmCashstatement(lBusinessCentralSetup, lkmCashstatement, lResponse, TRUE, LF_BC_Version));
          end;

          if DoContinue then
          begin
            WriteEksportedRecordToTextfile;
            Result := MarkRecordAsHandled(QFetchFinancialRecords.FieldByName('ID').AsInteger);
          end
          else
          begin
            Result := FALSE;
            lErrotString := 'Der skete en uventet fejl ved indsættelse af finanspost i BC ' + #13#10 +
              '  EP ID: ' + QFetchFinancialRecords.FieldByName('ID').AsString + #13#10 +
              '  Code: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
              '  Message: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10 +
              '  JSON: ' + lJSONStr + #13#10;
            AddToLog(lErrotString);
            INC(lErrorCounter);
            AddToErrorLog(lErrotString, lErrorFileName);
          end;
          FReeAndNil(lResponse);
        finally
          lkmCashstatement.Free;
        end;
      end
      else
      begin
        AddToLog(Format('  Already inserted. Skipping ID %s', [QFetchFinancialRecords.FieldByName('ID').AsString]));
        Result := MarkRecordAsHandled(QFetchFinancialRecords.FieldByName('ID').AsInteger);
      end;
    end
    else
    begin
      // Do not continue. Some error from BC when trying to get a record
      Result := FALSE;
      lErrotString := 'Unexpected error when checking financial record in BC ' + #13#10 +
        '  ID: ' + QFetchFinancialRecords.FieldByName('ID').AsString + #13#10 +
        '  Code: ' + (lGetResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
        '  Message: ' + (lGetResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10 +
        '  JSON: ' + lJSONStr + #13#10;
      AddToLog(lErrotString);
      AddToErrorLog(lErrotString, lErrorFileName);
    end;
    FReeAndNil(lGetResponse);
  end;

begin
  AddToLog('DoSyncronizeFinansCialRecords - BEGIN');
  if (ConnectToDB) then
  begin
    AddToLog('  TBusinessCentralSetup.Create');
    lBusinessCentralSetup := TBusinessCentralSetup.Create(LF_BC_BASEURL,
      LF_BC_PORT_Str,
      LF_BC_COMPANY_URL,
      LF_BC_ACTIVECOMPANYID,
      LF_BC_Environment,
      LF_BC_USERNAME,
      LF_BC_PASSWORD,
      LF_BC_Version);
    try
      AddToLog('  TBusinessCentral.Create');
      lBusinessCentral := TBusinessCentral.Create(LogFileFolder);
      try
        if (NOT(tnMain.Active)) then
          tnMain.StartTransaction;

        lDaysToLookAfterRecords := iniFile.ReadInteger('FinancialRecords', 'Days to look for records', 5);
        lDateAndTimeOfLastRun := iniFile.ReadDateTime('FinancialRecords', 'Last run', NOW - lDaysToLookAfterRecords);
        lFromDateAndTime := lDateAndTimeOfLastRun - lDaysToLookAfterRecords;
        lToDateAndTime := NOW;

        AddToLog(Format('  Fetching records. Period %s to %s', [FormatDateTime('yyyy-mm-dd hh:mm:ss', lFromDateAndTime), FormatDateTime('yyyy-mm-dd hh:mm:ss', lToDateAndTime)]));

        QFetchFinancialRecords.ParamByName('PStartDato').AsDateTime := lFromDateAndTime;
        QFetchFinancialRecords.ParamByName('PSlutDato').AsDateTime := lToDateAndTime;
        QFetchFinancialRecords.SQL.SaveToFile(SQLLogFileFolder + 'FinancialRecords.SQL');
        QFetchFinancialRecords.Open;
        QFetchFinancialRecords.FetchAll;

        AddToLog(Format('  Records fetched: %d', [QFetchFinancialRecords.RecordCount]));

        lExportCounter := 0;
        lErrorCounter := 0;

        if (NOT(QFetchFinancialRecords.EOF)) then
        begin
          // At least 1 record is there - fetch next transactions UD
          BC_TransactionID := FetchNextTransID('financial records');
          RoutineCanceled := FALSE;
          // Iterate through result set
{$IFDEF DEBUG}
          while (NOT(QFetchFinancialRecords.EOF)) AND (NOT(RoutineCanceled)) and (lExportCounter < 5) do
{$ENDIF}
{$IFDEF RELEASE}
            while (NOT(QFetchFinancialRecords.EOF)) AND (NOT(RoutineCanceled)) do
{$ENDIF}
            begin
              RoutineCanceled := NOT CreateAndExportFinancialRecord;
              if NOT RoutineCanceled then
              begin
                // save highest TransID of record
                QFetchFinancialRecords.Next;
              end;
            end;
          AddToLog('  Iteration done');

          if (NOT(RoutineCanceled)) then
          begin
            /// All good
            if NOT OnlyTestRoutine then
            begin
              QFetchFinancialRecords.Close;
              if (tnMain.Active) then
                tnMain.Commit;

              iniFile.WriteDateTime('FinancialRecords', 'Last time sync to BC was tried', NOW);
              iniFile.WriteDateTime('FinancialRecords', 'Last run', lToDateAndTime);
              InsertTracingLog(15, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
            end;
          end
          else
          begin
            // Some error occured. Send an mail to user
            // Send mail with file LogFolder + lErrorName
            // Rename file
            lText := 'Der skete en fejl ved synkronisering af finansposter til Business Central.' + #13#10 +
              'Vedhæftet er en fil med information' + #13#10;
            SendErrorMail(LogFileFolder + lErrorFileName, 'Finansposter', lText);
            // Rename error file
            TFile.Move(LogFileFolder + lErrorFileName, LogFileFolder + Format('Error_Finansposter_%s.txt', [FormatDateTime('ddmmyyyy_hhmmss', NOW)]));
            InsertTracingLog(16, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
          end;

          AddToLog('  Routine done');
        end
        else
        begin
          // NO records selected
          AddToLog('  No records');
        end;

        QFetchFinancialRecords.Close;
        if (tnMain.Active) then
          tnMain.Commit;

      finally
        AddToLog('  TBusinessCentral - Free');
        FReeAndNil(lBusinessCentral);
      end;
    finally
      AddToLog('  TBusinessCentralSetup - Free');
      FReeAndNil(lBusinessCentralSetup);
    end;

    DisconnectFromDB;

  end;
  AddToLog('DoSyncronizeFinansCialRecords - END');
  AddToLog('  ');
end;

procedure TDM.DoSyncronizeItems;
const
  lErrorFileName: String = 'ItemsErrors.txt';
var
  lBusinessCentralSetup: TBusinessCentralSetup;
  lBusinessCentral: TBusinessCentral;
  lDaysToLookAfterRecords: Integer;
  lFromDateAndTime: TDateTime;
  lToDateAndTime: TDateTime;
  lExportCounterHeadItems: Integer;
  lExportCounterHeadItemVariants: Integer;
  lExportCounterVariants: Integer;
  lErrorCounter: Integer;
  lText: string;
  BC_ItemsTransactionID: Integer;
  BC_VariantsTransactionID: Integer;
  lCurrentHeadItem: String;
  lDepartment: string;
  lDateAndTimeOfLastRun: TDateTime;
  ContinueWithVariants: Boolean;

  procedure CreateAndExportItems;
  var
    lkmItem: TkmItem;
    lFloat: Double;
    lResponse: TBusinessCentral_Response;
    lErrorString: string;
    lkmVariantId: TkmVariantId;
    Afbrudt: Boolean;
    lJSONStr: string;
    DoContinue: Boolean;

    Procedure CreateAndInsertHeadItem;
    begin
      // Build head item
      lkmItem := TkmItem.Create;
      try
        lkmItem.transId := BC_ItemsTransactionID;
        lkmItem.vareId := QFetchItems.FieldByName('VareID').AsString;
        lkmItem.beskrivelse := Copy(QFetchItems.FieldByName('Beskrivelse').AsString, 1, 50);
        lkmItem.model := Copy(QFetchItems.FieldByName('Model').AsString, 1, 50);
        lkmItem.kostPris := QFetchItems.FieldByName('KostPris').AsFloat;
        lkmItem.salgspris := QFetchItems.FieldByName('SalgsPris').AsFloat;
        lkmItem.leverandRKode := QFetchItems.FieldByName('LeverandorKode').AsString;
        lkmItem.varegruppe := QFetchItems.FieldByName('Varegruppe').AsString;
        lkmItem.status := '0';
        lkmItem.transDato := FormatDateTime('dd-mm-yyyy', NOW);
        lkmItem.transTid := FormatDateTime('hh:mm:ss', NOW);
        lkmItem.tariffNo := QFetchItems.FieldByName('INTRASTAT').AsString;
        lkmItem.countryRegionOfOriginCode := QFetchItems.FieldByName('Country').AsString;
        lkmItem.Varenavn2 := QFetchItems.FieldByName('Varenavn2').AsString;
        lkmItem.Varenavn3 := QFetchItems.FieldByName('Varenavn3').AsString;
        lkmItem.LeverandRnavn := QFetchItems.FieldByName('leverid').AsString;
        lkmItem.Varegruppenavn := QFetchItems.FieldByName('varegrpid').AsString;
        lkmItem.Farve := '';
        lkmItem.Storrelse := '';
        lkmItem.Laengde := '';
        lkmItem.EANNummer := '';
        lkmItem.Leverandoerensvarenummer := '';
        if TryStrToFloat(QFetchItems.FieldByName('Weigth').AsString, lFloat) then
          lkmItem.netWeight := lFloat
        else
          lkmItem.netWeight := 1;

        // Build JSON string
        lJSONStr := GetDefaultSerializer.SerializeObject(lkmItem);

        // Add to log
        AddToLog(Format('    Head item to transfer: %d - %s', [lExportCounterHeadItems, lJSONStr]));
        if OnlyTestRoutine then
        begin
          DoContinue := TRUE;
        end
        else
        begin
          DoContinue := (lBusinessCentral.PostkmItem(lBusinessCentralSetup, lkmItem, lResponse, LF_BC_Version));
        end;

        if DoContinue then
        begin
          // Inc amount of transferred head items
          INC(lExportCounterHeadItems);
          // No error or test
          ContinueWithVariants := TRUE;
        end
        else
        begin
          AddToLog(Format('    ERROR (more in error file): %s - %s', [
            (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString,
            (lResponse as TBusinessCentral_ErrorResponse).StatusText]));
          // ERROR - Do not continues with variants
          ContinueWithVariants := FALSE;
          // Insert error counter
          INC(lErrorCounter);
          // Build error string
          lErrorString := 'Unexpected error when inserting head item in Business Central. ' + #13#10 +
            '  Head item number: ' + QFetchItems.FieldByName('VareID').AsString + #13#10 +
            '  Code: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
            '  Message: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10;
          // Add to log file.
          AddToErrorLog(lErrorString, lErrorFileName);
        end;
        FReeAndNil(lResponse);
      finally
        lkmItem.Free;
      end;
    end;

    Procedure CreateAndInsertVariantItem;
    begin
      // Build head item
      lkmItem := TkmItem.Create;
      try
        lkmItem.transId := BC_ItemsTransactionID;
        lkmItem.vareId := QFetchItems.FieldByName('VariantID').AsString;
        lkmItem.beskrivelse := Copy(QFetchItems.FieldByName('Beskrivelse').AsString, 1, 50);
        lkmItem.model := Copy(QFetchItems.FieldByName('Model').AsString, 1, 50);
        lkmItem.kostPris := QFetchItems.FieldByName('KostPris').AsFloat;
        lkmItem.salgspris := QFetchItems.FieldByName('SalgsPris').AsFloat;
        lkmItem.leverandRKode := QFetchItems.FieldByName('LeverandorKode').AsString;
        lkmItem.varegruppe := QFetchItems.FieldByName('Varegruppe').AsString;
        lkmItem.status := '0';
        lkmItem.transDato := FormatDateTime('dd-mm-yyyy', NOW);
        lkmItem.transTid := FormatDateTime('hh:mm:ss', NOW);
        lkmItem.tariffNo := QFetchItems.FieldByName('INTRASTAT').AsString;
        lkmItem.countryRegionOfOriginCode := QFetchItems.FieldByName('Country').AsString;
        lkmItem.Varenavn2 := QFetchItems.FieldByName('Varenavn2').AsString;
        lkmItem.Varenavn3 := QFetchItems.FieldByName('Varenavn3').AsString;
        lkmItem.LeverandRnavn := QFetchItems.FieldByName('leverid').AsString;
        lkmItem.Varegruppenavn := QFetchItems.FieldByName('varegrpid').AsString;
        lkmItem.Farve := QFetchItems.FieldByName('Farve').AsString;
        lkmItem.Storrelse := QFetchItems.FieldByName('Storrelse').AsString;
        lkmItem.Laengde := QFetchItems.FieldByName('Laengde').AsString;
        lkmItem.EANNummer := QFetchItems.FieldByName('eannummer').AsString;
        lkmItem.Leverandoerensvarenummer := QFetchItems.FieldByName('levvarenr').AsString;
        if TryStrToFloat(QFetchItems.FieldByName('Weigth').AsString, lFloat) then
          lkmItem.netWeight := lFloat
        else
          lkmItem.netWeight := 1;

        // Build JSON string
        lJSONStr := GetDefaultSerializer.SerializeObject(lkmItem);

        // Add to log
        AddToLog(Format('    Variantitem to transfer: %d - %s', [lExportCounterHeadItemVariants, lJSONStr]));
        if OnlyTestRoutine then
        begin
          DoContinue := TRUE;
        end
        else
        begin
          DoContinue := (lBusinessCentral.PostkmItem(lBusinessCentralSetup, lkmItem, lResponse, LF_BC_Version));
        end;

        if DoContinue then
        begin
          // Inc amount of transferred head item Varinat
          INC(lExportCounterHeadItemVariants);
          // No error or test
          ContinueWithVariants := TRUE;
        end
        else
        begin
          AddToLog(Format('    ERROR (more in error file): %s - %s', [
            (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString,
            (lResponse as TBusinessCentral_ErrorResponse).StatusText]));
          // ERROR - Do not continues with variants
          ContinueWithVariants := FALSE;
          // Insert error counter
          INC(lErrorCounter);
          // Build error string
          lErrorString := 'Unexpected error when inserting head item in Business Central. ' + #13#10 +
            '  Head item number: ' + QFetchItems.FieldByName('VareID').AsString + #13#10 +
            '  Code: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
            '  Message: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10;
          // Add to log file.
          AddToErrorLog(lErrorString, lErrorFileName);
        end;
        FReeAndNil(lResponse);
      finally
        lkmItem.Free;
      end;
    end;

  begin
    if (lCurrentHeadItem <> QFetchItems.FieldByName('VareID').AsString) then
    begin
      (*
        Head item has change (or its the first record)
        We need to insert head item into kmItem
      *)
      // Set current head item
      lCurrentHeadItem := QFetchItems.FieldByName('VareID').AsString;
      // Head item has changed. Do transfer
      AddToLog(Format('  Adding head item %s to Business Central.', [QFetchItems.FieldByName('VareID').AsString]));

      // Insert into kmItem (hovedvare)
      CreateAndInsertHeadItem;

      if (ContinueWithVariants) then
      begin
        // To this head item we can continue and mark head item as done
        if NOT OnlyTestRoutine then
        begin
{$IFNDEF DEBUG}
          AddToLog(Format('    Head item %s marked as exported', [QFetchItems.FieldByName('VareID').AsString]));
          QItemsTemp.SQL.Clear;
          QItemsTemp.SQL.Add('Update Varer set Eksporteret=Eksporteret+1 where Plu_Nr=:PV;');
          QItemsTemp.ParamByName('PV').AsString := QFetchItems.FieldByName('VareID').AsString;
          QItemsTemp.ExecSQL;
          AddToLog(Format('    Handling variants to head item %s', [QFetchItems.FieldByName('VareID').AsString]));
{$ENDIF}
        end;
      end;
    end;

    if (ContinueWithVariants) then
    begin
      (*
        We have a variant - Insert this also in kmItemn (New)
      *)

      // Insert into kmItem (variant)
      CreateAndInsertVariantItem;

      // To this head item we can continue with variants
      Afbrudt := FALSE;

      // Create variant class
      lkmVariantId := TkmVariantId.Create;
      try
        lkmVariantId.transId := BC_VariantsTransactionID;
        lkmVariantId.vareId := QFetchItems.FieldByName('VareID').AsString;
        lkmVariantId.variantId := QFetchItems.FieldByName('VariantID').AsString;
        lkmVariantId.Farve := QFetchItems.FieldByName('Farve').AsString;
        lkmVariantId.stRrelse := QFetchItems.FieldByName('Storrelse').AsString;
        lkmVariantId.lNgde := QFetchItems.FieldByName('Laengde').AsString;
        lkmVariantId.status := '0';
        lkmVariantId.transDato := FormatDateTime('dd-mm-yyyy', NOW);
        lkmVariantId.transTid := FormatDateTime('hh:mm:ss', NOW);

        // Build JSON string
        lJSONStr := GetDefaultSerializer.SerializeObject(lkmVariantId);

        // Add to log
        AddToLog(Format('      Variant to transfer: %d - %s', [lExportCounterVariants, lJSONStr]));
        // POST (INsert den)
        if OnlyTestRoutine then
        begin
          DoContinue := TRUE;
        end
        else
        begin
          DoContinue := (lBusinessCentral.PostkmVariantId(lBusinessCentralSetup, lkmVariantId, lResponse, LF_BC_Version));
        end;

        if DoContinue then
        begin
          // No error
          // Increment exported variants
          INC(lExportCounterVariants);
        end
        else
        begin
          AddToLog(Format('    ERROR (more in error file): %s - %s', [
            (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString,
            (lResponse as TBusinessCentral_ErrorResponse).StatusText]));
          // ERROR
          INC(lErrorCounter);
          // Build errorstring
          lErrorString := 'Unexpected error while inserting variant in Business Central. ' + #13#10 +
            '  Variant: ' + QFetchItems.FieldByName('VariantID').AsString + #13#10 +
            '  Code: ' + IntToStr((lResponse as TBusinessCentral_ErrorResponse).StatusCode) + #13#10 +
            '  Message: ' + #13#10 + (lResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10;
          Afbrudt := TRUE;
          // Add to errorlog
          AddToErrorLog(lErrorString, lErrorFileName);
        end;
        FReeAndNil(lResponse);
      finally
        FReeAndNil(lkmVariantId);
      end;

      if (NOT(Afbrudt)) then
      begin
        if NOT OnlyTestRoutine then
        begin
{$IFNDEF DEBUG}
          AddToLog(Format('      Variant %s marked as exported', [QFetchItems.FieldByName('VariantID').AsString]));
          QItemsTemp.SQL.Clear;
          QItemsTemp.SQL.Add('Update VareFrvStr set Eksporteret=Eksporteret+1 where V509Index=:PV;');
          QItemsTemp.ParamByName('PV').AsString := QFetchItems.FieldByName('VariantID').AsString;
          QItemsTemp.ExecSQL;
{$ENDIF}
        end;
      end;
    end;
  end;

begin
  AddToLog('DoSyncronizeItems - BEGIN');
  try
    if (ConnectToDB) then
    begin
      AddToLog('  TBusinessCentralSetup.Create');
      lBusinessCentralSetup := TBusinessCentralSetup.Create(LF_BC_BASEURL,
        LF_BC_PORT_Str,
        LF_BC_COMPANY_URL,
        LF_BC_ACTIVECOMPANYID,
        LF_BC_Environment,
        LF_BC_USERNAME,
        LF_BC_PASSWORD,
        LF_BC_Version);
      try
        AddToLog(Format('  BC Url: %s', [lBusinessCentralSetup.BuildEntireURL]));
        AddToLog('  TBusinessCentral.Create');
        lBusinessCentral := TBusinessCentral.Create(LogFileFolder);
        try
          if (NOT(tnMain.Active)) then
            tnMain.StartTransaction;

          lDaysToLookAfterRecords := iniFile.ReadInteger('Items', 'Days to look for records', 5);
          lDepartment := iniFile.ReadString('Items', 'Department', '');
          // iniFile.WriteDateTime('Items', 'Last run', NOW - lDaysToLookAfterRecords);
          lDateAndTimeOfLastRun := iniFile.ReadDateTime('Items', 'Last run', NOW - lDaysToLookAfterRecords);
          lFromDateAndTime := lDateAndTimeOfLastRun;
          lToDateAndTime := NOW;

          AddToLog(Format('  Department: %s ', [lDepartment]));
          AddToLog(Format('  Fetching Items. Period %s to %s', [FormatDateTime('yyyy-mm-dd hh:mm:ss', lFromDateAndTime), FormatDateTime('yyyy-mm-dd hh:mm:ss', lToDateAndTime)]));

          QFetchItems.SQL.Clear;
{$IFDEF RELEASE}
          QFetchItems.SQL.Add(
            'SELECT DISTINCT ' + #13#10 +
            '    /*Hoved varenummer*/ ' + #13#10 +
            '    t.VAREFRVSTRNR AS VareID, ' + #13#10 +
            '    /*Barcode*/ ' + #13#10 +
            '    vv.V509INDEX AS VariantID, ' + #13#10 +
            '    /*Color*/ ' + #13#10 +
            '    vv.FARVE_NAVN AS Farve, ' + #13#10 +
            '    /*Size*/ ' + #13#10 +
            '    vv.STOERRELSE_NAVN AS Storrelse, ' + #13#10 +
            '    /*Length*/ ' + #13#10 +
            '    vv.LAENGDE_NAVN AS Laengde, ' + #13#10 +
            '    /*EANNumber*/ ' + #13#10 +
            '    vv.eannummer, ' + #13#10 +
            '    /*Suppliers item numbmer*/ ' + #13#10 +
            '    vv.levvarenr, ' + #13#10 +
            '    /*Items description*/ ' + #13#10 +
            '    v.VARENAVN1 AS Beskrivelse, ' + #13#10 +
            '    /*Description 2*/ ' + #13#10 +
            '    v.VARENAVN2, ' + #13#10 +
            '    /*Description 3*/ ' + #13#10 +
            '    v.VARENAVN3, ' + #13#10 +
            '    /*Style*/ ' + #13#10 +
            '    v.MODEL AS Model, ' + #13#10 +
            '    /*Brand short number*/ ' + #13#10 +
            '    l.V509INDEX AS LeverandorKode, ' + #13#10 +
            '    /*Brand*/ ' + #13#10 +
            '    v.leverid, ' + #13#10 +
            '    /*Group short number*/ ' + #13#10 +
            '    vg.V509INDEX AS Varegruppe, ' + #13#10 +
            '    /*Group*/ ' + #13#10 +
            '    v.varegrpid, ' + #13#10 +
            '    /*Country*/ ' + #13#10 +
            '    v.KATEGORI1 AS Country, ' + #13#10 +
            '    /*Weigth*/ ' + #13#10 +
            '    v.KATEGORI2 AS Weigth, ' + #13#10 +
            '    /*IntraStat value*/ ' + #13#10 +
            '    v.INTRASTAT, ' + #13#10 +
            '    /*Cost price from selected department*/ ' + #13#10 +
            '    (SELECT ' + #13#10 +
            '         vfsd.VEJETKOSTPRISSTK ' + #13#10 +
            '     FROM VareFrvStr_Detail vfsd ' + #13#10 +
            '     WHERE ' + #13#10 +
            '         vfsd.VAREPLU_ID = t.VAREFRVSTRNR AND ' + #13#10 +
            '         vfsd.FARVE_NAVN = t.FARVE_NAVN AND ' + #13#10 +
            '         vfsd.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND ' + #13#10 +
            '         vfsd.LAENGDE_NAVN = t.LAENGDE_NAVN AND ' + #13#10 +
            '         vfsd.afdeling_ID = :PAfdeling_ID) AS Kostpris, ' + #13#10 +
            '    /*Sale price from selected department*/ ' + #13#10 +
            '    (SELECT ' + #13#10 +
            '         vfsd.SALGSPRISSTK ' + #13#10 +
            '     FROM VareFrvStr_Detail vfsd ' + #13#10 +
            '     WHERE ' + #13#10 +
            '         vfsd.VAREPLU_ID = t.VAREFRVSTRNR AND ' + #13#10 +
            '         vfsd.FARVE_NAVN = t.FARVE_NAVN AND ' + #13#10 +
            '         vfsd.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND ' + #13#10 +
            '         vfsd.LAENGDE_NAVN = t.LAENGDE_NAVN AND ' + #13#10 +
            '         vfsd.afdeling_ID = :PAfdeling_ID) AS Salgspris ' + #13#10 +
            'FROM transaktioner t ' + #13#10 +
            '    INNER JOIN Varer v ON (V.PLU_NR = t.VAREFRVSTRNR) ' + #13#10 +
            '    INNER JOIN VareFrvStr vv ON (vv.VAREPLU_ID = t.VAREFRVSTRNR AND ' + #13#10 +
            '          vv.FARVE_NAVN = t.FARVE_NAVN AND ' + #13#10 +
            '          vv.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND ' + #13#10 +
            '          vv.LAENGDE_NAVN = t.LAENGDE_NAVN) ' + #13#10 +
            '    INNER JOIN leverandoerer l ON (l.NAVN = t.LEVNAVN) ' + #13#10 +
            '    INNER JOIN varegrupper vg ON (vg.NAVN = t.VAREGRPID) ' + #13#10 +
            'WHERE ' + #13#10 +
            '    t.dato >= :PStartDato AND ' + #13#10 +
            '    t.dato <= :PSlutDato AND ' + #13#10 +
            '    t.ART IN (0, 1, 11, 14) ' + #13#10 +
            'ORDER BY ' + #13#10 +
            '    /*Hoved varenummer*/ ' + #13#10 +
            '    t.VAREFRVSTRNR, ' + #13#10 +
            '    /*Barcode*/ ' + #13#10 +
            '    vv.V509INDEX '
            );
          // QFetchItems.SQL.Add(
          // 'SELECT DISTINCT ' +
          // '    v.VARENAVN1 AS Beskrivelse, ' + #13#10 +
          // '    vfsd.VEJETKOSTPRISSTK AS Kostpris, ' + #13#10 +
          // '    l.V509INDEX AS LeverandorKode, ' + #13#10 +
          // '    t.VAREFRVSTRNR AS VareID, ' + #13#10 +
          // '    v.MODEL AS Model, ' + #13#10 +
          // '    vg.V509INDEX AS Varegruppe, ' + #13#10 +
          // '    vfsd.SALGSPRISSTK AS Salgspris, ' + #13#10 +
          // '    vv.FARVE_NAVN AS Farve, ' + #13#10 +
          // '    vv.STOERRELSE_NAVN AS Storrelse, ' + #13#10 +
          // '    vv.LAENGDE_NAVN AS Laengde, ' + #13#10 +
          // '    vv.V509INDEX AS VariantID, ' + #13#10 +
          // '    v.KATEGORI1 AS Country, ' + #13#10 +
          // '    v.KATEGORI2 AS Weigth, ' + #13#10 +
          // '    v.INTRASTAT ' + #13#10 +
          // 'FROM transaktioner t ' + #13#10 +
          // '    INNER JOIN Varer v ON (V.PLU_NR = t.VAREFRVSTRNR) ' + #13#10 +
          // '    INNER JOIN VareFrvStr_Detail vfsd ON (vfsd.VAREPLU_ID = t.VAREFRVSTRNR AND ' + #13#10 +
          // '          vfsd.FARVE_NAVN = t.FARVE_NAVN AND ' + #13#10 +
          // '          vfsd.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND ' + #13#10 +
          // '          vfsd.LAENGDE_NAVN = t.LAENGDE_NAVN AND ' + #13#10 +
          // '          vfsd.afdeling_ID = :PAfdeling_ID) ' + #13#10 +
          // '    INNER JOIN VareFrvStr vv ON (vv.VAREPLU_ID = t.VAREFRVSTRNR AND ' + #13#10 +
          // '          vv.FARVE_NAVN = t.FARVE_NAVN AND ' + #13#10 +
          // '          vv.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND ' + #13#10 +
          // '          vv.LAENGDE_NAVN = t.LAENGDE_NAVN AND ' + #13#10 +
          // '          vv.EKSPORTERET = 0) ' + #13#10 +
          // '    INNER JOIN leverandoerer l ON (l.NAVN = t.LEVNAVN) ' + #13#10 +
          // '    INNER JOIN varegrupper vg ON (vg.NAVN = t.VAREGRPID) ' + #13#10 +
          // 'WHERE ' + #13#10 +
          // '    t.dato >= :PStartDato AND ' + #13#10 +
          // '    t.dato <= :PSlutDato AND ' + #13#10 +
          // '    t.ART IN (0, 1, 11, 14) ' + #13#10 +
          // 'ORDER BY ' + #13#10 +
          // '    4, ' + #13#10 +
          // '    11 '
          // );
{$ENDIF}
{$IFDEF DEBUG}
          (*
            Here we will fetch all items which has ben sold, regulated or moved within a given date interval.
            We will fetch cost- and sales prices from a department selected by user

            This will not take into account if item has been exported.
            It will just export items touched regarding stock.

            We will also need to select items which has been touch in any other way (edited fields of importance)
          *)
          QFetchItems.SQL.Add(
            'SELECT DISTINCT ' + #13#10 +
            '    /*Hoved varenummer*/ ' + #13#10 +
            '    t.VAREFRVSTRNR AS VareID, ' + #13#10 +
            '    /*Barcode*/ ' + #13#10 +
            '    vv.V509INDEX AS VariantID, ' + #13#10 +
            '    /*Color*/ ' + #13#10 +
            '    vv.FARVE_NAVN AS Farve, ' + #13#10 +
            '    /*Size*/ ' + #13#10 +
            '    vv.STOERRELSE_NAVN AS Storrelse, ' + #13#10 +
            '    /*Length*/ ' + #13#10 +
            '    vv.LAENGDE_NAVN AS Laengde, ' + #13#10 +
            '    /*EANNumber*/ ' + #13#10 +
            '    vv.eannummer, ' + #13#10 +
            '    /*Suppliers item numbmer*/ ' + #13#10 +
            '    vv.levvarenr, ' + #13#10 +
            '    /*Items description*/ ' + #13#10 +
            '    v.VARENAVN1 AS Beskrivelse, ' + #13#10 +
            '    /*Description 2*/ ' + #13#10 +
            '    v.VARENAVN2, ' + #13#10 +
            '    /*Description 3*/ ' + #13#10 +
            '    v.VARENAVN3, ' + #13#10 +
            '    /*Style*/ ' + #13#10 +
            '    v.MODEL AS Model, ' + #13#10 +
            '    /*Brand short number*/ ' + #13#10 +
            '    l.V509INDEX AS LeverandorKode, ' + #13#10 +
            '    /*Brand*/ ' + #13#10 +
            '    v.leverid, ' + #13#10 +
            '    /*Group short number*/ ' + #13#10 +
            '    vg.V509INDEX AS Varegruppe, ' + #13#10 +
            '    /*Group*/ ' + #13#10 +
            '    v.varegrpid, ' + #13#10 +
            '    /*Country*/ ' + #13#10 +
            '    v.KATEGORI1 AS Country, ' + #13#10 +
            '    /*Weigth*/ ' + #13#10 +
            '    v.KATEGORI2 AS Weigth, ' + #13#10 +
            '    /*IntraStat value*/ ' + #13#10 +
            '    v.INTRASTAT, ' + #13#10 +
            '    /*Cost price from selected department*/ ' + #13#10 +
            '    (SELECT ' + #13#10 +
            '         vfsd.VEJETKOSTPRISSTK ' + #13#10 +
            '     FROM VareFrvStr_Detail vfsd ' + #13#10 +
            '     WHERE ' + #13#10 +
            '         vfsd.VAREPLU_ID = t.VAREFRVSTRNR AND ' + #13#10 +
            '         vfsd.FARVE_NAVN = t.FARVE_NAVN AND ' + #13#10 +
            '         vfsd.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND ' + #13#10 +
            '         vfsd.LAENGDE_NAVN = t.LAENGDE_NAVN AND ' + #13#10 +
            '         vfsd.afdeling_ID = :PAfdeling_ID) AS Kostpris, ' + #13#10 +
            '    /*Sale price from selected department*/ ' + #13#10 +
            '    (SELECT ' + #13#10 +
            '         vfsd.SALGSPRISSTK ' + #13#10 +
            '     FROM VareFrvStr_Detail vfsd ' + #13#10 +
            '     WHERE ' + #13#10 +
            '         vfsd.VAREPLU_ID = t.VAREFRVSTRNR AND ' + #13#10 +
            '         vfsd.FARVE_NAVN = t.FARVE_NAVN AND ' + #13#10 +
            '         vfsd.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND ' + #13#10 +
            '         vfsd.LAENGDE_NAVN = t.LAENGDE_NAVN AND ' + #13#10 +
            '         vfsd.afdeling_ID = :PAfdeling_ID) AS Salgspris ' + #13#10 +
            'FROM transaktioner t ' + #13#10 +
            '    INNER JOIN Varer v ON (V.PLU_NR = t.VAREFRVSTRNR) ' + #13#10 +
            '    INNER JOIN VareFrvStr vv ON (vv.VAREPLU_ID = t.VAREFRVSTRNR AND ' + #13#10 +
            '          vv.FARVE_NAVN = t.FARVE_NAVN AND ' + #13#10 +
            '          vv.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND ' + #13#10 +
            '          vv.LAENGDE_NAVN = t.LAENGDE_NAVN) ' + #13#10 +
            '    INNER JOIN leverandoerer l ON (l.NAVN = t.LEVNAVN) ' + #13#10 +
            '    INNER JOIN varegrupper vg ON (vg.NAVN = t.VAREGRPID) ' + #13#10 +
            'WHERE ' + #13#10 +
            '    t.dato >= :PStartDato AND ' + #13#10 +
            '    t.dato <= :PSlutDato AND ' + #13#10 +
            '    t.ART IN (0, 1, 11, 14) ' + #13#10 +
            'ORDER BY ' + #13#10 +
            '    /*Hoved varenummer*/ ' + #13#10 +
            '    t.VAREFRVSTRNR, ' + #13#10 +
            '    /*Barcode*/ ' + #13#10 +
            '    vv.V509INDEX '
            );
          lToDateAndTime := NOW;
{$ENDIF}
          QFetchItems.ParamByName('PStartDato').AsDateTime := lFromDateAndTime;
          QFetchItems.ParamByName('PSlutDato').AsDateTime := lToDateAndTime;
          QFetchItems.ParamByName('PAfdeling_ID').AsString := lDepartment;
          // {$IFDEF DEBUG}
          // QFetchItems.ParamByName('PLever').AsString := 'ALLAN&CLARK';
          // {$ENDIF}
          QFetchItems.SQL.SaveToFile(SQLLogFileFolder + 'Items.SQL');
          QFetchItems.Open;
          QFetchItems.FetchAll;

          AddToLog(Format('  Items fetched: %d', [QFetchItems.RecordCount]));

          lExportCounterHeadItems := 0;
          lExportCounterHeadItemVariants := 0;
          lExportCounterVariants := 0;
          lErrorCounter := 0;
          lCurrentHeadItem := '';
          ContinueWithVariants := TRUE;

          if (NOT(QFetchItems.EOF)) then
          begin
            // At least 1 record is there - fetch next transactions UD
            BC_ItemsTransactionID := FetchNextTransID('head items');
            BC_VariantsTransactionID := FetchNextTransID('variants');
            // Iterate through result set
            while (NOT(QFetchItems.EOF)) do
            begin
              CreateAndExportItems;
              QFetchItems.Next;
            end;
            AddToLog('  Iteration done');
            AddToLog(Format('  Exported %d head items, %d head item variants and %d variants', [lExportCounterHeadItems, lExportCounterHeadItemVariants, lExportCounterVariants]));
            AddToLog('  Routine done');
            iniFile.WriteDateTime('Items', 'Last time sync to BC was tried', NOW);
            if lErrorCounter = 0 then
            begin
              // Only save time if there is no errors
              iniFile.WriteDateTime('Items', 'Last run', lToDateAndTime);
            end;
          end
          else
          begin
            // NO records selected
            AddToLog('  No records');
          end;

          QFetchItems.Close;
          if (tnMain.Active) then
            tnMain.Commit;

          if (lErrorCounter > 0) then
          begin
            // Some error occured. Send an mail to user
            // Send mail with file LogFolder + lErrorName
            // Rename file
            lText := 'Der skete en fejl ved synkronisering af varer til Business Central.' + #13#10 +
              'Vedhæftet er en fil med information' + #13#10;
            SendErrorMail(LogFileFolder + lErrorFileName, 'Varer', lText);
            // Rename error file
            TFile.Move(LogFileFolder + lErrorFileName, LogFileFolder + Format('Error_Varer_%s.txt', [FormatDateTime('ddmmyyyy_hhmmss', NOW)]));
            InsertTracingLog(2, lFromDateAndTime, lToDateAndTime, BC_ItemsTransactionID);
          end
          else
          begin
            // save last time items was checked
            iniFile.WriteDateTime('Items', 'Last run', lToDateAndTime);
            InsertTracingLog(1, lFromDateAndTime, lToDateAndTime, BC_ItemsTransactionID);
          end;
        finally
          AddToLog('  TBusinessCentral - Free');
          FReeAndNil(lBusinessCentral);
        end;
      finally
        AddToLog('  TBusinessCentralSetup - Free');
        FReeAndNil(lBusinessCentralSetup);
      end;

      DisconnectFromDB;
    end;
  except
    on E: Exception do
    begin
      AddToLog(Format('DoSyncronizeItems - ERROR. %s', [E.Message]));
      if (tnMain.Active) then
        tnMain.Rollback;
    end;
  end;
  AddToLog('DoSyncronizeItems - END');
  AddToLog('  ');
end;

procedure TDM.DoSyncronizeSalesTransactions;
const
  lSalesTransactionErrorFileName: String = 'SalestransactionErrors.txt';
var
  lBusinessCentralSetup: TBusinessCentralSetup;
  lBusinessCentral: TBusinessCentral;
  lDaysToLookAfterRecords: Integer;
  lDateAndTimeOfLastRun: TDateTime;
  lFromDateAndTime: TDateTime;
  lToDateAndTime: TDateTime;
  lNumberOfExportedSalesTransactions: Integer;
  BC_TransactionID: Integer;
  RoutineCanceled: Boolean;
  lText: string;

  Function CreateAndExportSalesTransaction: Boolean;
  var
    lkmItemSale: TkmItemSale;
    lResponse: TBusinessCentral_Response;
    lJSONStr: string;
    DoContinue: Boolean;
    lErrotString: string;
    DoContinueWithInsert: Boolean;
    lGetResponse: TBusinessCentral_Response;

    function DoMarkSalesTransactionsAsExported: Boolean;
    begin
      if NOT OnlyTestRoutine then
      begin
{$IFDEF RELEASE}
        try
          if NOT trSetEksportedValueOnSaleTrans.Active then
          begin
            trSetEksportedValueOnSaleTrans.StartTransaction;
          end;
          QSetEksportedValueOnSaleTrans.SQL.Clear;
          QSetEksportedValueOnSaleTrans.SQL.Add('Update Transaktioner set ');
          QSetEksportedValueOnSaleTrans.SQL.Add('  Eksporteret = :PEksporteret ');
          QSetEksportedValueOnSaleTrans.SQL.Add('where ');
          QSetEksportedValueOnSaleTrans.SQL.Add('  art IN (0,1) AND');
          QSetEksportedValueOnSaleTrans.SQL.Add('  TransID = :PTransID AND');
          QSetEksportedValueOnSaleTrans.SQL.Add('  (EKSPORTERET>=0 or EKSPORTERET IS null) ');
          QSetEksportedValueOnSaleTrans.ParamByName('PEksporteret').AsInteger := QFetchSalesTransactions.FieldByName('Eksporteret').AsInteger + 1;
          QSetEksportedValueOnSaleTrans.ParamByName('PTransID').AsInteger := QFetchSalesTransactions.FieldByName('EPID').AsInteger;
          QSetEksportedValueOnSaleTrans.ExecSQL;
          if trSetEksportedValueOnSaleTrans.Active then
          begin
            trSetEksportedValueOnSaleTrans.Commit;
          end;
          Result := TRUE;
        except
          On E: Exception do
          begin
            Result := FALSE;
            lErrotString := 'Unexpected error when marking sale transaction exported in EasyPOS ' + #13#10 +
              '  EP ID: ' + QFetchSalesTransactions.FieldByName('EPID').AsString + #13#10 +
              '  Message: ' + E.Message;
            AddToLog(lErrotString);
            AddToErrorLog(lErrotString, lSalesTransactionErrorFileName);
          end;
        end;
{$ENDIF}
{$IFDEF DEBUG}
        Result := TRUE;
{$ENDIF}
      end
      else
      begin
        Result := TRUE;
      end;
    end;

  begin
    AddToLog(Format('  Checking epid %s in Business Central', [QFetchSalesTransactions.FieldByName('EpID').AsString]));
    lBusinessCentralSetup.FilterValue := Format('epId eq %s', [QFetchSalesTransactions.FieldByName('EpID').AsString]);
    // Mine order værdier.-
    lBusinessCentralSetup.OrderValue := '';
    // Select fields
    lBusinessCentralSetup.SelectValue := '';
    // Hent dem.
    DoContinueWithInsert := lBusinessCentral.GetkmItemSales(lBusinessCentralSetup, lGetResponse, LF_BC_Version);

    if DoContinueWithInsert then
    begin
      if (lGetResponse as TkmItemSales).Value.Count = 0 then
      begin
        lkmItemSale := TkmItemSale.Create;
        try
          lkmItemSale.transId := BC_TransactionID;
          lkmItemSale.epId := QFetchSalesTransactions.FieldByName('EpID').AsInteger;
          lkmItemSale.bonNummer := QFetchSalesTransactions.FieldByName('Bonnummer').AsInteger;
          lkmItemSale.vareId := QFetchSalesTransactions.FieldByName('VareID').AsString;
          lkmItemSale.variantId := QFetchSalesTransactions.FieldByName('VariantID').AsString;
          lkmItemSale.bogfRingsDato := FormatDateTime('dd-mm-yyyy', QFetchSalesTransactions.FieldByName('BOGFORINGSDATO').AsDateTime);
          lkmItemSale.salgstidspunkt := FormatDateTime('hh:mm:ss', QFetchSalesTransactions.FieldByName('BOGFORINGSDATO').AsDateTime);
          lkmItemSale.antal := QFetchSalesTransactions.FieldByName('Antal').AsFloat;
          if (QFetchSalesTransactions.FieldByName('Antal').AsFloat <> 0) then
          begin
            lkmItemSale.momsbelB := QFetchSalesTransactions.FieldByName('MomsBelob').AsFloat / QFetchSalesTransactions.FieldByName('Antal').AsFloat;
            lkmItemSale.salgspris := QFetchSalesTransactions.FieldByName('Salgspris').AsFloat / QFetchSalesTransactions.FieldByName('Antal').AsFloat;
            lkmItemSale.kostPris := QFetchSalesTransactions.FieldByName('KostPris').AsFloat / QFetchSalesTransactions.FieldByName('Antal').AsFloat;
          end
          else
          begin
            lkmItemSale.momsbelB := 0;
            lkmItemSale.salgspris := 0;
            lkmItemSale.kostPris := 0;
          end;
          lkmItemSale.gaveKortId := '0';
          lkmItemSale.kasse := QFetchSalesTransactions.FieldByName('Kasse').AsString;
          lkmItemSale.butikId := QFetchSalesTransactions.FieldByName('ButikID').AsString;
          lkmItemSale.lagerStatus := 'Ubehandlet';
          lkmItemSale.finansStatus := 'Ubehandlet';
          lkmItemSale.transDato := FormatDateTime('dd-mm-yyyy', NOW);
          lkmItemSale.transTid := FormatDateTime('hh:mm:ss', NOW);

          lJSONStr := GetDefaultSerializer.SerializeObject(lkmItemSale);

          INC(lNumberOfExportedSalesTransactions);

          // Add to log
          AddToLog(Format('  Sale transaction record to transfer: %d - %s', [lNumberOfExportedSalesTransactions, lJSONStr]));
          if OnlyTestRoutine then
          begin
            DoContinue := TRUE;
          end
          else
          begin
            DoContinue := (lBusinessCentral.PostkmItemSale(lBusinessCentralSetup, lkmItemSale, lResponse, LF_BC_Version));
          end;

          if DoContinue then
          begin
            Result := DoMarkSalesTransactionsAsExported;
          end
          else
          begin
            Result := FALSE;

            lErrotString := 'Unexpected error when inserting sale transaction in BC ' + #13#10 +
              '  EP ID: ' + QFetchSalesTransactions.FieldByName('EPID').AsString + #13#10 +
              '  Code: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
              '  Message: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10 +
              '  JSON: ' + lJSONStr + #13#10;
            AddToLog(lErrotString);
            AddToErrorLog(lErrotString, lSalesTransactionErrorFileName);
          end;

          FReeAndNil(lResponse);
        finally
          FReeAndNil(lkmItemSale);
        end;
      end
      else
      begin
        AddToLog(Format('  Already inserted. Skipping epId %s', [QFetchSalesTransactions.FieldByName('EpID').AsString]));
        Result := DoMarkSalesTransactionsAsExported;
      end;
    end
    else
    begin
      // Do not continue. Some error from BC when trying to get a record
      Result := FALSE;
      lErrotString := 'Unexpected error when checking sale transaction in BC ' + #13#10 +
        '  EP ID: ' + QFetchSalesTransactions.FieldByName('EPID').AsString + #13#10 +
        '  Code: ' + (lGetResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
        '  Message: ' + (lGetResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10 +
        '  JSON: ' + lJSONStr + #13#10;
      AddToLog(lErrotString);
      AddToErrorLog(lErrotString, lSalesTransactionErrorFileName);
    end;
    FReeAndNil(lGetResponse);
  end;

begin
  AddToLog('DoSyncronizeSalesTransactions - BEGIN');
  if (ConnectToDB) then
  begin
    AddToLog('  TBusinessCentralSetup.Create');
    lBusinessCentralSetup := TBusinessCentralSetup.Create(LF_BC_BASEURL,
      LF_BC_PORT_Str,
      LF_BC_COMPANY_URL,
      LF_BC_ACTIVECOMPANYID,
      LF_BC_Environment,
      LF_BC_USERNAME,
      LF_BC_PASSWORD,
      LF_BC_Version);
    try
      AddToLog('  TBusinessCentral.Create');
      lBusinessCentral := TBusinessCentral.Create(LogFileFolder);
      try
        if (NOT(tnMain.Active)) then
          tnMain.StartTransaction;

        // Date of last run
        lDaysToLookAfterRecords := iniFile.ReadInteger('SalesTransaction', 'Days to look for records', 5);
        lDateAndTimeOfLastRun := iniFile.ReadDateTime('SalesTransaction', 'Last run', NOW - lDaysToLookAfterRecords);
        lFromDateAndTime := lDateAndTimeOfLastRun;
        // Date until now
        lToDateAndTime := NOW;

        // Log
        AddToLog(Format('  Fetching sales transactions. Period %s to %s', [FormatDateTime('yyyy-mm-dd hh:mm:ss', lFromDateAndTime),
          FormatDateTime('yyyy-mm-dd hh:mm:ss', lToDateAndTime)]));

        // Fetch sales transactions.
        QFetchSalesTransactions.ParamByName('PFromDate').AsDateTime := lFromDateAndTime;
        QFetchSalesTransactions.ParamByName('PToDate').AsDateTime := lToDateAndTime;
        QFetchSalesTransactions.SQL.SaveToFile(SQLLogFileFolder + 'SalesTransactions.SQL');
        QFetchSalesTransactions.Open;

        // Log
        AddToLog(Format('  Query opened', []));

        if QFetchSalesTransactions.RecordCount > 0 then
        begin
          // At least 1 record is there - fetch next transactions UD
          BC_TransactionID := FetchNextTransID('sales transations');
          lNumberOfExportedSalesTransactions := 0;
          RoutineCanceled := FALSE;
          While (Not(QFetchSalesTransactions.EOF)) AND (NOT(RoutineCanceled)) do
          begin
            RoutineCanceled := NOT CreateAndExportSalesTransaction;
            if NOT RoutineCanceled then
            begin
              // save highest TransID of record
              QFetchSalesTransactions.Next;
            end;
          end;
          AddToLog('  Iteration done');

          if (NOT(RoutineCanceled)) then
          begin
            /// All good
            if NOT OnlyTestRoutine then
            begin
              if (tnMain.Active) then
                tnMain.Commit;

              iniFile.WriteDateTime('SalesTransaction', 'Last run', lToDateAndTime);
              InsertTracingLog(5, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
            end;
          end
          else
          begin
            // Some error
            lText := 'Der skete en fejl ved synkronisering af salgstransaktioner til Business Central.' + #13#10 +
              'Vedhæftet er en fil med information' + #13#10;
            SendErrorMail(LogFileFolder + lSalesTransactionErrorFileName, 'Salgstransaktioner', lText);
            // Rename error file
            TFile.Move(LogFileFolder + lSalesTransactionErrorFileName, LogFileFolder + Format('Error_Salgstransaktioner_%s.txt', [FormatDateTime('ddmmyyyy_hhmmss', NOW)]));
            if (tnMain.Active) then
              tnMain.Rollback;
            AddToLog('  Export of sales transaction ended with errors.');
            InsertTracingLog(6, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
          end;
          iniFile.WriteDateTime('SalesTransaction', 'Last time sync to BC was tried', NOW);
          AddToLog('  Routine done');
        end
        else
        begin
          if (tnMain.Active) then
            tnMain.Commit;
          AddToLog(Format('  No sales transactions to export', []));
        end;
      finally
        AddToLog('  TBusinessCentral - Free');
        FReeAndNil(lBusinessCentral);
      end;
    finally
      AddToLog('  TBusinessCentralSetup - Free');
      FReeAndNil(lBusinessCentralSetup);
    end;

    DisconnectFromDB;
  end;
  AddToLog('DoSyncronizeSalesTransactions - END');
end;

procedure TDM.DoSyncronizeMovemmentsTransaction;
const
  lMovementsTransactionErrorFileName: String = 'MovementstransactionErrors.txt';
var
  lBusinessCentralSetup: TBusinessCentralSetup;
  lBusinessCentral: TBusinessCentral;
  lDaysToLookAfterRecords: Integer;
  lDateAndTimeOfLastRun: Extended;
  lFromDateAndTime: Extended;
  lToDateAndTime: Extended;
  BC_TransactionID: Integer;
  lNumberOfExportedMovementsTransactions: Integer;
  RoutineCanceled: Boolean;
  lResponse: TBusinessCentral_Response;
  lText: string;

  Function CreateAndExportMovementsTransaction: Boolean;
  var
    lkmItemMove: TkmItemMove;
    lJSONStr: string;
    DoContinue: Boolean;
    lErrotString: string;
    DoContinueWithInsert: Boolean;
    lGetResponse: TBusinessCentral_Response;

    function DoMarkMovementTransactionsAsExported: Boolean;
    begin
      if NOT OnlyTestRoutine then
      begin
{$IFDEF RELEASE}
        try
          if NOT trSetEksportedValueOnMovementsTrans.Active then
          begin
            trSetEksportedValueOnMovementsTrans.StartTransaction;
          end;
          QSetEksportedValueOnMovementsTrans.SQL.Clear;
          QSetEksportedValueOnMovementsTrans.SQL.Add('Update Transaktioner set ');
          QSetEksportedValueOnMovementsTrans.SQL.Add('  Eksporteret = :PEksporteret ');
          QSetEksportedValueOnMovementsTrans.SQL.Add('where ');
          QSetEksportedValueOnMovementsTrans.SQL.Add('  art IN (14) AND');
          QSetEksportedValueOnMovementsTrans.SQL.Add('  TransID = :PTransID AND');
          QSetEksportedValueOnMovementsTrans.SQL.Add('  (EKSPORTERET>=0 or EKSPORTERET IS null) ');
          QSetEksportedValueOnMovementsTrans.ParamByName('PEksporteret').AsInteger := QFetchMovementsTransactions.FieldByName('Eksporteret').AsInteger + 1;
          QSetEksportedValueOnMovementsTrans.ParamByName('PTransID').AsInteger := QFetchMovementsTransactions.FieldByName('EPID').AsInteger;
          QSetEksportedValueOnMovementsTrans.ExecSQL;
          if trSetEksportedValueOnMovementsTrans.Active then
          begin
            trSetEksportedValueOnMovementsTrans.Commit;
          end;
          Result := TRUE;
        except
          On E: Exception do
          begin
            Result := FALSE;
            lErrotString := 'Unexpected error when marking movement transaction exported in EasyPOS ' + #13#10 +
              '  EP ID: ' + QFetchMovementsTransactions.FieldByName('EPID').AsString + #13#10 +
              '  Message: ' + E.Message;
            AddToLog(lErrotString);
            AddToErrorLog(lErrotString, lMovementsTransactionErrorFileName);
          end;
        end;
{$ENDIF}
{$IFDEF DEBUG}
        Result := TRUE;
{$ENDIF}
      end
      else
      begin
        Result := TRUE;
      end;
    end;

  begin
    AddToLog(Format('  Checking epid %s in Business Central', [QFetchMovementsTransactions.FieldByName('EpID').AsString]));
    lBusinessCentralSetup.FilterValue := Format('epid eq %s', [QFetchMovementsTransactions.FieldByName('EpID').AsString]);
    // Mine order værdier.-
    lBusinessCentralSetup.OrderValue := '';
    // Select fields
    lBusinessCentralSetup.SelectValue := '';
    // Hent dem.
    DoContinueWithInsert := lBusinessCentral.GetkmItemMoves(lBusinessCentralSetup, lGetResponse, LF_BC_Version);

    if DoContinueWithInsert then
    begin
      if (lGetResponse as TkmItemMoves).Value.Count = 0 then
      begin
        lkmItemMove := TkmItemMove.Create;
        try
          lkmItemMove.transId := BC_TransactionID;
          lkmItemMove.flytningsId := QFetchMovementsTransactions.FieldByName('FlytningsID').AsString;
          lkmItemMove.vareId := QFetchMovementsTransactions.FieldByName('VareID').AsString;
          lkmItemMove.variantId := QFetchMovementsTransactions.FieldByName('VariantID').AsString;
          lkmItemMove.epId := QFetchMovementsTransactions.FieldByName('EPID').AsInteger;
          lkmItemMove.bogfRingsDato := FormatDateTime('dd-mm-yyyy', QFetchMovementsTransactions.FieldByName('BOGFORINGSDATO').AsDateTime);
          lkmItemMove.fraButik := QFetchMovementsTransactions.FieldByName('FraButik').AsString;
          lkmItemMove.tilButik := QFetchMovementsTransactions.FieldByName('TilButik').AsString;
          lkmItemMove.antal := QFetchMovementsTransactions.FieldByName('Antal').AsFloat;
          if (QFetchMovementsTransactions.FieldByName('Antal').AsFloat <> 0) then
          begin
            lkmItemMove.kostPris := QFetchMovementsTransactions.FieldByName('KostPris').AsFloat / QFetchMovementsTransactions.FieldByName('Antal').AsFloat;
          end
          else
          begin
            lkmItemMove.kostPris := 0;
          end;
          lkmItemMove.status := '0';
          lkmItemMove.transDato := FormatDateTime('dd-mm-yyyy', NOW);
          lkmItemMove.transTid := FormatDateTime('hh:mm:ss', NOW);

          lJSONStr := GetDefaultSerializer.SerializeObject(lkmItemMove);

          INC(lNumberOfExportedMovementsTransactions);
          // Add to log
          AddToLog(Format('  Movement transaction record to transfer: %d - %s', [lNumberOfExportedMovementsTransactions, lJSONStr]));
          if OnlyTestRoutine then
          begin
            DoContinue := TRUE;
          end
          else
          begin
            DoContinue := (lBusinessCentral.PostkmItemMove(lBusinessCentralSetup, lkmItemMove, lResponse, LF_BC_Version));
          end;

          if DoContinue then
          begin
            Result := DoMarkMovementTransactionsAsExported;
          end
          else
          begin
            Result := FALSE;

            lErrotString := 'Unexpected error when inserting movement transaction in BC ' + #13#10 +
              '  EP TransID: ' + QFetchMovementsTransactions.FieldByName('FlytningsID').AsString + #13#10 +
              '  Code: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
              '  Message: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10 +
              '  JSON: ' + lJSONStr + #13#10;
            AddToLog(lErrotString);
            AddToErrorLog(lErrotString, lMovementsTransactionErrorFileName);
          end;
          FReeAndNil(lResponse);
        finally
          lkmItemMove.Free;
        end;
      end
      else
      begin
        AddToLog(Format('  Already inserted. Skipping epId %s', [QFetchMovementsTransactions.FieldByName('EpID').AsString]));
        Result := DoMarkMovementTransactionsAsExported;
      end;
    end
    else
    begin
      // Do not continue. Some error from BC when trying to get a record
      Result := FALSE;
      lErrotString := 'Unexpected error when checking movement transaction in BC ' + #13#10 +
        '  EP ID: ' + QFetchMovementsTransactions.FieldByName('EPID').AsString + #13#10 +
        '  Code: ' + (lGetResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
        '  Message: ' + (lGetResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10 +
        '  JSON: ' + lJSONStr + #13#10;
      AddToLog(lErrotString);
      AddToErrorLog(lErrotString, lMovementsTransactionErrorFileName);
    end;
    FReeAndNil(lGetResponse);
  end;

begin
  AddToLog('DoSyncronizeMovemmentsTransaction - BEGIN');
  if (ConnectToDB) then
  begin
    AddToLog('  TBusinessCentralSetup.Create');
    lBusinessCentralSetup := TBusinessCentralSetup.Create(LF_BC_BASEURL,
      LF_BC_PORT_Str,
      LF_BC_COMPANY_URL,
      LF_BC_ACTIVECOMPANYID,
      LF_BC_Environment,
      LF_BC_USERNAME,
      LF_BC_PASSWORD,
      LF_BC_Version);
    try
      AddToLog('  TBusinessCentral.Create');
      lBusinessCentral := TBusinessCentral.Create(LogFileFolder);
      try
        if (NOT(tnMain.Active)) then
          tnMain.StartTransaction;

        // Date of last run
        lDaysToLookAfterRecords := iniFile.ReadInteger('MovementsTransaction', 'Days to look for records', 5);
        lDateAndTimeOfLastRun := iniFile.ReadDateTime('MovementsTransaction', 'Last run', NOW - lDaysToLookAfterRecords);
        lFromDateAndTime := lDateAndTimeOfLastRun;
        // Date until now
        lToDateAndTime := NOW;

        // Log
        AddToLog(Format('  Fetching records. movements transactons. Period %s to %s', [FormatDateTime('yyyy-mm-dd hh:mm:ss', lFromDateAndTime),
          FormatDateTime('yyyy-mm-dd hh:mm:ss', lToDateAndTime)]));

        // Fetch movements transactions.

        // AND  (tr.EKSPORTERET = 0 OR tr.EKSPORTERET IS NULL)

        QFetchMovementsTransactions.ParamByName('PFromDate').AsDateTime := lFromDateAndTime;
        QFetchMovementsTransactions.ParamByName('PToDate').AsDateTime := lToDateAndTime;
        QFetchMovementsTransactions.SQL.SaveToFile(SQLLogFileFolder + 'MovementsTransactions.SQL');
        QFetchMovementsTransactions.Open;
        // Log
        AddToLog(Format('  Query opened', []));
        If (Not(QFetchMovementsTransactions.EOF)) then
        begin
          // At least 1 record is there - fetch next transactions UD
          BC_TransactionID := FetchNextTransID('movements transations');
          lNumberOfExportedMovementsTransactions := 0;
          RoutineCanceled := FALSE;
          While (Not(QFetchMovementsTransactions.EOF)) AND (NOT(RoutineCanceled)) do
          begin
            RoutineCanceled := NOT CreateAndExportMovementsTransaction;
            if NOT RoutineCanceled then
            begin
              QFetchMovementsTransactions.Next;
            end;
          end;
          AddToLog('  Iteration done');

          if (NOT(RoutineCanceled)) then
          begin
            if (tnMain.Active) then
              tnMain.Commit;

            iniFile.WriteDateTime('MovementsTransaction', 'Last run', lToDateAndTime);
            InsertTracingLog(11, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
          end
          else
          begin
            lText := 'Der skete en fejl ved synkronisering af flytningstransaktioner til Business Central.' + #13#10 +
              'Vedhæftet er en fil med information' + #13#10;
            SendErrorMail(LogFileFolder + lMovementsTransactionErrorFileName, 'Flytningstransaktioner', lText);
            // Rename error file
            TFile.Move(LogFileFolder + lMovementsTransactionErrorFileName, LogFileFolder + Format('Error_Flytningstransaktioner_%s.txt',
              [FormatDateTime('ddmmyyyy_hhmmss', NOW)]));
            if (tnMain.Active) then
              tnMain.Rollback;
            AddToLog('  Export of movements transaction ended with errors.');
            InsertTracingLog(12, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
          end;
          iniFile.WriteDateTime('MovementsTransaction', 'Last time sync to BC was tried', NOW);
          AddToLog('  Routine done');
        end
        else
        begin
          if (tnMain.Active) then
            tnMain.Commit;
          AddToLog(Format('  No Movements transactions to export', []));
        end;
      finally
        AddToLog('  TBusinessCentral - Free');
        FReeAndNil(lBusinessCentral);
      end;
    finally
      AddToLog('  TBusinessCentralSetup - Free');
      FReeAndNil(lBusinessCentralSetup);
    end;

    DisconnectFromDB;
  end;
  AddToLog('DoSyncronizeMovemmentsTransaction - END');
end;

procedure TDM.DoSyncronizeStockRegulationTransaction;
const
  lStockRegulationsTransactionErrorFileName: String = 'StockRegulationstransactionErrors.txt';
var
  lBusinessCentralSetup: TBusinessCentralSetup;
  lBusinessCentral: TBusinessCentral;
  lDaysToLookAfterRecords: Integer;
  lDateAndTimeOfLastRun: TDateTime;
  lFromDateAndTime: TDateTime;
  lToDateAndTime: Extended;
  BC_TransactionID: Integer;
  lNumberOfExportedStockRegulationTransactions: Integer;
  RoutineCanceled: Boolean;
  lText: string;
  lResponse: TBusinessCentral_Response;

  Function CreateAndExporStockRegulationsTransaction: Boolean;
  var
    lJSONStr: string;
    DoContinue: Boolean;
    lErrotString: string;
    lkmItemAccess: TkmItemAccess;
    DoContinueWithInsert: Boolean;
    lGetResponse: TBusinessCentral_Response;

    function DoMarkStockRegulationTransactionsAsExported: Boolean;
    begin
      if NOT OnlyTestRoutine then
      begin
{$IFDEF RELEASE}
        try
          if NOT trSetEksportedValueOnStockTrans.Active then
          begin
            trSetEksportedValueOnStockTrans.StartTransaction;
          end;
          QSetEksportedValueOnStockTrans.SQL.Clear;

          QSetEksportedValueOnStockTrans.SQL.Add('Update Transaktioner t set');
          QSetEksportedValueOnStockTrans.SQL.Add('  t.Eksporteret = :PEksporteret');
          QSetEksportedValueOnStockTrans.SQL.Add('Where');
          QSetEksportedValueOnStockTrans.SQL.Add('  t.art=11 AND');
          QSetEksportedValueOnStockTrans.SQL.Add('  t.bonnr = :PBOnNr AND');
          QSetEksportedValueOnStockTrans.SQL.Add('  t.dato = :PDato AND');
          QSetEksportedValueOnStockTrans.SQL.Add('  t.levnavn = :PLevNavn AND');
          QSetEksportedValueOnStockTrans.SQL.Add('  t.afdeling_id = :PAfdeling_ID AND');
          QSetEksportedValueOnStockTrans.SQL.Add('  (t.EKSPORTERET>=0 or t.EKSPORTERET IS null)');
          QSetEksportedValueOnStockTrans.ParamByName('PEksporteret').AsInteger := QFetchStockRegulationsTransactions.FieldByName('Eksporteret').AsInteger + 1;
          QSetEksportedValueOnStockTrans.ParamByName('PBOnNr').AsInteger := QFetchStockRegulationsTransactions.FieldByName('Lagertilgangsnummer').AsInteger;
          QSetEksportedValueOnStockTrans.ParamByName('PDato').AsDateTime := QFetchStockRegulationsTransactions.FieldByName('BOGFORINGSDATO').AsDateTime;
          QSetEksportedValueOnStockTrans.ParamByName('PLevNavn').AsString := QFetchStockRegulationsTransactions.FieldByName('LeverandorNavn').AsString;
          QSetEksportedValueOnStockTrans.ParamByName('PAfdeling_ID').AsString := QFetchStockRegulationsTransactions.FieldByName('ButikID').AsString;
          QSetEksportedValueOnStockTrans.ExecSQL;
          if trSetEksportedValueOnStockTrans.Active then
          begin
            trSetEksportedValueOnStockTrans.Commit;
          end;
          Result := TRUE;
        except
          On E: Exception do
          begin
            Result := FALSE;

            lErrotString := Format('Unexpected error when marking stock regulation transaction exported in EasyPOS ' + #13#10 +
              'lagertilgangsnummer eq ''%s'' and leverandRKode eq ''%s'' and butikId eq ''%s'' and bogfRingsDato eq ''%s'' in Business Central' + #13#10 +
              'Message: %s', [
              QFetchStockRegulationsTransactions.FieldByName('Lagertilgangsnummer').AsString,
              QFetchStockRegulationsTransactions.FieldByName('LeverandorKode').AsString,
              QFetchStockRegulationsTransactions.FieldByName('ButikID').AsString,
              FormatDateTime('dd-mm-yyyy', QFetchStockRegulationsTransactions.FieldByName('BOGFORINGSDATO').AsDateTime),
              E.Message
              ]);
            AddToLog(lErrotString);
            AddToErrorLog(lErrotString, lStockRegulationsTransactionErrorFileName);
          end;
        end;
{$ENDIF}
{$IFDEF DEBUG}
        Result := TRUE;
{$ENDIF}
      end
      else
      begin
        Result := TRUE;
      end;
    end;

  begin
    AddToLog(Format('  Checking lagertilgangsnummer eq ''%s'' and leverandRKode eq ''%s'' and butikId eq ''%s'' and bogfRingsDato eq ''%s'' in Business Central', [
      QFetchStockRegulationsTransactions.FieldByName('Lagertilgangsnummer').AsString,
      QFetchStockRegulationsTransactions.FieldByName('LeverandorKode').AsString,
      QFetchStockRegulationsTransactions.FieldByName('ButikID').AsString,
      FormatDateTime('dd-mm-yyyy', QFetchStockRegulationsTransactions.FieldByName('BOGFORINGSDATO').AsDateTime)
      ]));
    lBusinessCentralSetup.FilterValue := Format('lagertilgangsnummer eq ''%s'' and leverandRKode eq ''%s'' and butikId eq ''%s'' and bogfRingsDato eq ''%s'' ', [
      QFetchStockRegulationsTransactions.FieldByName('Lagertilgangsnummer').AsString,
      QFetchStockRegulationsTransactions.FieldByName('LeverandorKode').AsString,
      QFetchStockRegulationsTransactions.FieldByName('ButikID').AsString,
      FormatDateTime('dd-mm-yyyy', QFetchStockRegulationsTransactions.FieldByName('BOGFORINGSDATO').AsDateTime)
      ]);
    // Mine order værdier.-
    lBusinessCentralSetup.OrderValue := '';
    // Select fields
    lBusinessCentralSetup.SelectValue := '';
    // Hent dem.
    DoContinueWithInsert := lBusinessCentral.GetkmItemAccesss(lBusinessCentralSetup, lGetResponse, LF_BC_Version);

    if DoContinueWithInsert then
    begin
      if (lGetResponse as TkmItemAccesss).Value.Count = 0 then
      begin
        lkmItemAccess := TkmItemAccess.Create;
        try
          lkmItemAccess.transId := BC_TransactionID;
          lkmItemAccess.butikId := QFetchStockRegulationsTransactions.FieldByName('ButikID').AsString;
          lkmItemAccess.leverandRKode := QFetchStockRegulationsTransactions.FieldByName('LeverandorKode').AsString;
          lkmItemAccess.lagertilgangsnummer := QFetchStockRegulationsTransactions.FieldByName('Lagertilgangsnummer').AsString;
          lkmItemAccess.bogfRingsDato := FormatDateTime('dd-mm-yyyy', QFetchStockRegulationsTransactions.FieldByName('BOGFORINGSDATO').AsDateTime);
          lkmItemAccess.belB := QFetchStockRegulationsTransactions.FieldByName('Belob').AsFloat;
          lkmItemAccess.status := '0';
          lkmItemAccess.tilbagefRt := FALSE;
          lkmItemAccess.transDato := FormatDateTime('dd-mm-yyyy', NOW);
          lkmItemAccess.transTid := FormatDateTime('hh:mm:ss', NOW);

          lJSONStr := GetDefaultSerializer.SerializeObject(lkmItemAccess);

          INC(lNumberOfExportedStockRegulationTransactions);
          // Add to log
          AddToLog(Format('  Stock regulation transaction record to transfer: %d - %s', [lNumberOfExportedStockRegulationTransactions, lJSONStr]));
          if OnlyTestRoutine then
          begin
            DoContinue := TRUE;
          end
          else
          begin
            DoContinue := (lBusinessCentral.PostkmItemAccess(lBusinessCentralSetup, lkmItemAccess, lResponse, LF_BC_Version));
          end;

          if DoContinue then
          begin
            Result := DoMarkStockRegulationTransactionsAsExported;
          end
          else
          begin
            Result := FALSE;

            lErrotString := 'Unexpected error when inserting stock regulation transaction in BC ' + #13#10 +
              '  EP Bonnr: ' + QFetchStockRegulationsTransactions.FieldByName('LagerTilgangsNummer').AsString + #13#10 +
              '  Code: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
              '  Message: ' + (lResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10 +
              '  JSON: ' + lJSONStr + #13#10;
            AddToLog(lErrotString);
            AddToErrorLog(lErrotString, lStockRegulationsTransactionErrorFileName);
          end;
          FReeAndNil(lResponse);
        finally
          FReeAndNil(lkmItemAccess);
        end;
      end
      else
      begin
        AddToLog(Format
          ('  Already inserted. Skipping lagertilgangsnummer eq ''%s'' and leverandRKode eq ''%s'' and butikId eq ''%s'' and bogfRingsDato eq ''%s'' in Business Central', [
          QFetchStockRegulationsTransactions.FieldByName('Lagertilgangsnummer').AsString,
          QFetchStockRegulationsTransactions.FieldByName('LeverandorKode').AsString,
          QFetchStockRegulationsTransactions.FieldByName('ButikID').AsString,
          FormatDateTime('dd-mm-yyyy', QFetchStockRegulationsTransactions.FieldByName('BOGFORINGSDATO').AsDateTime)
          ]));

        Result := DoMarkStockRegulationTransactionsAsExported;
      end;
    end
    else
    begin
      // Do not continue. Some error from BC when trying to get a record
      Result := FALSE;
      lErrotString := 'Unexpected error when checking stock regulation transaction in BC ' + #13#10 +
        '  EP ID: ' + QFetchStockRegulationsTransactions.FieldByName('EPID').AsString + #13#10 +
        '  Code: ' + (lGetResponse as TBusinessCentral_ErrorResponse).StatusCode.ToString + #13#10 +
        '  Message: ' + (lGetResponse as TBusinessCentral_ErrorResponse).StatusText + #13#10 +
        '  JSON: ' + lJSONStr + #13#10;
      AddToLog(lErrotString);
      AddToErrorLog(lErrotString, lStockRegulationsTransactionErrorFileName);
    end;
    FReeAndNil(lGetResponse);
  end;

begin
  AddToLog('DoSyncronizeStockRegulationTransaction - BEGIN');
  if (ConnectToDB) then
  begin
    AddToLog('  TBusinessCentralSetup.Create');
    lBusinessCentralSetup := TBusinessCentralSetup.Create(LF_BC_BASEURL,
      LF_BC_PORT_Str,
      LF_BC_COMPANY_URL,
      LF_BC_ACTIVECOMPANYID,
      LF_BC_Environment,
      LF_BC_USERNAME,
      LF_BC_PASSWORD,
      LF_BC_Version);
    try
      AddToLog('  TBusinessCentral.Create');
      lBusinessCentral := TBusinessCentral.Create(LogFileFolder);
      try
        if (NOT(tnMain.Active)) then
          tnMain.StartTransaction;

        // Date of last run
        lDaysToLookAfterRecords := iniFile.ReadInteger('StockRegulation', 'Days to look for records', 5);
        lDateAndTimeOfLastRun := iniFile.ReadDateTime('StockRegulation', 'Last run', NOW - lDaysToLookAfterRecords);
        lFromDateAndTime := lDateAndTimeOfLastRun;
        // Date until now
        lToDateAndTime := NOW;

        // Log
        AddToLog(Format('  Fetching records. Stock regulation transactons. Period %s to %s', [FormatDateTime('yyyy-mm-dd hh:mm:ss', lFromDateAndTime),
          FormatDateTime('yyyy-mm-dd hh:mm:ss', lToDateAndTime)]));

        // Fetch movements transactions.
        QFetchStockRegulationsTransactions.ParamByName('PFromDate').AsDateTime := lFromDateAndTime;
        QFetchStockRegulationsTransactions.ParamByName('PToDate').AsDateTime := lToDateAndTime;
        QFetchStockRegulationsTransactions.SQL.SaveToFile(SQLLogFileFolder + 'StockRegulationsTransactions.SQL');
        QFetchStockRegulationsTransactions.Open;

        // Log
        AddToLog(Format('  Query opened', []));
        If (Not(QFetchStockRegulationsTransactions.EOF)) then
        begin
          // At least 1 record is there - fetch next transactions UD
          BC_TransactionID := FetchNextTransID('movements transations');
          lNumberOfExportedStockRegulationTransactions := 0;
          RoutineCanceled := FALSE;
          While (Not(QFetchStockRegulationsTransactions.EOF)) AND (NOT(RoutineCanceled)) do
          begin
            RoutineCanceled := NOT CreateAndExporStockRegulationsTransaction;
            if NOT RoutineCanceled then
            begin
              QFetchStockRegulationsTransactions.Next;
            end;
          end;
          AddToLog('  Iteration done');

          if (NOT(RoutineCanceled)) then
          begin
            if (tnMain.Active) then
              tnMain.Commit;

            iniFile.WriteDateTime('StockRegulation', 'Last run', lToDateAndTime);
            InsertTracingLog(7, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
          end
          else
          begin
            lText := 'Der skete en fejl ved synkronisering af tilgangstransaktioner til Business Central.' + #13#10 +
              'Vedhæftet er en fil med information' + #13#10;
            SendErrorMail(LogFileFolder + lStockRegulationsTransactionErrorFileName, 'tilgangstransaktioner', lText);
            // Rename error file
            TFile.Move(LogFileFolder + lStockRegulationsTransactionErrorFileName, LogFileFolder + Format('Error_Tilgangstransaktioner_%s.txt',
              [FormatDateTime('ddmmyyyy_hhmmss', NOW)]));
            if (tnMain.Active) then
              tnMain.Rollback;
            AddToLog('  Export of stock regulation transaction ended with errors.');
            InsertTracingLog(8, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
          end;
          iniFile.WriteDateTime('StockRegulation', 'Last time sync to BC was tried', NOW);
          AddToLog('  Routine done');
        end
        else
        begin
          if (tnMain.Active) then
            tnMain.Commit;
          AddToLog(Format('  No stock regulation transactions to export', []));
        end;
      finally
        AddToLog('  TBusinessCentral - Free');
        FReeAndNil(lBusinessCentral);
      end;
    finally
      AddToLog('  TBusinessCentralSetup - Free');
      FReeAndNil(lBusinessCentralSetup);
    end;

    DisconnectFromDB;
  end;
  AddToLog('DoSyncronizeStockRegulationTransaction - END');
end;

procedure TDM.DoHandleEksportToBusinessCentral;
var
  lSyncroniseFinancialRecords: Boolean;
  lSyncronizeItem: Boolean;
  lSyncronizeSalesTransactions: Boolean;
  lSyncronizeMovementsTransactions: Boolean;
  lSyncronizeStockRegulationsTransactions: Boolean;
begin
  // This will check what to syncronize and do it.
  try
    if DM.InitialilzeProgram then
    begin
      DoClearFolder(LogFileFolder, 'Log*.*');
      DoClearFolder(LogFileFolder, 'Error*.*');
      DoClearFolder(LogFileFolder + 'FinansEksport\', 'EkspFinancialRecordsToBC*.*');
      DoClearFolder(LogFileFolder + 'BC_Log\', 'BusinessCentral*.*');

      lSyncroniseFinancialRecords := iniFile.ReadBool('SYNCRONIZE', 'FinancialRecords', FALSE);
      lSyncronizeItem := iniFile.ReadBool('SYNCRONIZE', 'Items', FALSE);
      lSyncronizeSalesTransactions := iniFile.ReadBool('SYNCRONIZE', 'SalesTransactions', FALSE);
      lSyncronizeMovementsTransactions := iniFile.ReadBool('SYNCRONIZE', 'MovementsTransactions', FALSE);
      lSyncronizeStockRegulationsTransactions := iniFile.ReadBool('SYNCRONIZE', 'StockRegulationsTransactions', FALSE);

      AddToLog(Format('Syncronize financial records: %s', [lSyncroniseFinancialRecords.ToString]));
      AddToLog(Format('Syncronize Items: %s', [lSyncronizeItem.ToString]));
      AddToLog(Format('Syncronize Sales Transactions: %s', [lSyncronizeSalesTransactions.ToString]));
      AddToLog(Format('Syncronize Movements Transaction: %s', [lSyncronizeMovementsTransactions.ToString]));
      AddToLog(Format('Syncronize Stock regulations Transaction: %s', [lSyncronizeStockRegulationsTransactions.ToString]));
      AddToLog('  ');

      if lSyncronizeItem then
      begin
        DoSyncronizeItems;
      end;

      if lSyncroniseFinancialRecords then
      begin
        DoSyncronizeFinansCialRecords;
      end;

      if lSyncronizeSalesTransactions then
      begin
        DoSyncronizeSalesTransactions;
      end;

      if lSyncronizeMovementsTransactions then
      begin
        DoSyncronizeMovemmentsTransaction;
      end;

      if lSyncronizeStockRegulationsTransactions then
      begin
        DoSyncronizeStockRegulationTransaction;
      end;
      iniFile.WriteDateTime('PROGRAM', 'LAST RUN', NOW);
    end;
  except
    on E: Exception do
    begin
      AddToLog(Format('ERROR. %s', [E.Message]));
      if (tnMain.Active) then
        tnMain.Rollback;
    end;
  end;
end;

function TDM.InitialilzeProgram: Boolean;
(*
  This routine will read global settings from the INI file.
  It will read the programs version.,
  All will be written to global logfile
*)
var
  PrgVers1, PrgVers2, PrgVers3, PrgVers4: Word;

  glRunTime: string;
  glRunEachMinute: Boolean;
  glLastRunTime: TDateTime;

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

  function ItIsTimeToRun: Boolean;
{$IFNDEF DEBUG}
  var
    lCurrentHour: string;
{$ENDIF}
  begin
{$IFDEF DEBUG}
    Result := TRUE;
{$ELSE}
    if glRunEachMinute then
    begin
      Result := TRUE;
    end
    else
    begin
      if FormatDateTime('yyyymmdd', NOW) <> FormatDateTime('yyyymmdd', glLastRunTime) then
      begin
        // It is not today. Check time
        lCurrentHour := FormatDateTime('hh', NOW);
        if lCurrentHour = glRunTime then
        begin
          // It is time to run
          Result := TRUE;
        end
        else
        begin
          // Not the right time to run
          Result := FALSE;
        end;
      end
      else
      begin
        // Last run was today. You cannot run more today
        Result := FALSE;
      end;
    end;
{$ENDIF}
  end;

begin
  GetBuildInfo(PrgVers1, PrgVers2, PrgVers3, PrgVers4);

  // glTimer := iniFile.ReadInteger('PROGRAM', 'TIMER', 300);
  glRunTime := iniFile.ReadString('PROGRAM', 'RUNTIME', '22');
  glRunEachMinute := iniFile.ReadBool('PROGRAM', 'RUN AT EACH MINUTE', FALSE);
  glLastRunTime := iniFile.ReadDateTime('PROGRAM', 'LAST RUN', NOW - 365);
  if glRunEachMinute then
  begin
    glTimer := glRunTime.ToInteger;
  end
  else
  begin
    glTimer := 15; // Check every 15 minutes
  end;
  LogFileFolder := iniFile.ReadString('PROGRAM', 'LOGFILEFOLDER', '');
  AddToLog('EasyPOS Service to synconize data from EasyPOS to BUsiness Central: ' +
    IntToStr(PrgVers1) + '.' +
    IntToStr(PrgVers2) + '.' +
    IntToStr(PrgVers3) + '.' +
    IntToStr(PrgVers4));
  AddToLog(' ');

  if ItIsTimeToRun then
  begin
    Result := TRUE;
    AddToLog('It is time to run.');
    if glRunEachMinute then
    begin
      AddToLog(Format('  Run each %s minute(s)', [glRunTime]));
    end
    else
    begin
      AddToLog(Format('  Time is %s', [FormatDateTime('dd-mm-yyyy hh:mm', glLastRunTime)]));
      AddToLog(Format('  Should run at %s', [glRunTime]));
    end;
    AddToLog(' ');

    SQLLogFileFolder := LogFileFolder + 'SQL\';

    ForceDirectories(LogFileFolder);
    ForceDirectories(SQLLogFileFolder);

    AddToLog('INI file: ' + iniFile.FileName);
    AddToLog(' ');

    AddToLog('Program timer (i minutter): ' + IntToStr(glTimer));
    AddToLog('LogFileFolder: ' + LogFileFolder);
    AddToLog('INI File: ' + ExtractFilePath(ParamStr(0)) + 'Settings.INI');

    EasyPOS_Database := iniFile.ReadString('PROGRAM', 'DATABASE', '');
    EasyPOS_Database_User := iniFile.ReadString('PROGRAM', 'USER', '');
    EasyPOS_Database_Password := iniFile.ReadString('PROGRAM', 'PASSWORD', '');
    EasyPOS_Department := iniFile.ReadString('PROGRAM', 'Department', '');
    EasyPOS_Machine := iniFile.ReadString('PROGRAM', 'Machine', '');
    OnlyTestRoutine := iniFile.ReadBool('PROGRAM', 'TestRoutine', FALSE);
    AddToLog('Database: ' + EasyPOS_Database);
    AddToLog('User: xxx');
    AddToLog('Password: xxx');
    AddToLog('Department: ' + EasyPOS_Department);
    AddToLog('Machine: ' + EasyPOS_Machine);
    AddToLog('Only test: ' + OnlyTestRoutine.ToString(TRUE));

    AddToLog(' ');

    AddToLog('Initialize done  ');
    AddToLog('  ');
  end
  else
  begin
    Result := FALSE;
    AddToLog('It is not time to run.');
    AddToLog(Format('  Last run was %s', [FormatDateTime('dd-mm-yyyy hh:mm', glLastRunTime)]));
    AddToLog(Format('  Should run at %s', [glRunTime]));
  end;

  tiTimer.Interval := glTimer * 1000 * 60;
end;

procedure TDM.tiTimerTimer(Sender: TObject);
begin
  tiTimer.Enabled := FALSE;
  DM.iniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Settings.INI');
  try
    DoHandleEksportToBusinessCentral;
  finally
    DM.iniFile.Free;
  end;
  tiTimer.Interval := glTimer * 1000 * 60;
  tiTimer.Enabled := TRUE;
end;

end.
