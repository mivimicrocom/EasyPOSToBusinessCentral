object DM: TDM
  Height = 848
  Width = 1148
  object tiTimer: TTimer
    Enabled = False
    OnTimer = tiTimerTimer
    Left = 872
    Top = 128
  end
  object dbMain: TFDConnection
    Params.Strings = (
      'SQLDialect=1'
      'User_Name=sysdba'
      'Password=masterkey'
      'Database=e:\Data\FB30\Kaufmann\OCCEasyPOS.FDB'
      'Protocol=TCPIP'
      'Server=10.8.32.21'
      'Port=3070'
      'DriverID=FB')
    TxOptions.AutoStop = False
    Left = 88
    Top = 184
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    VendorLib = '.\fbclient.dll'
    Left = 129
    Top = 102
  end
  object tnMain: TFDTransaction
    Options.AutoStop = False
    Connection = dbMain
    Left = 104
    Top = 266
  end
  object QFetchFinancialRecords: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    SQL.Strings = (
      '/* Oms'#230'tningsposter. Grouperet efter afdeling, dato, kontonr */'
      'SELECT'
      '    /*01*/ POSTERINGER.DATO AS Dato,'
      '    /*02*/ POSTERINGER.KONTONR,'
      '    /*03*/ CAST('#39'Oms.'#39' AS VARCHAR(60)) AS Tekst,'
      '    /*04*/ SUM(POSTERINGER.BELOB) Belob,'
      '    /*05*/ POSTERINGER.AFDELING_ID,'
      '    /*06*/ POSTERINGER.UAFD_NAVN,'
      '    /*07*/ POSTERINGER.POSTTYPE,'
      '    /*08*/ POSTERINGER.SORTERING,'
      '    /*09*/ POSTERINGER.behandlet,'
      '    /*10*/ POSTERINGER.kontotype,'
      '    /*11*/ POSTERINGER.bilagsnr,'
      '    /*12*/ POSTERINGER.afdeling,'
      '    /*13*/ POSTERINGER.modkonto,'
      '    /*14*/ POSTERINGER.modbilag,'
      '    /*15*/ POSTERINGER.valuta,'
      '    /*16*/ POSTERINGER.valutakode,'
      '    /*17*/ POSTERINGER.uafd_grp_navn,'
      '    /*18*/ POSTERINGER.MOMSKODE,'
      '    /*19*/ MAX(POSTERINGER.ID) ID,'
      '    /*19*/ CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    POSTERINGER.Sortering = 10 AND'
      '    POSTERINGER.Belob <> 0 AND'
      '    (NOT(POSTERINGER.PostType = 25))'
      'GROUP BY'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    1,'
      '    POSTERINGER.KONTONR,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    9,'
      '    10,'
      '    11,'
      '    12,'
      '    13,'
      '    14,'
      '    15,'
      '    16,'
      '    17,'
      '    18,'
      '    20'
      'HAVING'
      '    SUM(POSTERINGER.BELOB) <> 0'
      ''
      'UNION'
      ''
      
        '/* Afregninger. Grouperet efter afdeling, dato, kontonr  uden fo' +
        'rskydning*/'
      'SELECT'
      '    POSTERINGER.DATO AS Dato,'
      '    POSTERINGER.KONTONR,'
      '    CAST(POSTERINGER.Tekst AS VARCHAR(60)) AS Tekst,'
      '    SUM(POSTERINGER.BELOB) Belob,'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    POSTERINGER.behandlet,'
      '    POSTERINGER.kontotype,'
      '    POSTERINGER.bilagsnr,'
      '    POSTERINGER.afdeling,'
      '    POSTERINGER.modkonto,'
      '    POSTERINGER.modbilag,'
      '    POSTERINGER.valuta,'
      '    POSTERINGER.valutakode,'
      '    POSTERINGER.uafd_grp_navn,'
      '    POSTERINGER.MOMSKODE,'
      '    MAX(POSTERINGER.ID) ID,'
      '    CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    (NOT(POSTERINGER.PostType = 8)) AND'
      '    POSTERINGER.Sortering = 40 AND'
      '    POSTERINGER.Belob <> 0'
      'GROUP BY'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    1,'
      '    POSTERINGER.KONTONR,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    9,'
      '    10,'
      '    11,'
      '    12,'
      '    13,'
      '    14,'
      '    15,'
      '    16,'
      '    17,'
      '    18,'
      '    3,'
      '    20'
      'HAVING'
      '    SUM(POSTERINGER.BELOB) <> 0'
      ''
      'UNION'
      ''
      '/* forskydning. Grouperet efter afdeling, dato, kontonr. */'
      'SELECT'
      ''
      '    POSTERINGER.DATO AS Dato,'
      '    POSTERINGER.KONTONR,'
      '    CAST('#39'Forskydning '#39' AS VARCHAR(60)) AS Tekst,'
      '    SUM(POSTERINGER.BELOB) Belob,'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    POSTERINGER.behandlet,'
      '    POSTERINGER.kontotype,'
      '    POSTERINGER.bilagsnr,'
      '    POSTERINGER.afdeling,'
      '    POSTERINGER.modkonto,'
      '    POSTERINGER.modbilag,'
      '    POSTERINGER.valuta,'
      '    POSTERINGER.valutakode,'
      '    POSTERINGER.uafd_grp_navn,'
      '    POSTERINGER.MOMSKODE,'
      '    MAX(POSTERINGER.ID) ID,'
      '    CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    POSTERINGER.PostType = 8 AND'
      '    POSTERINGER.Sortering = 40 AND'
      '    POSTERINGER.Belob <> 0'
      'GROUP BY'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    1,'
      '    POSTERINGER.KONTONR,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    9,'
      '    10,'
      '    11,'
      '    12,'
      '    13,'
      '    14,'
      '    15,'
      '    16,'
      '    17,'
      '    18,'
      '    20'
      'HAVING'
      
        '    (SUM(POSTERINGER.BELOB) < -0.005 OR SUM(POSTERINGER.BELOB) >' +
        ' 0.005)'
      ''
      'UNION'
      ''
      '/* Diff. poster. Grouperet efter afdeling, dato, kontonr. */'
      'SELECT'
      ''
      '    POSTERINGER.DATO AS Dato,'
      '    POSTERINGER.KONTONR,'
      '    CAST('#39'Difference '#39' AS VARCHAR(60)) AS Tekst,'
      '    SUM(POSTERINGER.BELOB) Belob,'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    POSTERINGER.behandlet,'
      '    POSTERINGER.kontotype,'
      '    POSTERINGER.bilagsnr,'
      '    POSTERINGER.afdeling,'
      '    POSTERINGER.modkonto,'
      '    POSTERINGER.modbilag,'
      '    POSTERINGER.valuta,'
      '    POSTERINGER.valutakode,'
      '    POSTERINGER.uafd_grp_navn,'
      '    POSTERINGER.MOMSKODE,'
      '    MAX(POSTERINGER.ID) ID,'
      '    CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    POSTERINGER.PostType = 7 AND'
      '    POSTERINGER.Belob <> 0'
      'GROUP BY'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    1,'
      '    POSTERINGER.KONTONR,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    9,'
      '    10,'
      '    11,'
      '    12,'
      '    13,'
      '    14,'
      '    15,'
      '    16,'
      '    17,'
      '    18,'
      '    3,'
      '    20'
      'HAVING'
      '    SUM(POSTERINGER.BELOB) <> 0'
      ''
      'UNION'
      ''
      '/* Gavekort. */'
      'SELECT'
      ''
      '    POSTERINGER.DATO AS Dato,'
      '    POSTERINGER.KONTONR,'
      '    CAST(POSTERINGER.TEKST AS VARCHAR(60)) AS Tekst,'
      '    POSTERINGER.BELOB,'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    POSTERINGER.behandlet,'
      '    POSTERINGER.kontotype,'
      '    POSTERINGER.bilagsnr,'
      '    POSTERINGER.afdeling,'
      '    POSTERINGER.modkonto,'
      '    POSTERINGER.modbilag,'
      '    POSTERINGER.valuta,'
      '    POSTERINGER.valutakode,'
      '    POSTERINGER.uafd_grp_navn,'
      '    POSTERINGER.MOMSKODE,'
      '    POSTERINGER.ID,'
      '    (SELECT FIRST 1'
      '         INTERSOLVE_NUMBERS.INTERSOLVENUMMER'
      '     FROM INTERSOLVE_NUMBERS'
      '     WHERE'
      
        '         INTERSOLVE_NUMBERS.EASYPOSNUMMER = POSTERINGER.bilagsnr' +
        ' AND'
      '         INTERSOLVE_NUMBERS.TRANSACTIONTIME >= :PStartDato AND'
      
        '         INTERSOLVE_NUMBERS.TRANSACTIONTIME <= :PSlutDato) AS Bi' +
        'lagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    POSTERINGER.PostType = 23 AND'
      '    POSTERINGER.Belob <> 0'
      ''
      'UNION'
      ''
      '/* Tilgodesedler. */'
      'SELECT'
      ''
      '    POSTERINGER.DATO AS Dato,'
      '    POSTERINGER.KONTONR,'
      '    CAST(POSTERINGER.TEKST AS VARCHAR(60)) AS Tekst,'
      '    POSTERINGER.BELOB,'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    POSTERINGER.behandlet,'
      '    POSTERINGER.kontotype,'
      '    POSTERINGER.bilagsnr,'
      '    POSTERINGER.afdeling,'
      '    POSTERINGER.modkonto,'
      '    POSTERINGER.modbilag,'
      '    POSTERINGER.valuta,'
      '    POSTERINGER.valutakode,'
      '    POSTERINGER.uafd_grp_navn,'
      '    POSTERINGER.MOMSKODE,'
      '    POSTERINGER.ID,'
      '    CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    POSTERINGER.PostType = 22 AND'
      '    POSTERINGER.Belob <> 0'
      ''
      'UNION'
      ''
      '/* Int. Afd.salg.. Grouperet efter afdeling, dato, kontonr */'
      ''
      'SELECT'
      ''
      '    /*01*/ POSTERINGER.DATO AS Dato,'
      '    /*02*/ POSTERINGER.KONTONR,'
      '    /*03*/ CAST(MAX(POSTERINGER.Tekst) AS VARCHAR(60)) AS Tekst,'
      '    /*04*/ SUM(POSTERINGER.BELOB) Belob,'
      '    /*05*/ POSTERINGER.AFDELING_ID,'
      '    /*06*/ POSTERINGER.UAFD_NAVN,'
      '    /*07*/ POSTERINGER.POSTTYPE,'
      '    /*08*/ POSTERINGER.SORTERING,'
      '    /*09*/ POSTERINGER.behandlet,'
      '    /*10*/ POSTERINGER.kontotype,'
      '    /*11*/ MAX(POSTERINGER.bilagsnr) AS bilagsnr,'
      '    /*12*/ POSTERINGER.afdeling,'
      '    /*13*/ POSTERINGER.modkonto,'
      '    /*14*/ POSTERINGER.modbilag,'
      '    /*15*/ POSTERINGER.valuta,'
      '    /*16*/ POSTERINGER.valutakode,'
      '    /*17*/ POSTERINGER.uafd_grp_navn,'
      '    /*18*/ POSTERINGER.MOMSKODE,'
      '    /*19*/ MAX(POSTERINGER.ID) ID,'
      '    /*20*/ CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    POSTERINGER.PostType = 99 AND'
      '    POSTERINGER.Sortering <> 0 AND'
      '    POSTERINGER.Belob <> 0'
      'GROUP BY'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_NAVN,'
      '    1,'
      '    POSTERINGER.KONTONR,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING,'
      '    9,'
      '    10,'
      '    12,'
      '    13,'
      '    14,'
      '    15,'
      '    16,'
      '    17,'
      '    18,'
      '    20'
      'HAVING'
      '    SUM(POSTERINGER.BELOB) <> 0'
      ''
      'UNION'
      ''
      '/* Afgang til butik. Grouperet efter afdeling, dato, kontonr */'
      ''
      'SELECT'
      ''
      '    /*01*/ POSTERINGER.DATO AS Dato,'
      '    /*02*/ POSTERINGER.KONTONR,'
      '    /*03*/ CAST(POSTERINGER.TEKST AS VARCHAR(60)) AS Tekst,'
      '    /*04*/ POSTERINGER.BELOB AS Belob,'
      '    /*05*/ POSTERINGER.AFDELING_ID,'
      '    /*06*/ POSTERINGER.UAFD_NAVN,'
      '    /*07*/ POSTERINGER.POSTTYPE,'
      '    /*08*/ POSTERINGER.SORTERING,'
      '    /*09*/ POSTERINGER.behandlet,'
      '    /*10*/ POSTERINGER.kontotype,'
      '    /*11*/ POSTERINGER.bilagsnr AS bilagsnr,'
      '    /*12*/ POSTERINGER.afdeling,'
      '    /*13*/ POSTERINGER.modkonto,'
      '    /*14*/ POSTERINGER.modbilag,'
      '    /*15*/ POSTERINGER.valuta,'
      '    /*16*/ POSTERINGER.valutakode,'
      '    /*17*/ POSTERINGER.uafd_grp_navn,'
      '    /*18*/ POSTERINGER.MOMSKODE,'
      '    /*19*/ POSTERINGER.ID AS ID,'
      '    /*20*/ CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    POSTERINGER.PostType = 99 AND'
      '    POSTERINGER.Sortering = 0 AND'
      '    POSTERINGER.BELOB <> 0'
      ''
      'UNION'
      ''
      'SELECT'
      ''
      '    /*01*/ POSTERINGER.DATO AS Dato,'
      '    /*02*/ POSTERINGER.KONTONR,'
      '    /*03*/ CAST(POSTERINGER.TEKST AS VARCHAR(60)) AS Tekst,'
      '    /*04*/ POSTERINGER.BELOB,'
      '    /*05*/ POSTERINGER.AFDELING_ID,'
      '    /*06*/ POSTERINGER.UAFD_NAVN,'
      '    /*07*/ POSTERINGER.POSTTYPE,'
      '    /*08*/ POSTERINGER.SORTERING,'
      '    /*09*/ POSTERINGER.behandlet,'
      '    /*10*/ POSTERINGER.kontotype,'
      '    /*11*/ POSTERINGER.bilagsnr,'
      '    /*12*/ POSTERINGER.afdeling,'
      '    /*13*/ POSTERINGER.modkonto,'
      '    /*14*/ POSTERINGER.modbilag,'
      '    /*15*/ POSTERINGER.valuta,'
      '    /*16*/ POSTERINGER.valutakode,'
      '    /*17*/ POSTERINGER.uafd_grp_navn,'
      '    /*18*/ POSTERINGER.MOMSKODE,'
      '    /*18*/ POSTERINGER.ID,'
      '    /*20*/ CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2'
      'FROM Posteringer'
      'WHERE'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet = 0 AND'
      '    NOT((POSTERINGER.PostType = 7) OR /* Difference poster */'
      '    (POSTERINGER.POSTTYPE = 8) OR /*Forskydninger */'
      '    (POSTERINGER.PostType = 22) OR /*Gavekort*/'
      '    (POSTERINGER.PostType = 23) OR /*Tilgodesedler */'
      '    (POSTERINGER.PostType = 99) OR /*Int. afd. salg */'
      '    ((POSTERINGER.Sortering = 40) AND'
      '    (Posteringer.Posttype = 5)) OR /*Afregninger */'
      '    ((POSTERINGER.Sortering = 10) AND'
      '    (Posteringer.Posttype = 0)) /*Oms'#230'tning */'
      '    ) AND'
      '    POSTERINGER.Belob <> 0'
      ''
      'ORDER BY'
      '    1,'
      '    /* Dato uden tidspunkt */'
      '    5,'
      '    /* Afdeling*/'
      '    6,'
      '    /* Maskine*/'
      '    8,'
      '    /* Sortering*/'
      '    7,'
      '    /* Posttype*/'
      '    18 /* ID */')
    Left = 72
    Top = 463
    ParamData = <
      item
        Name = 'PSTARTDATO'
        ParamType = ptInput
      end
      item
        Name = 'PSLUTDATO'
        ParamType = ptInput
      end>
  end
  object QFinansTemp: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    Left = 72
    Top = 527
  end
  object GetNextTransactionIDToBC: TFDStoredProc
    Connection = dbMain
    Transaction = tnMain
    StoredProcName = 'GETNAVISION_TRANSID'
    Left = 336
    Top = 208
    ParamData = <
      item
        Position = 1
        Name = 'STEP'
        DataType = ftInteger
        ParamType = ptInput
      end
      item
        Position = 2
        Name = 'TRANSID'
        DataType = ftInteger
        ParamType = ptOutput
      end>
    object GetNextTransactionIDToBCTRANSID: TIntegerField
      FieldName = 'TRANSID'
      Origin = 'TRANSID'
    end
  end
  object QFetchItems: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    SQL.Strings = (
      'SELECT DISTINCT'
      '    v.VARENAVN1 AS Beskrivelse,'
      '    vfsd.VEJETKOSTPRISSTK AS Kostpris,'
      '    l.V509INDEX AS LeverandorKode,'
      '    t.VAREFRVSTRNR AS VareID,'
      '    v.MODEL AS Model,'
      '    vg.V509INDEX AS Varegruppe,'
      '    vfsd.SALGSPRISSTK AS Salgspris,'
      '    vv.FARVE_NAVN AS Farve,'
      '    vv.STOERRELSE_NAVN AS Storrelse,'
      '    vv.LAENGDE_NAVN AS Laengde,'
      '    vv.V509INDEX AS VariantID,'
      '    v.KATEGORI1 AS Country,'
      '    v.KATEGORI2 AS Weigth,'
      '    v.INTRASTAT'
      'FROM transaktioner t'
      '    INNER JOIN Varer v ON (V.PLU_NR = t.VAREFRVSTRNR)'
      
        '    INNER JOIN VareFrvStr_Detail vfsd ON (vfsd.VAREPLU_ID = t.VA' +
        'REFRVSTRNR AND'
      '          vfsd.FARVE_NAVN = t.FARVE_NAVN AND'
      '          vfsd.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND'
      '          vfsd.LAENGDE_NAVN = t.LAENGDE_NAVN AND'
      '          vfsd.afdeling_ID = :PAfdeling_ID)'
      
        '    INNER JOIN VareFrvStr vv ON (vv.VAREPLU_ID = t.VAREFRVSTRNR ' +
        'AND'
      '          vv.FARVE_NAVN = t.FARVE_NAVN AND'
      '          vv.STOERRELSE_NAVN = t.STOERRELSE_NAVN AND'
      '          vv.LAENGDE_NAVN = t.LAENGDE_NAVN AND'
      '          vv.EKSPORTERET = 0)'
      '    INNER JOIN leverandoerer l ON (l.NAVN = t.LEVNAVN)'
      '    INNER JOIN varegrupper vg ON (vg.NAVN = t.VAREGRPID)'
      'WHERE'
      '    t.dato >= :PStartDato AND'
      '    t.dato <= :PSlutDato AND'
      '    t.ART IN (0, 1, 11, 14)'
      'ORDER BY'
      '    4,'
      '    11  '
      #9)
    Left = 560
    Top = 408
    ParamData = <
      item
        Name = 'PAFDELING_ID'
        ParamType = ptInput
      end
      item
        Name = 'PSTARTDATO'
        ParamType = ptInput
      end
      item
        Name = 'PSLUTDATO'
        ParamType = ptInput
      end>
  end
  object QItemsTemp: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    Left = 552
    Top = 471
  end
  object QFetchSalesTransactions: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    SQL.Strings = (
      'select '
      '  tr.TRANSID as EpID, '
      '  tr.UAFD_NAVN as Kasse, '
      '  tr.KOSTPR as KostPris, '
      '  tr.Eksporteret, '
      '  tr.AFDELING_ID, '
      '  af.NAVISION_IDX as ButikID, '
      '  tr.SALGSTK as Antal, '
      '  vfs.V509INDEX as VariantID, '
      '  tr.BONNR as Bonnummer, '
      '  tr.VAREFRVSTRNR as VareID, '
      '  tr.SALGKR as Salgspris, '
      '  tr.MomsKr as MomsBelob, '
      '  tr.DATO as BogforingsDato '
      'from transaktioner tr '
      '  inner join afdeling af on (af.AFDELINGSNUMMER=tr.AFDELING_ID) '
      '  Inner join varefrvstr vfs on ( '
      
        '                                 vfs.VAREPLU_ID=tr.VAREFRVSTRNR ' +
        'and '
      
        '                                 vfs.FARVE_NAVN=tr.FARVE_NAVN an' +
        'd '
      
        '                                 vfs.STOERRELSE_NAVN=tr.STOERREL' +
        'SE_NAVN and '
      
        '                                 vfs.LAENGDE_NAVN=tr.LAENGDE_NAV' +
        'N '
      '                                ) '
      'where '
      '  tr.dato>=:PFromDate and '
      '  tr.dato<=:PToDate and '
      '  tr.art IN (0,1) '
      'Order by 1')
    Left = 304
    Top = 424
    ParamData = <
      item
        Name = 'PFROMDATE'
        ParamType = ptInput
      end
      item
        Name = 'PTODATE'
        ParamType = ptInput
      end>
  end
  object QSalesTransactionsTemp: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    Left = 296
    Top = 487
  end
  object INS_Sladre: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    SQL.Strings = (
      'Insert Into SladreHank ('
      '  Dato,'
      '  Art,'
      '  LevNavn,'
      '  Ekspedient,'
      '  VareFrvStrNr,'
      '  VareGrpId,'
      '  BonText,'
      '  Afdeling_ID,'
      '  UAfd_Navn,'
      '  UAfd_Grp_Navn'
      ')'
      'Values ('
      '  :PDato,'
      '  :PArt,'
      '  :PLevNavn,'
      '  :PEkspedient,'
      '  :PVareFrvStrNr,'
      '  :PVareGrpId,'
      '  :PBonText,'
      '  :PAfdeling_ID,'
      '  :PUAfd_Navn,'
      '  :PUAfd_Grp_Navn'
      ');')
    Left = 336
    Top = 88
    ParamData = <
      item
        Name = 'PDATO'
        ParamType = ptInput
      end
      item
        Name = 'PART'
        ParamType = ptInput
      end
      item
        Name = 'PLEVNAVN'
        ParamType = ptInput
      end
      item
        Name = 'PEKSPEDIENT'
        ParamType = ptInput
      end
      item
        Name = 'PVAREFRVSTRNR'
        ParamType = ptInput
      end
      item
        Name = 'PVAREGRPID'
        ParamType = ptInput
      end
      item
        Name = 'PBONTEXT'
        ParamType = ptInput
      end
      item
        Name = 'PAFDELING_ID'
        ParamType = ptInput
      end
      item
        Name = 'PUAFD_NAVN'
        ParamType = ptInput
      end
      item
        Name = 'PUAFD_GRP_NAVN'
        ParamType = ptInput
      end>
  end
end
