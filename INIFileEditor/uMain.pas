unit uMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.IOUtils,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.Mask,
  INiFiles,
  RzEdit,
  RzLabel,
  RzButton,
  RzShellDialogs,
  RzRadChk,
  RzTabs,
  RzLstBox;

type
  TfrmMain = class(TForm)
    RzSelectFolderDialog1: TRzSelectFolderDialog;
    RzPageControl1: TRzPageControl;
    tsProgram: TRzTabSheet;
    edPassword: TRzEdit;
    edDepartment: TRzEdit;
    edMachine: TRzEdit;
    Label1: TRzLabel;
    Label2: TRzLabel;
    edTimer: TRzNumericEdit;
    edLogFolder: TRzEdit;
    RzLabel1: TRzLabel;
    edDatabase: TRzEdit;
    edUser: TRzEdit;
    RzLabel2: TRzLabel;
    RzLabel6: TRzLabel;
    RzLabel7: TRzLabel;
    RzLabel8: TRzLabel;
    cbOnlyTest: TRzCheckBox;
    btnSelectFolder: TRzBitBtn;
    TabSheet1: TRzTabSheet;
    RzLabel3: TRzLabel;
    edBCBaseURL: TRzEdit;
    edBCPOrt: TRzNumericEdit;
    RzLabel4: TRzLabel;
    edBCCompanyURL: TRzEdit;
    RzLabel5: TRzLabel;
    edBCUser: TRzEdit;
    RzLabel9: TRzLabel;
    edBCPassword: TRzEdit;
    RzLabel10: TRzLabel;
    edBCActiveCompany: TRzEdit;
    RzLabel11: TRzLabel;
    TabSheet2: TRzTabSheet;
    edMailSenderName: TRzEdit;
    RzLabel12: TRzLabel;
    RzLabel13: TRzLabel;
    RzLabel14: TRzLabel;
    RzLabel15: TRzLabel;
    RzLabel16: TRzLabel;
    RzLabel17: TRzLabel;
    RzLabel18: TRzLabel;
    RzLabel19: TRzLabel;
    RzLabel20: TRzLabel;
    RzLabel21: TRzLabel;
    edMailSenderMail: TRzEdit;
    edMailReplyToName: TRzEdit;
    edMailReplyToMail: TRzEdit;
    edMailReciever: TRzEdit;
    edMailSubject: TRzEdit;
    edMailSMTPHost: TRzEdit;
    edMailSMTPPort: TRzNumericEdit;
    edMailSMTPUSername: TRzEdit;
    edMailSMTPPassword: TRzEdit;
    TabSheet3: TRzTabSheet;
    cbSyncItems: TRzCheckBox;
    cbSyncFinancialRecords: TRzCheckBox;
    cbSyncSalesTrans: TRzCheckBox;
    cbSyncMovements: TRzCheckBox;
    tsItems: TRzTabSheet;
    RzLabel22: TRzLabel;
    edItemsDAys: TRzNumericEdit;
    RzLabel23: TRzLabel;
    edItemsLastRun: TRzEdit;
    RzLabel24: TRzLabel;
    edItemsDeparetment: TRzEdit;
    RzLabel25: TRzLabel;
    edItemsLastTry: TRzEdit;
    TabSheet4: TRzTabSheet;
    RzLabel26: TRzLabel;
    edFinancialRecordsDAys: TRzNumericEdit;
    RzLabel27: TRzLabel;
    edFinancialRecordsLastRun: TRzEdit;
    RzLabel29: TRzLabel;
    edFinancialRecordsLastTry: TRzEdit;
    tsGeneralLog: TRzTabSheet;
    mmoLog: TRzMemo;
    lbLogFiles: TRzListBox;
    TabSheet5: TRzTabSheet;
    lbBCLogFiles: TRzListBox;
    mmoBCLogs: TRzMemo;
    TabSheet6: TRzTabSheet;
    lbFinansLogFiles: TRzListBox;
    mmoFinansLog: TRzMemo;
    lblLastruntime: TLabel;
    cbUseTLS: TRzCheckBox;
    TabSheet7: TRzTabSheet;
    TabSheet8: TRzTabSheet;
    TabSheet9: TRzTabSheet;
    RzTabSheet1: TRzTabSheet;
    RzLabel28: TRzLabel;
    RzLabel30: TRzLabel;
    RzLabel31: TRzLabel;
    RzNumericEdit1: TRzNumericEdit;
    RzEdit1: TRzEdit;
    RzEdit2: TRzEdit;
    RzLabel32: TRzLabel;
    edSalesTransactionsDays: TRzNumericEdit;
    edSalesTransactionsLastRun: TRzEdit;
    edSalesTransactionsLastTry: TRzEdit;
    RzLabel33: TRzLabel;
    RzLabel34: TRzLabel;
    RzLabel35: TRzLabel;
    edMovementsTransactionsDays: TRzNumericEdit;
    edMovementTransactionsLastRun: TRzEdit;
    edMovementTransactionsLastTry: TRzEdit;
    RzLabel36: TRzLabel;
    RzLabel37: TRzLabel;
    RzLabel38: TRzLabel;
    edStockRegulationTransactionsDays: TRzNumericEdit;
    edStockRegulationTransactionsLastRun: TRzEdit;
    edStockRegulationTransactionsLastTry: TRzEdit;
    RzLabel39: TRzLabel;
    RzLabel40: TRzLabel;
    cbSyncStockRegulations: TRzCheckBox;
    cbHvertMinut: TCheckBox;
    edEnvironment: TRzEdit;
    RzLabel41: TRzLabel;
    cbSyncCostpriceToEasyPOS: TRzCheckBox;
    TabSheet10: TRzTabSheet;
    RzLabel42: TRzLabel;
    edNumberofUtemsToUpdateCostprice: TRzNumericEdit;
    edBusinessCentralKunde: TRzEdit;
    RzLabel43: TRzLabel;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSelectFolderClick(Sender: TObject);
    procedure tsGeneralLogShow(Sender: TObject);
    procedure lbLogFilesClick(Sender: TObject);
    procedure TabSheet5Show(Sender: TObject);
    procedure lbBCLogFilesClick(Sender: TObject);
    procedure TabSheet6Show(Sender: TObject);
    procedure lbFinansLogFilesClick(Sender: TObject);
  private
    FiniFile: TINIFile;
    FiniFileName: string;
    procedure ReadSettingsFromINIFile;
    procedure WriteSettingsFromINIFile;
    { Private declarations }
  public
    { Public declarations }
    property iniFile: TINIFile read FiniFile write FiniFile;
    property iniFileName: string read FiniFileName write FiniFileName;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}


