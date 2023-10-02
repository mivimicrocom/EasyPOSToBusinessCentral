unit uSendEMail;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  vcl.dialogs,
  IdIOHandler,
  IdIOHandlerSocket,
  IdIOHandlerStack,
  IdSSL,
  IdSSLOpenSSL,
  IdExplicitTLSClientServerBase,
  IdMessageClient,
  IdMessage,
  IdAttachmentFile,
  IdSMTPBase,
  IdSMTP,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  IdHTTP,
  IdBaseComponent,
  IdSASL,
  IdSASLUserPass,
  IdSASLLogin,
  IdUserPassProvider,
  IdSASLAnonymous,
  IdSASLDigest,
  IdSASLOTP,
  IdSASLPlain,
  IdSASL_CRAMBase,
  IdSASL_CRAM_MD5,
  IdSASL_CRAM_SHA1,
  IdSASLSKey;

type
  TSendEMailSMTPSetup = class(TComponent)
  private
    FSMTPServer: string;
    FSMTPPort: integer;
    FSMTPUsername: string;
    FSMTPPassword: string;
    FUseTLS: boolean;
    { private declarations }
  public
    { public declarations }
    property SMTPServer: string read FSMTPServer write FSMTPServer;
    property SMTPPort: integer read FSMTPPort write FSMTPPort;
    property SMTPUsername: string read FSMTPUsername write FSMTPUsername;
    property SMTPPassword: string read FSMTPPassword write FSMTPPassword;
    property UseTLS: boolean read FUseTLS write FUseTLS;
  end;

  TSendEMailMailSetup = class(TComponent)
  private
    FReceivingEMail: string;
    FReplyToEMail: string;
    FReplyToName: string;
    FSenderEMail: string;
    FSenderName: string;
    FEmailSubject: string;
    FEmailContent: Tstrings;
    FAttachment: string;
    FSendCopyToself: boolean;
    FUseMicrocomMailServer: boolean;
    { private declarations }
  public
    { public declarations }
    property ReceivingEMail: string read FReceivingEMail write FReceivingEMail;
    property ReplyToEMail: string read FReplyToEMail write FReplyToEMail;
    property ReplyToName: string read FReplyToName write FReplyToName;
    property SenderEMail: string read FSenderEMail write FSenderEMail;
    property SenderName: string read FSenderName write FSenderName;
    property EmailSubject: string read FEmailSubject write FEmailSubject;
    property EmailContent: Tstrings read FEmailContent write FEmailContent;
    property Attachment: string read FAttachment write FAttachment;
    property SendCopyToself: boolean read FSendCopyToself write FSendCopyToself;
    property UseMicrocomMailServer: boolean read FUseMicrocomMailServer write FUseMicrocomMailServer;
  end;

  TSendEMail = class
  private
    FSMTP: TIdSMTP;
    FMSG: TIdMessage;
    FUserPassProvider: TIdUserPassProvider;
    FSMTPSetup: TSendEMailSMTPSetup;
    FMailSetup: TSendEMailMailSetup;
    { private declarations }
    procedure AddSslHandler(var aSMTP: TIdSMTP; aSMTPSetup: TSendEMailSMTPSetup);
    procedure CreateMail(var aMSG: TIdMessage; aMailSetup: TSendEMailMailSetup);
  public
    { public declarations }
    constructor Create(aSMTPSetup: TSendEMailSMTPSetup);
    destructor Destroy; override;
    function SendEMail(aMail: TSendEMailMailSetup; var lErrorReturnString: String): boolean;
  end;

implementation

{ TSendEMail }

uses
  UDM;

procedure TSendEMail.AddSslHandler(var aSMTP: TIdSMTP; aSMTPSetup: TSendEMailSMTPSetup);
var
  SASLAnonymous: TIdSASLAnonymous;
  SASLDigest: TIdSASLDigest;
  SASLLogin: TIdSASLLogin;
  SASLOTP: TIdSASLOTP;
  SASLMD5: TIdSASLCRAMMD5;
  SASLPlain: TIdSASLPlain;
  SASLSHA1: TIdSASLCRAMSHA1;
  SASLSkey: TIdSASLSKey;
  // UserPassProvider: TIdUserPassProvider;
