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
    Options.AutoStart = False
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
      'SELECT'
      '    POSTERINGER.AFDELING_ID,'
      '    POSTERINGER.UAFD_GRP_NAVN,'
      '    POSTERINGER.UAFD_NAVN,'
      '    POSTERINGER.DATO,'
      '    POSTERINGER.ID,'
      '    POSTERINGER.BEHANDLET,'
      '    POSTERINGER.KONTOTYPE,'
      '    POSTERINGER.KONTONR,'
      '    POSTERINGER.BILAGSNR,'
      '    CAST('#39#39' AS VARCHAR(30)) AS BilagsNr2,'
      '    POSTERINGER.AFDELING,'
      '    POSTERINGER.MODKONTO,'
      '    POSTERINGER.TEKST,'
      '    POSTERINGER.BELOB,'
      '    POSTERINGER.MOMSKODE,'
      '    POSTERINGER.MODBILAG,'
      '    POSTERINGER.VALUTA,'
      '    POSTERINGER.VALUTAKODE,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING'
      'FROM POSTERINGER'
      'WHERE'
      '    POSTERINGER.belob <> 0 AND'
      '    POSTERINGER.Dato >= :PStartDato AND'
      '    POSTERINGER.Dato <= :PSlutDato AND'
      '    POSTERINGER.Behandlet >= 0'
      'ORDER BY'
      '    POSTERINGER.afdeling_ID,'
      '    POSTERINGER.Dato,'
      '    POSTERINGER.PostType  ')
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
    Left = 280
    Top = 192
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
    Left = 208
    Top = 432
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
    Left = 200
    Top = 495
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
      '  and (tr.EKSPORTERET=0 or tr.EKSPORTERET IS null)'
      'Order by 1')
    Left = 920
    Top = 240
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
    Left = 912
    Top = 303
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
  object QFetchMovementsTransactions: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    SQL.Strings = (
      'SELECT'
      '    tr.Eksporteret,'
      '    tr.TransID AS EPID,'
      '    tr.BONNR AS FlytningsID,'
      '    tr.dato AS Bogforingsdato,'
      '    tr.TILBUTIK AS TilButik2,'
      '    (SELECT'
      '         NAVISION_IDX'
      '     FROM afdeling'
      '     WHERE'
      '         afdelingsnummer = TR.TILBUTIK) AS TIlButik,'
      '    tr.AFDELING_ID AS FraButik2,'
      '    af.NAVISION_IDX AS FraButik,'
      '    tr.VAREFRVSTRNR AS VareID,'
      '    vfs.V509INDEX AS VariantID,'
      '    tr.SalgStk AS Antal,'
      '    tr.KostPr AS KostPris'
      'FROM TRansaktioner tr'
      
        '    INNER JOIN afdeling af ON (af.AFDELINGSNUMMER = tr.AFDELING_' +
        'ID)'
      
        '    LEFT JOIN varefrvstr vfs ON (vfs.VAREPLU_ID = tr.VAREFRVSTRN' +
        'R AND'
      '          vfs.FARVE_NAVN = tr.FARVE_NAVN AND'
      '          vfs.STOERRELSE_NAVN = tr.STOERRELSE_NAVN AND'
      '          vfs.LAENGDE_NAVN = tr.LAENGDE_NAVN)'
      'WHERE'
      '    tr.dato >= :PFromDate AND'
      '    tr.dato <= :PToDate AND'
      '    tr.art IN (14) AND'
      '    tr.Pakkelinje IN (1, 5) /*Kun afgange*/'
      'ORDER BY'
      '    1  ')
    Left = 768
    Top = 312
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
  object QMovementsTransactionsTemp: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    Left = 760
    Top = 375
  end
  object QFetchStockRegulationsTransactions: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    SQL.Strings = (
      'SELECT'
      '    TR.DATO AS Bogforingsdato,'
      '    Afd.NAVISION_IDX AS ButikID,'
      '    tr.BONNR AS LagerTilgangsNummer,'
      '    tr.LEVNAVN,'
      '    (SELECT'
      '         l.V509INDEX'
      '     FROM leverandoerer l'
      '     WHERE'
      '         l.navn = tr.levnavn) AS LeverandorKode,'
      '    (SELECT'
      '         l.Navn'
      '     FROM leverandoerer l'
      '     WHERE'
      '         l.navn = tr.levnavn) AS LeverandorNavn,'
      '    tr.Eksporteret,'
      '    SUM(tr.KostPr) AS Belob'
      'FROM Transaktioner tr'
      
        '    INNER JOIN Afdeling Afd ON (Afd.AFDELINGSNUMMER = tr.AFDELIN' +
        'G_ID)'
      'WHERE'
      '    tr.dato >= :PFromDate AND'
      '    tr.art = 11 AND'
      '    tr.dato <= :PToDate AND'
      '    (tr.EKSPORTERET = 0 OR tr.EKSPORTERET IS NULL)'
      'GROUP BY'
      '    5,'
      '    6,'
      '    4,'
      '    3,'
      '    2,'
      '    1,'
      '    7'
      'ORDER BY'
      '    1,'
      '    3  ')
    Left = 568
    Top = 360
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
  object QStockRegulationsTransationsTemp: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    Left = 560
    Top = 423
  end
  object QSetEksportedValueOnSaleTrans: TFDQuery
    Connection = dbMain
    Transaction = trSetEksportedValueOnSaleTrans
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
    Left = 1000
    Top = 400
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
  object trSetEksportedValueOnSaleTrans: TFDTransaction
    Options.AutoStop = False
    Connection = dbMain
    Left = 1016
    Top = 474
  end
  object QSetEksportedValueOnMovementsTrans: TFDQuery
    Connection = dbMain
    Transaction = trSetEksportedValueOnMovementsTrans
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
    Left = 792
    Top = 496
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
  object trSetEksportedValueOnMovementsTrans: TFDTransaction
    Options.AutoStop = False
    Connection = dbMain
    Left = 808
    Top = 570
  end
  object QSetEksportedValueOnStockTrans: TFDQuery
    Connection = dbMain
    Transaction = trSetEksportedValueOnStockTrans
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
    Left = 528
    Top = 576
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
  object trSetEksportedValueOnStockTrans: TFDTransaction
    Options.AutoStop = False
    Connection = dbMain
    Left = 544
    Top = 650
  end
  object QSetEksportedValueOnFinancialTrans: TFDQuery
    Connection = dbMain
    Transaction = trSetEksportedValueOnFinancialTrans
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
    Left = 192
    Top = 592
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
  object trSetEksportedValueOnFinancialTrans: TFDTransaction
    Options.AutoStart = False
    Options.AutoStop = False
    Connection = dbMain
    Left = 208
    Top = 666
  end
end
