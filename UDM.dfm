object DM: TDM
  OldCreateOrder = False
  Height = 848
  Width = 1148
  object DB: TIBDatabase
    DatabaseName = '10.0.1.18/3070:e:\Data\FB30\Kaufmann\OCCEasyPOS.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey')
    LoginPrompt = False
    DefaultTransaction = tr
    ServerType = 'IBServer'
    SQLDialect = 1
    AllowStreamedConnected = False
    Left = 60
    Top = 36
  end
  object tr: TIBTransaction
    DefaultDatabase = DB
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    Left = 63
    Top = 104
  end
  object QFetchWEBOrder: TIBQuery
    Database = DB
    Transaction = tr
    BufferChunks = 1000
    CachedUpdates = False
    ParamCheck = True
    SQL.Strings = (
      'SELECT'
      '  UDVALG_DETAIL.ID,'
      '  UDVALG_DETAIL.BONNR,'
      '  UDVALG_DETAIL.IDNR,'
      '  UDVALG_DETAIL.ART,'
      '  UDVALG_DETAIL.AFDELING_ID,'
      '  UDVALG_DETAIL.UAFD_NAVN,'
      '  UDVALG_DETAIL.BONTYPE,'
      '  UDVALG_DETAIL.DATO,'
      '  UDVALG_DETAIL.PICTURE_URL,'
      '  UDVALG_DETAIL.VARENUMMER,'
      '  UDVALG_DETAIL.FARVE,'
      '  UDVALG_DETAIL.STOERRELSE,'
      '  UDVALG_DETAIL.LAENGDE,'
      '  UDVALG_DETAIL.BONTEKST,'
      '  FARVER.V509INDEX as FarveV509'
      'FROM'
      '  UDVALG_DETAIL'
      
        '  INNER JOIN VAREFRVSTR ON UDVALG_DETAIL.BONTEKST = VAREFRVSTR.V' +
        '509INDEX'
      '  INNER JOIN FARVER ON VAREFRVSTR.FARVE_NAVN = FARVER.NAVN'
      'WHERE'
      '  UDVALG_DETAIL.BONTYPE = 0 AND'
      '  UDVALG_DETAIL.DATO >= :PDato')
    Left = 116
    Top = 56
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'PDato'
        ParamType = ptUnknown
      end>
  end
  object tiTimer: TTimer
    Enabled = False
    OnTimer = tiTimerTimer
    Left = 392
    Top = 456
  end
  object trInsert: TIBTransaction
    DefaultDatabase = DB
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    Left = 211
    Top = 216
  end
  object QTemp: TIBQuery
    Database = DB
    Transaction = trInsert
    BufferChunks = 1000
    CachedUpdates = False
    ParamCheck = True
    Left = 300
    Top = 276
  end
end