procedure TfrmMain.btnSelectFolderClick(Sender: TObject);
begin
  RzSelectFolderDialog1.SelectedFolder.PathName := edLogFolder.Text;
  if RzSelectFolderDialog1.Execute then
  begin
    edLogFolder.Text := RzSelectFolderDialog1.SelectedPathName + '\';
  end;
end;

procedure TfrmMain.ReadSettingsFromINIFile;
begin
  edTimer.Text := IntToStr(FiniFile.ReadInteger('PROGRAM', 'RUNTIME', 60));
  cbHvertMinut.Checked := FiniFile.ReadBool('PROGRAM', 'RUN AT EACH MINUTE', FALSE);
  lblLastruntime.Caption := Format('Routine ran last time at: %s',[FiniFile.ReadString('PROGRAM', 'LAST RUN', '')]);
  edLogFolder.Text := FiniFile.ReadString('PROGRAM', 'LOGFILEFOLDER', '');
  edDatabase.Text := FiniFile.ReadString('PROGRAM', 'DATABASE', '');
  edUser.Text := FiniFile.ReadString('PROGRAM', 'USER', '');
  edPassword.Text := FiniFile.ReadString('PROGRAM', 'PASSWORD', '');
  edDepartment.Text := FiniFile.ReadString('PROGRAM', 'Department', '');
  edMachine.Text := FiniFile.ReadString('PROGRAM', 'Machine', '');
  cbOnlyTest.Checked := FiniFile.ReadBool('PROGRAM', 'TestRoutine', FALSE);

  edBCBaseURL.Text := FiniFile.ReadString('BUSINESS CENTRAL', 'BC_BASEURL', '');
  edBCCompanyURL.Text := FiniFile.ReadString('BUSINESS CENTRAL', 'BC_COMPANY_URL', '');
  edBCUser.Text := FiniFile.ReadString('BUSINESS CENTRAL', 'BC_USERNAME', '');
  edBCPassword.Text := FiniFile.ReadString('BUSINESS CENTRAL', 'BC_PASSWORD', '');
  edBCActiveCompany.Text := FiniFile.ReadString('BUSINESS CENTRAL', 'BC_ACTIVECOMPANYID', '');
  edBCPOrt.Text := FiniFile.ReadString('BUSINESS CENTRAL', 'BC_PORT', '');
  edBusinessCentralKunde.Text := iniFile.ReadString('BUSINESS CENTRAL', 'Online Business Central', '');
  edEnvironment.Text := FiniFile.ReadString('BUSINESS CENTRAL', 'BC_ENVIRONMENT', '');

  edMailSenderName.Text := FiniFile.ReadString('MAIL', 'From name', '');
  edMailSenderMail.Text := FiniFile.ReadString('MAIL', 'From mail', '');
  edMailReplyToName.Text := FiniFile.ReadString('MAIL', 'Reply name', '');
  edMailReplyToMail.Text := FiniFile.ReadString('MAIL', 'Reply mail', '');
  edMailReciever.Text := FiniFile.ReadString('MAIL', 'Recipient Mail', '');
  edMailSubject.Text := FiniFile.ReadString('MAIL', 'Subject', '');
  edMailSMTPHost.Text := FiniFile.ReadString('MAIL', 'Host', '');
  edMailSMTPPort.Text := FiniFile.ReadString('MAIL', 'Port', '');
  cbUseTLS.Checked := FiniFile.ReadBool('MAIL', 'UseTSL', FALSE);
  edMailSMTPUSername.Text := FiniFile.ReadString('MAIL', 'Username', '');
  edMailSMTPPassword.Text := FiniFile.ReadString('MAIL', 'password', '');

  cbSyncFinancialRecords.Checked := FiniFile.ReadBool('SYNCRONIZE', 'FinancialRecords', FALSE);
  cbSyncItems.Checked := FiniFile.ReadBool('SYNCRONIZE', 'Items', FALSE);
  cbSyncSalesTrans.Checked := FiniFile.ReadBool('SYNCRONIZE', 'SalesTransactions', FALSE);
  cbSyncMovements.Checked := FiniFile.ReadBool('SYNCRONIZE', 'MovementsTransactions', FALSE);
  cbSyncStockRegulations.Checked := FiniFile.ReadBool('SYNCRONIZE', 'StockRegulationsTransactions', FALSE);
  cbSyncCostpriceToEasyPOS.Checked := FiniFile.ReadBool('SYNCRONIZE', 'Costprice from BC', FALSE);

  edItemsDAys.Text := FiniFile.ReadString('ITEMS', 'Days to look for records', '5');
  edItemsDeparetment.Text := FiniFile.ReadString('ITEMS', 'Department', '');
  edItemsLastRun.Text := FiniFile.ReadString('ITEMS', 'Last run', '');
  edItemsLastTry.Text := FiniFile.ReadString('ITEMS', 'Last time sync to BC was tried', '');

  edFinancialRecordsDAys.Text := FiniFile.ReadString('FinancialRecords', 'Days to look for records', '5');
  edFinancialRecordsLastRun.Text := FiniFile.ReadString('FinancialRecords', 'Last run', '');
  edFinancialRecordsLastTry.Text := FiniFile.ReadString('FinancialRecords', 'Last time sync to BC was tried', '');

  edSalesTransactionsDays.Text := FiniFile.ReadString('SalesTransaction', 'Days to look for records', '5');
  edSalesTransactionsLastRun.Text := FiniFile.ReadString('SalesTransaction', 'Last run', '');
  edSalesTransactionsLastTry.Text := FiniFile.ReadString('SalesTransaction', 'Last time sync to BC was tried', '');

  edMovementsTransactionsDays.Text := FiniFile.ReadString('MovementsTransaction', 'Days to look for records', '5');
  edMovementTransactionsLastRun.Text := FiniFile.ReadString('MovementsTransaction', 'Last run', '');
  edMovementTransactionsLastTry.Text := FiniFile.ReadString('MovementsTransaction', 'Last time sync to BC was tried', '');

  edStockRegulationTransactionsDays.Text := FiniFile.ReadString('StockRegulation', 'Days to look for records', '5');
  edStockRegulationTransactionsLastRun.Text := FiniFile.ReadString('StockRegulation', 'Last run', '');
  edStockRegulationTransactionsLastTry.Text := FiniFile.ReadString('StockRegulation', 'Last time sync to BC was tried', '');

  edNumberofUtemsToUpdateCostprice.Text := FiniFile.ReadString('Costprice', 'Items to handle per cycle', '50');
