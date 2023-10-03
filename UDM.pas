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
    LF_BC_PORT: Integer;
    LF_BC_COMPANY_URL: String;
    LF_BC_USERNAME: String;
    LF_BC_PASSWORD: String;
    LF_BC_ACTIVECOMPANYID: String;

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
  uSendEMail,
  MVCFramework,
  MVCFramework.Serializer.Defaults,
  MVCFramework.Serializer.Commons,
  MVCFramework.Serializer.JsonDataObjects,
  uBusinessCentralIntegration;

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
  LF_BC_PORT := iniFile.ReadInteger('BUSINESS CENTRAL', 'BC_PORT', 0);
  LF_BC_COMPANY_URL := iniFile.ReadString('BUSINESS CENTRAL', 'BC_COMPANY_URL', '');
  LF_BC_USERNAME := iniFile.ReadString('BUSINESS CENTRAL', 'BC_USERNAME', '');
  LF_BC_PASSWORD := iniFile.ReadString('BUSINESS CENTRAL', 'BC_PASSWORD', '');
  LF_BC_ACTIVECOMPANYID := iniFile.ReadString('BUSINESS CENTRAL', 'BC_ACTIVECOMPANYID', '');

  if (LF_BC_BASEURL = '') AND
    (LF_BC_PORT = 0) AND
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
    LF_BC_PORT := QFinansTemp.FieldByName('BC_PORT').AsInteger;
    LF_BC_COMPANY_URL := QFinansTemp.FieldByName('BC_COMPANY_URL').AsString;
    LF_BC_USERNAME := QFinansTemp.FieldByName('BC_USERNAME').AsString;
    LF_BC_PASSWORD := QFinansTemp.FieldByName('BC_PASSWORD').AsString;
    LF_BC_ACTIVECOMPANYID := QFinansTemp.FieldByName('BC_ACTIVECOMPANYID').AsString;
    QFinansTemp.Close;
  end;

  AddToLog('  LF_BC_BASEURL: ' + LF_BC_BASEURL);
  AddToLog('  LF_BC_PORT: ' + LF_BC_PORT.ToString);
  AddToLog('  LF_BC_COMPANY_URL: ' + LF_BC_COMPANY_URL);
  AddToLog('  LF_BC_USERNAME: ' + LF_BC_USERNAME);
  AddToLog('  LF_BC_PASSWORD: ' + LF_BC_PASSWORD);
  AddToLog('  LF_BC_ACTIVECOMPANYID: ' + LF_BC_ACTIVECOMPANYID);

  Result :=
    ((LF_BC_BASEURL <> '') AND
    (LF_BC_PORT <> 0) AND
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

  procedure CreateAndExportFinancialRecord;
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

    { TSI:IGNORE ON }

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
        0: // Oms.
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
        DoContinue := (lBusinessCentral.PostkmCashstatement(lBusinessCentralSetup, lkmCashstatement, lResponse, TRUE));
      end;

      if DoContinue then
      begin
        WriteEksportedRecordToTextfile;
      end
      else
      begin
        lErrotString := 'Der skete en uventet fejl ved indsættelse af finanspost i BC ' + #13#10 +
          '  EP ID: ' + QFetchFinancialRecords.FieldByName('ID').AsString + #13#10 +
          '  Code: ' + 'Appmode' + #13#10 +
          '  Message: ' + #13#10 + 'Appmode' + #13#10 +
          '  JSON: ' + lJSONStr + #13#10;
        AddToLog(lErrotString);
        INC(lErrorCounter);
        AddToErrorLog(lErrotString, lErrorFileName);
      end;
      FReeAndNil(lResponse);
    finally
      lkmCashstatement.Free;
    end;

  end;

  procedure MarkRecordAsHandled;
  begin
    AddToLog('  Mark selected records as handled');
    QFinansTemp.SQL.Clear;
    QFinansTemp.SQL.Add('Update Posteringer set Behandlet=Behandlet+1 Where Dato >= :PStartDato and Dato <= :PSlutDato;');
    QFinansTemp.ParamByName('PStartDato').AsDateTime := QFetchFinancialRecords.ParamByName('PStartDato').AsDateTime;
    QFinansTemp.ParamByName('PSlutDato').AsDateTime := QFetchFinancialRecords.ParamByName('PSlutDato').AsDateTime;
    QFinansTemp.ExecSQL;
  end;

begin
  AddToLog('DoSyncronizeFinansCialRecords - BEGIN');
  if (ConnectToDB) then
  begin
    AddToLog('  TBusinessCentralSetup.Create');
    lBusinessCentralSetup := TBusinessCentralSetup.Create(LF_BC_BASEURL, LF_BC_PORT.ToString, LF_BC_COMPANY_URL, LF_BC_ACTIVECOMPANYID, LF_BC_USERNAME, LF_BC_PASSWORD);
    try
      AddToLog('  TBusinessCentral.Create');
      lBusinessCentral := TBusinessCentral.Create(LogFileFolder);
      try
        if (NOT(tnMain.Active)) then
          tnMain.StartTransaction;

        lDaysToLookAfterRecords := iniFile.ReadInteger('FinancialRecords', 'Days to look for records', 5);
        // iniFile.WriteDateTime('FinancialRecords', 'Last run', NOW - lDaysToLookAfterRecords);
        lDateAndTimeOfLastRun := iniFile.ReadDateTime('FinancialRecords', 'Last run', NOW - lDaysToLookAfterRecords);
        lFromDateAndTime := lDateAndTimeOfLastRun;
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
          // Iterate through result set
          while (NOT(QFetchFinancialRecords.EOF)) do
          begin
            CreateAndExportFinancialRecord;
            QFetchFinancialRecords.Next;
          end;
          AddToLog('  Iteration done');
          if NOT(OnlyTestRoutine) then
          begin
            MarkRecordAsHandled;
          end;
          AddToLog('  Routine done');
          iniFile.WriteDateTime('FinancialRecords', 'Last time sync to BC was tried', NOW);
          iniFile.WriteDateTime('FinancialRecords', 'Last run', lToDateAndTime);
        end
        else
        begin
          // NO records selected
          AddToLog('  No records');
        end;

        QFetchFinancialRecords.Close;
        if (tnMain.Active) then
          tnMain.Commit;

        if (lErrorCounter > 0) then
        begin
          // Some error occured. Send an mail to user
          // Send mail with file LogFolder + lErrorName
          // Rename file
          lText := 'Der skete en fejl ved synkronisering af finansposter til Business Central.' + #13#10 +
            'Vedhæftet er en fil med information' + #13#10;
          SendErrorMail(LogFileFolder + lErrorFileName, 'Finansposter', lText);
          // Rename error file
          TFile.Move(LogFileFolder + lErrorFileName, LogFileFolder + Format('Error_Finansposter_%s.txt', [FormatDateTime('ddmmyyyy_hhmmss', NOW)]))
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
  lFromDateAndTime: Extended;
  lToDateAndTime: Extended;
  lExportCounterHeadItems: Integer;
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
  begin
    if (lCurrentHeadItem <> QFetchItems.FieldByName('VareID').AsString) then
    begin
      // Set current head item
      lCurrentHeadItem := QFetchItems.FieldByName('VareID').AsString;
      // Head item has changed. Do transfer
      AddToLog(Format('  Adding head item %s to Business Central.', [QFetchItems.FieldByName('VareID').AsString]));

      // Build head item
      lkmItem := TkmItem.Create;
      try
        lkmItem.transId := BC_ItemsTransactionID;
        lkmItem.vareId := QFetchItems.FieldByName('VareID').AsString;
        lkmItem.beskrivelse := QFetchItems.FieldByName('Beskrivelse').AsString;
        lkmItem.model := QFetchItems.FieldByName('Model').AsString;
        lkmItem.kostPris := QFetchItems.FieldByName('KostPris').AsFloat;
        lkmItem.salgspris := QFetchItems.FieldByName('SalgsPris').AsFloat;
        lkmItem.leverandRKode := QFetchItems.FieldByName('LeverandorKode').AsString;
        lkmItem.varegruppe := QFetchItems.FieldByName('Varegruppe').AsString;
        lkmItem.status := '0';
        lkmItem.transDato := FormatDateTime('dd-mm-yyyy', NOW);
        lkmItem.transTid := FormatDateTime('hh:mm:ss', NOW);
        lkmItem.tariffNo := QFetchItems.FieldByName('INTRASTAT').AsString;
        lkmItem.countryRegionOfOriginCode := QFetchItems.FieldByName('Country').AsString;
        if TryStrToFloat(QFetchItems.FieldByName('Weigth').AsString, lFloat) then
          lkmItem.netWeight := lFloat
        else
          lkmItem.netWeight := 0;

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
          DoContinue := (lBusinessCentral.PostkmItem(lBusinessCentralSetup, lkmItem, lResponse, TRUE));
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

      if (ContinueWithVariants) then
      begin
        // To this head item we can continue and mark head item as done
        if NOT OnlyTestRoutine then
        begin
          AddToLog(Format('    Head item %s marked as exported', [QFetchItems.FieldByName('VareID').AsString]));
          QItemsTemp.SQL.Clear;
          QItemsTemp.SQL.Add('Update Varer set Eksporteret=Eksporteret+1 where Plu_Nr=:PV;');
          QItemsTemp.ParamByName('PV').AsString := QFetchItems.FieldByName('VareID').AsString;
          QItemsTemp.ExecSQL;
          AddToLog(Format('    Handling variants to head item %s', [QFetchItems.FieldByName('VareID').AsString]));
        end;
      end;
    end;

    if (ContinueWithVariants) then
    begin
      // To this head item we can continue with variants
      Afbrudt := FALSE;

      // Create variant class
      lkmVariantId := TkmVariantId.Create;
      try
        lkmVariantId.transId := BC_VariantsTransactionID;
        lkmVariantId.vareId := QFetchItems.FieldByName('VareID').AsString;
        lkmVariantId.variantId := QFetchItems.FieldByName('VariantID').AsString;
        lkmVariantId.farve := QFetchItems.FieldByName('Farve').AsString;
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
          DoContinue := (lBusinessCentral.PostkmVariantId(lBusinessCentralSetup, lkmVariantId, lResponse, TRUE));
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
  if (ConnectToDB) then
  begin
    AddToLog('  TBusinessCentralSetup.Create');
    lBusinessCentralSetup := TBusinessCentralSetup.Create(LF_BC_BASEURL, LF_BC_PORT.ToString, LF_BC_COMPANY_URL, LF_BC_ACTIVECOMPANYID, LF_BC_USERNAME, LF_BC_PASSWORD);
    try
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

        QFetchItems.ParamByName('PStartDato').AsDateTime := lFromDateAndTime;
        QFetchItems.ParamByName('PSlutDato').AsDateTime := lToDateAndTime;
        QFetchItems.ParamByName('PAfdeling_ID').AsString := lDepartment;
        QFetchItems.SQL.SaveToFile(SQLLogFileFolder + 'Items.SQL');
        QFetchItems.Open;
        QFetchItems.FetchAll;

        AddToLog(Format('  Items fetched: %d', [QFetchItems.RecordCount]));

        lExportCounterHeadItems := 0;
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
          AddToLog(Format('  Exported %d head items and %d variants', [lExportCounterHeadItems, lExportCounterVariants]));
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
          TFile.Move(LogFileFolder + lErrorFileName, LogFileFolder + Format('Error_Varer_%s.txt', [FormatDateTime('ddmmyyyy_hhmmss', NOW)]))
        end
        else
        begin
          // save last time items was checked
          iniFile.WriteDateTime('Items', 'Last run', lToDateAndTime);
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
  AddToLog('DoSyncronizeItems - END');
  AddToLog('  ');
end;

procedure TDM.DoSyncronizeSalesTransactions;
begin
  AddToLog('DoSyncronizeSalesTransactions - BEGIN');
  AddToLog('  Not implemented');
  AddToLog('DoSyncronizeSalesTransactions - END');
end;

procedure TDM.DoSyncronizeMovemmentsTransaction;
begin
  AddToLog('DoSyncronizeMovemmentsTransaction - BEGIN');
  AddToLog('  Not implemented');
  AddToLog('DoSyncronizeMovemmentsTransaction - END');
end;

procedure TDM.DoHandleEksportToBusinessCentral;
var
  lSyncroniseFinancialRecords: Boolean;
  lSyncronizeItem: Boolean;
  lSyncronizeSalesTransactions: Boolean;
  lSyncronizeMovementsTransactions: Boolean;
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

      AddToLog(Format('Syncronize financial records: %s', [lSyncroniseFinancialRecords.ToString]));
      AddToLog(Format('Syncronize Items: %s', [lSyncronizeItem.ToString]));
      AddToLog(Format('Syncronize Sales Transactions: %s', [lSyncronizeSalesTransactions.ToString]));
      AddToLog(Format('Syncronize Movements Transaction: %s', [lSyncronizeMovementsTransactions.ToString]));
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
      iniFile.WriteDateTime('PROGRAM', 'LAST RUN', NOW);
    end;

  except
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
  var
    lCurrentHour: string;
  begin
{$IFDEF DEBUG}
    Result := TRUE;
{$ELSE}
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
{$ENDIF}
  end;

begin
  GetBuildInfo(PrgVers1, PrgVers2, PrgVers3, PrgVers4);

  // glTimer := iniFile.ReadInteger('PROGRAM', 'TIMER', 300);
  glRunTime := iniFile.ReadString('PROGRAM', 'RUNTIME', '22');
  glLastRunTime := iniFile.ReadDateTime('PROGRAM', 'LAST RUN', NOW - 365);
{$IFDEF DEBUG}
  glTimer := 2; // Check every 2 minutes
{$ELSE}
  glTimer := 15; // Check every 15 minutes
{$ENDIF}
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
    AddToLog(Format('  Time is %s', [FormatDateTime('dd-mm-yyyy hh:mm', glLastRunTime)]));
    AddToLog(Format('  Should run at %s', [glRunTime]));
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
