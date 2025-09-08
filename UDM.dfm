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
    TxOptions.AutoStart = False
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
    Options.Isolation = xiReadCommitted
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
      '    CAST('#39#39' AS VARCHAR(30)) AS BILAGSNR2,'
      '    POSTERINGER.AFDELING,'
      '    POSTERINGER.MODKONTO,'
      '    CASE WHEN POSTERINGER.VALUTA = 0 THEN'
      '        POSTERINGER.TEKST'
      
        '      ELSE POSTERINGER.TEKST || '#39' ('#39' || ROUND((POSTERINGER.BELOB' +
        ' / POSTERINGER.VALUTA) * 100, 2) || '#39')'#39
      '    END AS TEKST,'
      '    POSTERINGER.BELOB,'
      '    POSTERINGER.MOMSKODE,'
      '    POSTERINGER.MODBILAG,'
      '    POSTERINGER.VALUTA,'
      '    POSTERINGER.VALUTAKODE,'
      '    POSTERINGER.POSTTYPE,'
      '    POSTERINGER.SORTERING'
      'FROM POSTERINGER'
      'WHERE'
      '    POSTERINGER.BELOB <> 0'
      '    AND POSTERINGER.DATO >= :PSTARTDATO'
      '    AND POSTERINGER.DATO <= :PSLUTDATO'
      '    AND POSTERINGER.BEHANDLET = 0'
      '    AND CHAR_LENGTH(POSTERINGER.AFDELING_ID) = 3'
      'ORDER BY'
      '    POSTERINGER.DATO ASC  ')
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
      'SELECT'
      '    TR.TRANSID AS EPID,'
      '    TR.UAFD_NAVN AS KASSE,'
      '    TR.KOSTPR AS KOSTPRIS,'
      '    TR.EKSPORTERET,'
      '    TR.AFDELING_ID,'
      '    AF.NAVISION_IDX AS BUTIKID,'
      '    TR.SALGSTK AS ANTAL,'
      '    VFS.V509INDEX AS VARIANTID,'
      '    TR.BONNR AS BONNUMMER,'
      '    TR.VAREFRVSTRNR AS VAREID,'
      '    TR.SALGKR AS SALGSPRIS,'
      '    TR.MOMSKR AS MOMSBELOB,'
      '    TR.DATO AS BOGFORINGSDATO'
      'FROM TRANSAKTIONER TR'
      '    INNER JOIN AFDELING AF ON'
      '          (AF.AFDELINGSNUMMER = TR.AFDELING_ID)'
      '    INNER JOIN VAREFRVSTR VFS ON'
      '          (VFS.VAREPLU_ID = TR.VAREFRVSTRNR'
      '          AND VFS.FARVE_NAVN = TR.FARVE_NAVN'
      '          AND VFS.STOERRELSE_NAVN = TR.STOERRELSE_NAVN'
      '          AND VFS.LAENGDE_NAVN = TR.LAENGDE_NAVN)'
      'WHERE'
      '    TR.DATO >= :PFROMDATE'
      '    AND TR.DATO <= :PTODATE'
      '    AND TR.ART IN (0, 1)'
      '    AND (TR.EKSPORTERET = 0 OR TR.EKSPORTERET IS NULL)'
      'ORDER BY'
      '    TR.DATO ASC')
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
      '    TR.EKSPORTERET,'
      '    TR.TRANSID AS EPID,'
      '    TR.BONNR AS FLYTNINGSID,'
      '    TR.DATO AS BOGFORINGSDATO,'
      '    TR.TILBUTIK AS TILBUTIK2,'
      '    (SELECT'
      '         NAVISION_IDX'
      '     FROM AFDELING'
      '     WHERE'
      '         AFDELINGSNUMMER = TR.TILBUTIK) AS TILBUTIK,'
      '    TR.AFDELING_ID AS FRABUTIK2,'
      '    AF.NAVISION_IDX AS FRABUTIK,'
      '    TR.VAREFRVSTRNR AS VAREID,'
      '    VFS.V509INDEX AS VARIANTID,'
      '    TR.SALGSTK AS ANTAL,'
      '    TR.KOSTPR AS KOSTPRIS'
      'FROM TRANSAKTIONER TR'
      '    INNER JOIN AFDELING AF ON'
      '          (AF.AFDELINGSNUMMER = TR.AFDELING_ID)'
      '    LEFT JOIN VAREFRVSTR VFS ON'
      '          (VFS.VAREPLU_ID = TR.VAREFRVSTRNR'
      '          AND VFS.FARVE_NAVN = TR.FARVE_NAVN'
      '          AND VFS.STOERRELSE_NAVN = TR.STOERRELSE_NAVN'
      '          AND VFS.LAENGDE_NAVN = TR.LAENGDE_NAVN)'
      'WHERE'
      '    TR.DATO >= :PFROMDATE'
      '    AND TR.DATO <= :PTODATE'
      '    AND TR.ART IN (14)'
      '    AND TR.PAKKELINJE IN (1, 5) /*Kun afgange*/'
      '    AND (TR.EKSPORTERET = 0 OR TR.EKSPORTERET IS NULL)'
      'ORDER BY'
      '    TR.DATO ASC  ')
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
    Options.Isolation = xiReadCommitted
    Options.AutoStart = False
    Options.AutoStop = False
    Connection = dbMain
    Left = 208
    Top = 666
  end
  object QFetchItemsUpdateCostprice: TFDQuery
    Connection = dbMain
    Transaction = tnMain
    SQL.Strings = (
      'SELECT'
      '    V.PLU_NR,'
      '    (SELECT'
      '         COUNT(*)'
      '     FROM VAREFRVSTR VV'
      '     WHERE'
      '         VV.VAREPLU_ID = V.PLU_NR) AS ANTALVV'
      'FROM VARER V'
      'WHERE'
      '    V.UPDATE_FROM_BC > 0'
      'ORDER BY'
      '    V.ANTAL_DETALJER DESC  ')
    Left = 280
    Top = 344
  end
  object trUpdateCostprice: TFDTransaction
    Options.Isolation = xiReadCommitted
    Options.AutoStart = False
    Options.AutoStop = False
    Options.StopOptions = [xoIfCmdsInactive]
    Connection = dbMain
    Left = 496
    Top = 146
  end
  object qUpdateCostprice: TFDQuery
    Connection = dbMain
    Transaction = trUpdateCostprice
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    Left = 544
    Top = 231
  end
  object qDepartmentsAndCurrency: TFDQuery
    Connection = dbMain
    Transaction = trUpdateCostprice
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    SQL.Strings = (
      'SELECT'
      '    AFDELING.AFDELINGSNUMMER,'
      '    STAMDATA_PRG_EXT.STDVALUTA,'
      '    VALUTA.TEKST,'
      '    VALUTALINIER.KURS'
      'FROM AFDELING'
      '    INNER JOIN STAMDATA_PRG_EXT ON'
      
        '          STAMDATA_PRG_EXT.AFDELING_ID = AFDELING.AFDELINGSNUMME' +
        'R'
      '    INNER JOIN VALUTA ON'
      '          VALUTA.TEKST = STAMDATA_PRG_EXT.STDVALUTA'
      '    INNER JOIN VALUTALINIER ON'
      '          VALUTALINIER.VALUTA_TEKST = VALUTA.TEKST'
      'ORDER BY'
      '    AFDELING.AFDELINGSNUMMER ASC  ')
    Left = 656
    Top = 135
  end
  object qFetchVariant: TFDQuery
    Connection = dbMain
    Transaction = trUpdateCostprice
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    SQL.Strings = (
      'SELECT'
      '    VAREFRVSTR_DETAIL.ANTALSTK,'
      '    VAREFRVSTR_DETAIL.FARVE_NAVN,'
      '    VAREFRVSTR_DETAIL.LAENGDE_NAVN,'
      '    VAREFRVSTR_DETAIL.STOERRELSE_NAVN,'
      '    VAREFRVSTR_DETAIL.BEH_KOSTPRIS,'
      '    VAREFRVSTR_DETAIL.SALGSPRISSTK,'
      '    VAREFRVSTR_DETAIL.VEJETKOSTPRISSTK'
      'FROM VAREFRVSTR_DETAIL'
      'WHERE'
      '    VAREFRVSTR_DETAIL.V509INDEX = :PV509INDEX'
      '    AND VAREFRVSTR_DETAIL.AFDELING_ID = :PAFDELING_ID   ')
    Left = 648
    Top = 215
    ParamData = <
      item
        Name = 'PV509INDEX'
        ParamType = ptInput
      end
      item
        Name = 'PAFDELING_ID'
        ParamType = ptInput
      end>
  end
  object qDoRegulation: TFDQuery
    Connection = dbMain
    Transaction = trUpdateCostprice
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    Left = 480
    Top = 303
  end
  object INS_WEBLogEasyPOS: TFDQuery
    Connection = dbMain
    Transaction = trUpdateCostprice
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    SQL.Strings = (
      'INSERT INTO WEB_SLADREHANK ('
      '    HVAD,'
      '    HVEM,'
      '    HVOR,'
      '    DATO_STEMPEL,'
      '    SQLSETNING)'
      'VALUES ('
      '    :HVAD,'
      '    :HVEM,'
      '    :HVOR,'
      '    :DATO_STEMPEL,'
      '    :SQLSETNING);')
    Left = 552
    Top = 80
    ParamData = <
      item
        Name = 'HVAD'
        ParamType = ptInput
      end
      item
        Name = 'HVEM'
        ParamType = ptInput
      end
      item
        Name = 'HVOR'
        ParamType = ptInput
      end
      item
        Name = 'DATO_STEMPEL'
        ParamType = ptInput
      end
      item
        Name = 'SQLSETNING'
        ParamType = ptInput
      end>
  end
  object UpdItem: TFDQuery
    ObjectView = False
    Connection = dbMain
    Transaction = trUpdateItem
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    Left = 344
    Top = 487
  end
  object trUpdateItem: TFDTransaction
    Options.Isolation = xiReadCommitted
    Options.AutoStart = False
    Options.AutoStop = False
    Connection = dbMain
    Left = 336
    Top = 426
  end
end