end;

procedure TfrmMain.TabSheet5Show(Sender: TObject);
var
  lFilSti: string;
  lFilNavn: string;
  FileAttrs: Integer;
  sr: TSearchRec;
begin
  lbBCLogFiles.Items.Clear;

  lFilSti := edLogFolder.Text + 'BC_Log\';
  // Set log file wildcard
  lFilNavn := lFilSti + 'BusinessCentral*.*';
  FileAttrs := faAnyFile;
  // Find first logfile
  if FindFirst(lFilNavn, FileAttrs, sr) = 0 then
  begin
    lbBCLogFiles.Items.Add(sr.Name);
  end;
  // Find next logfile
  while (FindNext(sr) = 0) do
  begin
    lbBCLogFiles.Items.Add(sr.Name);
  end;
  lbBCLogFiles.ItemIndex := 0;
  mmoBCLogs.Lines.LoadFromFile(lFilSti + lbBCLogFiles.Items[lbBCLogFiles.ItemIndex]);
end;

procedure TfrmMain.TabSheet6Show(Sender: TObject);
var
  lFilSti: string;
  lFilNavn: string;
  FileAttrs: Integer;
  sr: TSearchRec;
begin
  lbBCLogFiles.Items.Clear;

  lFilSti := edLogFolder.Text + 'FinansEksport\';
  // Set log file wildcard
  lFilNavn := lFilSti + 'EkspFinancialRecordsToBC*.*';
  FileAttrs := faAnyFile;
  // Find first logfile
  if FindFirst(lFilNavn, FileAttrs, sr) = 0 then
  begin
    lbFinansLogFiles.Items.Add(sr.Name);
  end;
  // Find next logfile
  while (FindNext(sr) = 0) do
  begin
    lbFinansLogFiles.Items.Add(sr.Name);
  end;
  lbFinansLogFiles.ItemIndex := 0;
  mmoFinansLog.Lines.LoadFromFile(lFilSti + lbFinansLogFiles.Items[lbFinansLogFiles.ItemIndex]);
