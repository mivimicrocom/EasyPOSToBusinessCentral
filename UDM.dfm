object DM: TDM
  Height = 848
  Width = 1148
  object tiTimer: TTimer
    Enabled = False
    OnTimer = tiTimerTimer
    Left = 392
    Top = 456
  end
  object dbMain: TFDConnection
    Params.Strings = (
      'SQLDialect=1'
      'DriverID=FB'
      'User_Name=sysdba'
      'Password=masterkey')
    TxOptions.AutoStop = False
    Left = 312
    Top = 232
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    VendorLib = '.\fbclient.dll'
    Left = 129
    Top = 102
  end
  object trnMain: TFDTransaction
    Options.AutoStop = False
    Connection = dbMain
    Left = 176
    Top = 298
  end
  object qryFetchData: TFDQuery
    Connection = dbMain
    FetchOptions.AssignedValues = [evAutoFetchAll]
    FetchOptions.AutoFetchAll = afDisable
    SQL.Strings = (
      'select * from {id Categories}')
    Left = 264
    Top = 159
  end
end
