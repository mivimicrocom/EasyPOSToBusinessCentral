object Service2: TService2
  OldCreateOrder = False
  DisplayName = 'Service2'
  AfterInstall = ServiceAfterInstall
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 749
  Width = 1067
end