end;

procedure TfrmMain.tsGeneralLogShow(Sender: TObject);
var
  lFilSti: string;
  lFilNavn: string;
  FileAttrs: Integer;
  sr: TSearchRec;
begin
  lbLogFiles.Items.Clear;

  lFilSti := edLogFolder.Text;
  // Set log file wildcard
  lFilNavn := lFilSti + 'Log*.*';
  FileAttrs := faAnyFile;
  // Find first logfile
  if FindFirst(lFilNavn, FileAttrs, sr) = 0 then
  begin
    lbLogFiles.Items.Add(sr.Name);
  end;
  // Find next logfile
  while (FindNext(sr) = 0) do
  begin
    lbLogFiles.Items.Add(sr.Name);
  end;

  // Set log file wildcard
  lFilNavn := lFilSti + 'Err*.*';
  FileAttrs := faAnyFile;
  // Find first logfile
  if FindFirst(lFilNavn, FileAttrs, sr) = 0 then
  begin
    lbLogFiles.Items.Add(sr.Name);
  end;
  // Find next logfile
  while (FindNext(sr) = 0) do
  begin
    lbLogFiles.Items.Add(sr.Name);
  end;

  lbLogFiles.ItemIndex := 0;
  mmoLog.Lines.LoadFromFile(lFilSti + lbLogFiles.Items[lbLogFiles.ItemIndex]);
