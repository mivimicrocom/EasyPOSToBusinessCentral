object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 
    'Indstillinger til windows serviceprogram (EasyPOS to Business Ce' +
    'ntral)'
  ClientHeight = 662
  ClientWidth = 888
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 728
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object RzPageControl1: TRzPageControl
    Left = 0
    Top = 0
    Width = 888
    Height = 662
    Hint = ''
    ActivePage = TabSheet1
    Align = alClient
    TabIndex = 1
    TabOrder = 0
    ExplicitWidth = 884
    ExplicitHeight = 661
    FixedDimension = 21
    object tsProgram: TRzTabSheet
      Caption = 'Program'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label1: TRzLabel
        Left = 16
        Top = 28
        Width = 237
        Height = 15
        Caption = 'At which hour should the routine run (i.e. 22)'
      end
      object Label2: TRzLabel
        Left = 16
        Top = 105
        Width = 135
        Height = 15
        Caption = 'Select folder to place logs'
      end
      object RzLabel1: TRzLabel
        Left = 16
        Top = 183
        Width = 96
        Height = 15
        Caption = 'EasyPOS Database'
      end
      object RzLabel2: TRzLabel
        Left = 16
        Top = 260
        Width = 65
        Height = 15
        Caption = 'Firebird user'
      end
      object RzLabel6: TRzLabel
        Left = 16
        Top = 338
        Width = 93
        Height = 15
        Caption = 'Firebird password'
      end
      object RzLabel7: TRzLabel
        Left = 16
        Top = 415
        Width = 110
        Height = 15
        Caption = 'EasyPOS department'
      end
      object RzLabel8: TRzLabel
        Left = 16
        Top = 493
        Width = 94
        Height = 15
        Caption = 'EasyPOS Machine'
      end
      object lblLastruntime: TLabel
        Left = 87
        Top = 50
        Width = 76
        Height = 15
        Caption = 'lblLastruntime'
      end
      object edPassword: TRzEdit
        Left = 16
        Top = 355
        Width = 200
        Height = 23
        Text = ''
        PasswordChar = '*'
        TabOrder = 0
      end
      object edDepartment: TRzEdit
        Left = 16
        Top = 432
        Width = 200
        Height = 23
        Text = ''
        TabOrder = 1
      end
      object edMachine: TRzEdit
        Left = 16
        Top = 509
        Width = 200
        Height = 23
        Text = ''
        TabOrder = 2
      end
      object edTimer: TRzNumericEdit
        Left = 16
        Top = 47
        Width = 65
        Height = 23
        Hint = 'Enter minutes between service will check and do export'
        TabOrder = 3
        DisplayFormat = ',0;(,0)'
      end
      object edLogFolder: TRzEdit
        Left = 16
        Top = 124
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 4
      end
      object edDatabase: TRzEdit
        Left = 16
        Top = 201
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 5
      end
      object edUser: TRzEdit
        Left = 16
        Top = 278
        Width = 200
        Height = 23
        Text = ''
        TabOrder = 6
      end
      object cbOnlyTest: TRzCheckBox
        Left = 16
        Top = 568
        Width = 357
        Height = 19
        Caption = 
          'Only run as test (noting will be syncronized to Business Central' +
          ')'
        State = cbUnchecked
        TabOrder = 7
      end
      object btnSelectFolder: TRzBitBtn
        Left = 696
        Top = 122
        Width = 25
        Caption = '*'
        TabOrder = 8
        OnClick = btnSelectFolderClick
      end
    end
    object TabSheet1: TRzTabSheet
      Caption = 'Business Central'
      ExplicitWidth = 880
      ExplicitHeight = 636
      object RzLabel3: TRzLabel
        Left = 24
        Top = 15
        Width = 48
        Height = 15
        Caption = 'Base URL'
      end
      object RzLabel4: TRzLabel
        Left = 24
        Top = 85
        Width = 22
        Height = 15
        Caption = 'Port'
      end
      object RzLabel5: TRzLabel
        Left = 24
        Top = 156
        Width = 76
        Height = 15
        Caption = 'Company URL'
      end
      object RzLabel9: TRzLabel
        Left = 24
        Top = 227
        Width = 53
        Height = 15
        Caption = 'Username'
      end
      object RzLabel10: TRzLabel
        Left = 24
        Top = 297
        Width = 50
        Height = 15
        Caption = 'Password'
      end
      object RzLabel11: TRzLabel
        Left = 24
        Top = 368
        Width = 88
        Height = 15
        Caption = 'Active Company'
      end
      object edBCBaseURL: TRzEdit
        Left = 24
        Top = 36
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 0
      end
      object edBCPOrt: TRzNumericEdit
        Left = 24
        Top = 104
        Width = 65
        Height = 23
        TabOrder = 1
        AllowScientificNotation = False
        DisplayFormat = ',0;(,0)'
      end
      object edBCCompanyURL: TRzEdit
        Left = 24
        Top = 175
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 2
      end
      object edBCUser: TRzEdit
        Left = 24
        Top = 246
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 3
      end
      object edBCPassword: TRzEdit
        Left = 24
        Top = 316
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 4
      end
      object edBCActiveCompany: TRzEdit
        Left = 24
        Top = 387
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 5
      end
    end
    object TabSheet2: TRzTabSheet
      Caption = 'Mail'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object RzLabel12: TRzLabel
        Left = 32
        Top = 23
        Width = 61
        Height = 15
        Caption = 'From name'
      end
      object RzLabel13: TRzLabel
        Left = 32
        Top = 268
        Width = 75
        Height = 15
        Caption = 'Recipient mail'
      end
      object RzLabel14: TRzLabel
        Left = 32
        Top = 329
        Width = 39
        Height = 15
        Caption = 'Subject'
      end
      object RzLabel15: TRzLabel
        Left = 32
        Top = 391
        Width = 25
        Height = 15
        Caption = 'Host'
      end
      object RzLabel16: TRzLabel
        Left = 32
        Top = 452
        Width = 22
        Height = 15
        Caption = 'Port'
      end
      object RzLabel17: TRzLabel
        Left = 32
        Top = 513
        Width = 53
        Height = 15
        Caption = 'Username'
      end
      object RzLabel18: TRzLabel
        Left = 32
        Top = 84
        Width = 54
        Height = 15
        Caption = 'From mail'
      end
      object RzLabel19: TRzLabel
        Left = 32
        Top = 145
        Width = 76
        Height = 15
        Caption = 'Reply to name'
      end
      object RzLabel20: TRzLabel
        Left = 32
        Top = 207
        Width = 69
        Height = 15
        Caption = 'Reply to mail'
      end
      object RzLabel21: TRzLabel
        Left = 32
        Top = 575
        Width = 50
        Height = 15
        Caption = 'Password'
      end
      object edMailSenderName: TRzEdit
        Left = 32
        Top = 44
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 0
      end
      object edMailSenderMail: TRzEdit
        Left = 32
        Top = 105
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 1
      end
      object edMailReplyToName: TRzEdit
        Left = 32
        Top = 166
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 2
      end
      object edMailReplyToMail: TRzEdit
        Left = 32
        Top = 228
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 3
      end
      object edMailReciever: TRzEdit
        Left = 32
        Top = 289
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 4
      end
      object edMailSubject: TRzEdit
        Left = 32
        Top = 350
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 5
      end
      object edMailSMTPHost: TRzEdit
        Left = 32
        Top = 412
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 6
      end
      object edMailSMTPPort: TRzNumericEdit
        Left = 32
        Top = 473
        Width = 65
        Height = 23
        TabOrder = 7
        DisplayFormat = ',0;(,0)'
      end
      object edMailSMTPUSername: TRzEdit
        Left = 32
        Top = 534
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 8
      end
      object edMailSMTPPassword: TRzEdit
        Left = 32
        Top = 596
        Width = 665
        Height = 23
        Text = ''
        TabOrder = 9
      end
    end
    object TabSheet3: TRzTabSheet
      Caption = 'Syncronize'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object cbSyncItems: TRzCheckBox
        Left = 16
        Top = 32
        Width = 108
        Height = 17
        Caption = 'Syncronize items'
        State = cbUnchecked
        TabOrder = 0
      end
      object cbSyncFinancialRecords: TRzCheckBox
        Left = 16
        Top = 72
        Width = 166
        Height = 17
        Caption = 'Syncronize financial records'
        State = cbUnchecked
        TabOrder = 1
      end
      object cbSyncSalesTrans: TRzCheckBox
        Left = 16
        Top = 112
        Width = 171
        Height = 17
        Caption = 'Syncronize sales transactions'
        State = cbUnchecked
        TabOrder = 2
      end
      object cbSyncMovements: TRzCheckBox
        Left = 16
        Top = 152
        Width = 204
        Height = 17
        Caption = 'Syncronize movement transactions'
        State = cbUnchecked
        TabOrder = 3
      end
    end
    object tsItems: TRzTabSheet
      Caption = 'Items'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object RzLabel22: TRzLabel
        Left = 24
        Top = 34
        Width = 335
        Height = 15
        Caption = 
          'Days to look back if routine has never run (no value in Last Run' +
          ')'
      end
      object RzLabel23: TRzLabel
        Left = 24
        Top = 160
        Width = 42
        Height = 15
        Caption = 'Last run'
      end
      object RzLabel24: TRzLabel
        Left = 24
        Top = 97
        Width = 131
        Height = 15
        Caption = 'Department to limit SQL '
      end
      object RzLabel25: TRzLabel
        Left = 24
        Top = 223
        Width = 73
        Height = 15
        Caption = 'Last try to run'
      end
      object edItemsDAys: TRzNumericEdit
        Left = 24
        Top = 55
        Width = 65
        Height = 23
        Hint = 'Enter minutes between service will check and do export'
        TabOrder = 0
        DisplayFormat = ',0;(,0)'
      end
      object edItemsLastRun: TRzEdit
        Left = 24
        Top = 179
        Width = 665
        Height = 23
        Text = ''
        Enabled = False
        ReadOnly = True
        TabOrder = 1
      end
      object edItemsDeparetment: TRzEdit
        Left = 24
        Top = 117
        Width = 65
        Height = 23
        Text = ''
        TabOrder = 2
      end
      object edItemsLastTry: TRzEdit
        Left = 24
        Top = 242
        Width = 665
        Height = 23
        Text = ''
        Enabled = False
        ReadOnly = True
        TabOrder = 3
      end
    end
    object TabSheet4: TRzTabSheet
      Caption = 'Financial records'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object RzLabel26: TRzLabel
        Left = 32
        Top = 42
        Width = 335
        Height = 15
        Caption = 
          'Days to look back if routine has never run (no value in Last Run' +
          ')'
      end
      object RzLabel27: TRzLabel
        Left = 32
        Top = 168
        Width = 42
        Height = 15
        Caption = 'Last run'
      end
      object RzLabel29: TRzLabel
        Left = 32
        Top = 231
        Width = 73
        Height = 15
        Caption = 'Last try to run'
      end
      object edFinancialRecordsDAys: TRzNumericEdit
        Left = 32
        Top = 63
        Width = 65
        Height = 23
        TabOrder = 0
        DisplayFormat = ',0;(,0)'
      end
      object edFinancialRecordsLastRun: TRzEdit
        Left = 32
        Top = 187
        Width = 665
        Height = 23
        Text = ''
        Enabled = False
        ReadOnly = True
        TabOrder = 1
      end
      object edFinancialRecordsLastTry: TRzEdit
        Left = 32
        Top = 250
        Width = 665
        Height = 23
        Text = ''
        Enabled = False
        ReadOnly = True
        TabOrder = 2
      end
    end
    object tsGeneralLog: TRzTabSheet
      OnShow = tsGeneralLogShow
      Caption = 'Programlog'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object mmoLog: TRzMemo
        Left = 217
        Top = 0
        Width = 667
        Height = 637
        Align = alClient
        TabOrder = 0
      end
      object lbLogFiles: TRzListBox
        Left = 0
        Top = 0
        Width = 217
        Height = 637
        Align = alLeft
        ItemHeight = 15
        TabOrder = 1
        OnClick = lbLogFilesClick
      end
    end
    object TabSheet5: TRzTabSheet
      OnShow = TabSheet5Show
      Caption = 'Business Central Log'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object lbBCLogFiles: TRzListBox
        Left = 0
        Top = 0
        Width = 297
        Height = 637
        Align = alLeft
        ItemHeight = 15
        TabOrder = 0
        OnClick = lbBCLogFilesClick
      end
      object mmoBCLogs: TRzMemo
        Left = 297
        Top = 0
        Width = 587
        Height = 637
        Align = alClient
        TabOrder = 1
      end
    end
    object TabSheet6: TRzTabSheet
      OnShow = TabSheet6Show
      Caption = 'Finanseksportlog'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 880
      ExplicitHeight = 636
      object lbFinansLogFiles: TRzListBox
        Left = 0
        Top = 0
        Width = 297
        Height = 637
        Align = alLeft
        ItemHeight = 15
        TabOrder = 0
        OnClick = lbFinansLogFilesClick
      end
      object mmoFinansLog: TRzMemo
        Left = 297
        Top = 0
        Width = 587
        Height = 637
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 583
        ExplicitHeight = 636
      end
    end
  end
  object RzSelectFolderDialog1: TRzSelectFolderDialog
    Title = 'V'#230'lg folder til logfiler'
    Left = 200
    Top = 688
  end
end
