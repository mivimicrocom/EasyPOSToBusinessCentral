unit uEventLogger;
// http://edn.embarcadero.com/article/40404

interface

uses
  Windows;

const
  SDefaultSource = 'EasyPOS Program.';

function WriteEventLog(AEntry: string;
  AServer: string = '';
  ASource: string = SDefaultSource;
  AEventType: word = EVENTLOG_INFORMATION_TYPE;
  AEventId: word = 0;
  AEventCategory: word = 0): boolean;

implementation

// TEventLogger is not used because the current RTL supports only local servers
function WriteEventLog(AEntry: string;
  AServer: string = '';
  ASource: string = SDefaultSource;
  AEventType: word = EVENTLOG_INFORMATION_TYPE;
  AEventId: word = 0;
  AEventCategory: word = 0): boolean;
var
  EventLog: integer;
  P: Pointer;
begin
  Result := False;
  P := PWideChar(AEntry);
  if Length(AServer) = 0 then // Write to the local machine
    EventLog := RegisterEventSource(nil, PWideChar(ASource))
  else // Write to a remote machine
    EventLog := RegisterEventSource(PWideChar(AServer), PWideChar(ASource));
  if EventLog <> 0 then
    try
      ReportEvent(EventLog, // event log handle
        AEventType, // event type
        AEventCategory, // category zero
        AEventId, // event identifier
        nil, // no user security identifier
        1, // one substitution string
        0, // no data
        @P, // pointer to string array
        nil); // pointer to data
      Result := True;
    finally
      DeregisterEventSource(EventLog);
    end;
end;

end.