end;

procedure TfrmMain.WriteSettingsFromINIFile;
begin
  FiniFile.WriteInteger('PROGRAM', 'RUNTIME', StrToInt(edTimer.Text));
  FiniFile.WriteBool('PROGRAM', 'RUN AT EACH MINUTE', cbHvertMinut.Checked);
  FiniFile.WriteString('PROGRAM', 'LOGFILEFOLDER', edLogFolder.Text);
  FiniFile.WriteString('PROGRAM', 'DATABASE', edDatabase.Text);
  FiniFile.WriteString('PROGRAM', 'USER', edUser.Text);
  FiniFile.WriteString('PROGRAM', 'PASSWORD', edPassword.Text);
  FiniFile.WriteString('PROGRAM', 'Department', edDepartment.Text);
  FiniFile.WriteString('PROGRAM', 'Machine', edMachine.Text);
  FiniFile.WriteBool('PROGRAM', 'TestRoutine', cbOnlyTest.Checked);

  FiniFile.WriteString('BUSINESS CENTRAL', 'BC_BASEURL', edBCBaseURL.Text);
  FiniFile.WriteString('BUSINESS CENTRAL', 'BC_COMPANY_URL', edBCCompanyURL.Text);
  FiniFile.WriteString('BUSINESS CENTRAL', 'BC_USERNAME', edBCUser.Text);
  FiniFile.WriteString('BUSINESS CENTRAL', 'BC_PASSWORD', edBCPassword.Text);
  FiniFile.WriteString('BUSINESS CENTRAL', 'BC_ACTIVECOMPANYID', edBCActiveCompany.Text);
  FiniFile.WriteString('BUSINESS CENTRAL', 'BC_ENVIRONMENT', edEnvironment.Text);
  FiniFile.WriteInteger('BUSINESS CENTRAL', 'BC_PORT', edBCPOrt.IntValue);
  FiniFile.WriteString('BUSINESS CENTRAL', 'Online Business Central', edBusinessCentralKunde.Text);


  FiniFile.WriteString('MAIL', 'From name', edMailSenderName.Text);
  FiniFile.WriteString('MAIL', 'From mail', edMailSenderMail.Text);
  FiniFile.WriteString('MAIL', 'Reply name', edMailReplyToName.Text);
  FiniFile.WriteString('MAIL', 'Reply mail', edMailReplyToMail.Text);
  FiniFile.WriteString('MAIL', 'Recipient Mail', edMailReciever.Text);
  FiniFile.WriteString('MAIL', 'Subject', edMailSubject.Text);
  FiniFile.WriteString('MAIL', 'Host', edMailSMTPHost.Text);
  FiniFile.WriteInteger('MAIL', 'Port', edMailSMTPPort.IntValue);
  FiniFile.WriteBool('MAIL', 'UseTSL', cbUseTLS.Checked);

  FiniFile.WriteString('MAIL', 'Username', edMailSMTPUSername.Text);
  FiniFile.WriteString('MAIL', 'password', edMailSMTPPassword.Text);

  FiniFile.WriteBool('SYNCRONIZE', 'FinancialRecords', cbSyncFinancialRecords.Checked);
  FiniFile.WriteBool('SYNCRONIZE', 'Items', cbSyncItems.Checked);
  FiniFile.WriteBool('SYNCRONIZE', 'SalesTransactions', cbSyncSalesTrans.Checked);
  FiniFile.WriteBool('SYNCRONIZE', 'MovementsTransactions', cbSyncMovements.Checked);
  FiniFile.WriteBool('SYNCRONIZE', 'StockRegulationsTransactions', cbSyncStockRegulations.Checked);
  FiniFile.WriteBool('SYNCRONIZE', 'Costprice from BC', cbSyncCostpriceToEasyPOS.Checked);

  FiniFile.WriteString('ITEMS', 'Days to look for records', edItemsDAys.Text);
  FiniFile.WriteString('ITEMS', 'Department', edItemsDeparetment.Text);
  FiniFile.WriteString('ITEMS', 'Last run', edItemsLastRun.Text);
  FiniFile.WriteString('ITEMS', 'Last time sync to BC was tried', edItemsLastTry.Text);

  FiniFile.WriteString('FinancialRecords', 'Days to look for records', edFinancialRecordsDAys.Text);
  FiniFile.WriteString('FinancialRecords', 'Last run', edFinancialRecordsLastRun.Text);
  FiniFile.WriteString('FinancialRecords', 'Last time sync to BC was tried', edFinancialRecordsLastTry.Text);

  FiniFile.WriteString('SalesTransaction', 'Days to look for records', edSalesTransactionsDays.Text);
  FiniFile.WriteString('SalesTransaction', 'Last run', edSalesTransactionsLastRun.Text);
  FiniFile.WriteString('SalesTransaction', 'Last time sync to BC was tried', edSalesTransactionsLastTry.Text);

  FiniFile.WriteString('MovementsTransaction', 'Days to look for records', edMovementsTransactionsDays.Text);
  FiniFile.WriteString('MovementsTransaction', 'Last run', edMovementTransactionsLastRun.Text);
  FiniFile.WriteString('MovementsTransaction', 'Last time sync to BC was tried', edMovementTransactionsLastTry.Text);

  FiniFile.WriteString('StockRegulation', 'Days to look for records', edStockRegulationTransactionsDays.Text);
  FiniFile.WriteString('StockRegulation', 'Last run', edStockRegulationTransactionsLastRun.Text);
  FiniFile.WriteString('StockRegulation', 'Last time sync to BC was tried', edStockRegulationTransactionsLastTry.Text);

  FiniFile.WriteString('Costprice', 'Items to handle per cycle', edNumberofUtemsToUpdateCostprice.Text);