begin
  aSMTP.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(aSMTP);
  TIdSSLIOHandlerSocketOpenSSL(aSMTP.IOHandler).SSLOptions.Method := sslvTLSv1_2;

  TIdSSLIOHandlerSocketOpenSSL(aSMTP.IOHandler).Destination := aSMTPSetup.SMTPServer + ':' + IntToStr(aSMTPSetup.SMTPPort);
  TIdSSLIOHandlerSocketOpenSSL(aSMTP.IOHandler).Port := aSMTPSetup.SMTPPort;
  TIdSSLIOHandlerSocketOpenSSL(aSMTP.IOHandler).Host := aSMTPSetup.SMTPServer;
  TIdSSLIOHandlerSocketOpenSSL(aSMTP.IOHandler).SSLOptions.Mode := sslmUnassigned;
  TIdSSLIOHandlerSocketOpenSSL(aSMTP.IOHandler).SSLOptions.VerifyMode := [];
  TIdSSLIOHandlerSocketOpenSSL(aSMTP.IOHandler).SSLOptions.VerifyDepth := 0;

  aSMTP.UseTLS := utUseExplicitTLS;
  // When we explicitly assign the port, we just get connection timeouts...
  // aSMTP.Port := 587;

  // This needs to be true, so that TIdSMTP can decide which SASL to use,
  // from the ones provided below.
  // (https://stackoverflow.com/questions/17734414/using-indy-10-smtp-with-office365)
  aSMTP.UseEhlo := True;

  aSMTP.Username := aSMTPSetup.SMTPUsername;
  aSMTP.Password := aSMTPSetup.SMTPPassword;
  aSMTP.AuthType := satSASL;

  // SASL mechanisms are declared and added in descending order of security
  // (as far as that can be known -- not all units give a value for FSecurityLevel).
  SASLOTP := TIdSASLOTP.Create(aSMTP);
  SASLOTP.UserPassProvider := FUserPassProvider;
  aSMTP.SASLMechanisms.Add.SASL := SASLOTP;

  SASLSkey := TIdSASLSKey.Create(aSMTP);
  SASLSkey.UserPassProvider := FUserPassProvider;
  aSMTP.SASLMechanisms.Add.SASL := SASLSkey;

  SASLSHA1 := TIdSASLCRAMSHA1.Create(aSMTP);
  SASLSHA1.UserPassProvider := FUserPassProvider;
  aSMTP.SASLMechanisms.Add.SASL := SASLSHA1;

  SASLMD5 := TIdSASLCRAMMD5.Create(aSMTP);
  SASLMD5.UserPassProvider := FUserPassProvider;
  aSMTP.SASLMechanisms.Add.SASL := SASLMD5;

  SASLLogin := TIdSASLLogin.Create(aSMTP);
  SASLLogin.UserPassProvider := FUserPassProvider;
  aSMTP.SASLMechanisms.Add.SASL := SASLLogin;

  SASLDigest := TIdSASLDigest.Create(aSMTP);
  SASLDigest.UserPassProvider := FUserPassProvider;
  aSMTP.SASLMechanisms.Add.SASL := SASLDigest;

  SASLPlain := TIdSASLPlain.Create(aSMTP);
  SASLPlain.UserPassProvider := FUserPassProvider;
  aSMTP.SASLMechanisms.Add.SASL := SASLPlain;

  // (least secure)
  SASLAnonymous := TIdSASLAnonymous.Create(aSMTP);
  aSMTP.SASLMechanisms.Add.SASL := SASLAnonymous;

  aSMTP.ValidateAuthLoginCapability := False;
end;

procedure TSendEMail.CreateMail(var aMSG: TIdMessage; aMailSetup: TSendEMailMailSetup);
begin
  aMSG.MessageParts.Clear;

  aMSG.Date := NOW;

  aMSG.From.Address := aMailSetup.SenderEMail;
  if aMailSetup.UseMicrocomMailServer then
    aMSG.From.Name := aMailSetup.ReplyToName + ' på vegne af ' + aMailSetup.SenderName
  else
  begin
    aMSG.From.Name := aMailSetup.SenderName;
  end;
  aMSG.ReplyTo.Add;
  aMSG.ReplyTo[0].Name := aMailSetup.ReplyToName;
  aMSG.ReplyTo[0].Address := aMailSetup.ReplyToEMail;
  aMSG.Recipients.EMailAddresses := aMailSetup.ReceivingEMail;

  aMSG.Subject := aMailSetup.EmailSubject;

  aMSG.Body := aMailSetup.EmailContent;

  if (TRIM(aMailSetup.Attachment) <> '') then
    TIdAttachmentFile.Create(aMSG.MessageParts, aMailSetup.Attachment);

end;

constructor TSendEMail.Create(aSMTPSetup: TSendEMailSMTPSetup);
begin
  FSMTPSetup := aSMTPSetup;

  FUserPassProvider := TIdUserPassProvider.Create;
  FUserPassProvider.Username := FSMTPSetup.FSMTPUsername;
  FUserPassProvider.Password := FSMTPSetup.FSMTPPassword;
end;

destructor TSendEMail.Destroy;
begin
  FUserPassProvider.Free;
  inherited;
end;

function TSendEMail.SendEMail(aMail: TSendEMailMailSetup; var lErrorReturnString: String): boolean;
begin
  FMailSetup := aMail;
  DM.AddToLog('      TIdSMTP.Create');
  FSMTP := TIdSMTP.Create(nil);
  try
    DM.AddToLog('      TIdMessage.Create');
    FMSG := TIdMessage.Create(nil);
    try
      DM.AddToLog('      CreateMail(FMSG, FMailSetup)');
      CreateMail(FMSG, FMailSetup);
      if FSMTPSetup.UseTLS then
      begin
        DM.AddToLog('      AddSslHandler(FSMTP, FSMTPSetup)');
        AddSslHandler(FSMTP, FSMTPSetup);
      end;
      try

        FSMTP.Host := FSMTPSetup.FSMTPServer;
        FSMTP.Username := FSMTPSetup.FSMTPUsername;
        FSMTP.Password := FSMTPSetup.FSMTPPassword;
        FSMTP.Port := FSMTPSetup.FSMTPPort;
        if FSMTPSetup.UseTLS then
          FSMTP.UseTLS := utUseExplicitTLS;

        DM.AddToLog('      FSMTP.Connect');
        FSMTP.Connect;
        If (FSMTP.Connected) Then
        Begin
          DM.AddToLog('      FSMTP.Authenticate');
          FSMTP.Authenticate;

          DM.AddToLog('      FSMTP.Send(FMSG)');
          FSMTP.Send(FMSG);

          FSMTP.Disconnect;
        End;
        lErrorReturnString := '';
        Result := True;
      except
        on E: Exception do
        begin
          DM.AddToLog(Format('      Error: %s',[E.Message]));
          Result := False;
          lErrorReturnString := E.Message;
          FSMTP.Disconnect;
        end;
      end;
    finally
      FMSG.Free;
    end;
  finally
    FSMTP.Free;
  end;
end;

end.