end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  lSourceFile: string;
  lDestinationFile: string;
begin
  lSourceFile := ExtractFilePath(Application.ExeName) + '\' + FiniFileName;
  lDestinationFile := ExtractFilePath(Application.ExeName) + '\' + TPath.GetFileNameWithoutExtension(FiniFileName) + '.BAK';
  TFile.Copy(lSourceFile, lDestinationFile, true);
  WriteSettingsFromINIFile;
  FiniFile.Free;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FiniFileName := 'Settings.ini';
  RzPageControl1.ActivePageIndex := 0;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  lFileName: string;
begin
  lFileName := ExtractFilePath(Application.ExeName) + '\' + FiniFileName;
  if FileExists(lFileName) then
  begin
    FiniFile := TINIFile.Create(lFileName);
    ReadSettingsFromINIFile;
  end
  else
  begin
    ShowMessage('INI fil (settings.ini) ikke fundet.');
  end;
end;

procedure TfrmMain.lbBCLogFilesClick(Sender: TObject);
begin
  mmoBCLogs.Lines.LoadFromFile(edLogFolder.Text + 'BC_Log\' + lbBCLogFiles.Items[lbBCLogFiles.ItemIndex]);
end;

procedure TfrmMain.lbFinansLogFilesClick(Sender: TObject);
begin
  mmoFinansLog.Lines.LoadFromFile(edLogFolder.Text + 'FinansEksport\' + lbFinansLogFiles.Items[lbFinansLogFiles.ItemIndex]);
end;

procedure TfrmMain.lbLogFilesClick(Sender: TObject);
begin
  mmoLog.Lines.LoadFromFile(edLogFolder.Text + lbLogFiles.Items[lbLogFiles.ItemIndex]);
end;

end.
