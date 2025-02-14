unit HttpConnectionNetHttp;

interface

uses
  System.Classes,
  Generics.Collections,
  HttpConnection,
  System.Net.Mime,
  System.Net.URLClient,
  System.Net.HttpClient;

type
  TMethod = (mGET, mPOST, mPUT, mPATCH, mDELETE);

  THttpConnectionNetHttp = class(TInterfacedObject, IHttpConnection)
  private
    FResponse: IHTTPResponse;
    FAsynchronous: Boolean;
    FVerifyCert: Boolean;
    FCanceled: Boolean;
    FHeaders: TStrings;
    FAcceptTypes: string;
    FAcceptedLanguages: string;
    FContentTypes: string;
    FConnectionTimeout: Integer;
    FSendTimeout: Integer;
    FResponseTimeout: Integer;
    FOnConnectionLost: THTTPConnectionLostEvent;
    FOnAsyncRequestProcess: TAsyncRequestProcessEvent;
    FProxyCredentials: TProxyCredentials;

    function IsRetryableError(Error: ENetHTTPClientException): Boolean;
    function DoSyncRequest(AHTTPClient: THTTPClient; AMethod: TMethod; const AURL: string; AContent, AResponse: TStream): IHTTPResponse;
    function DoASyncRequest(AHTTPClient: THTTPClient; AMethod: TMethod; const AURL: string; AContent, AResponse: TStream): IHTTPResponse;
    procedure DoRequest(AMethod: TMethod; const AURL: string; AContent, AResponse: TStream);
  public
    constructor Create;
    destructor Destroy; override;

    function SetAcceptTypes(AAcceptTypes: string): IHttpConnection;
    function SetContentTypes(AContentTypes: string): IHttpConnection;
    function SetAcceptedLanguages(AAcceptedLanguages: string): IHttpConnection;
    function SetHeaders(AHeaders: TStrings): IHttpConnection;
    function ConfigureTimeout(const ATimeout: TTimeOut): IHttpConnection;
    function ConfigureProxyCredentials(AProxyCredentials: TProxyCredentials): IHttpConnection;
    function SetOnAsyncRequestProcess(const Value: TAsyncRequestProcessEvent): IHttpConnection;

    procedure Get(AUrl: string; AResponse: TStream);
    procedure Post(AUrl: string; AContent, AResponse: TStream);
    procedure Put(AUrl: string; AContent, AResponse: TStream);
    procedure Patch(AUrl: string; AContent, AResponse: TStream);
    procedure Delete(AUrl: string; AContent, AResponse: TStream);

    function GetResponseCode: Integer;
    function GetResponseHeader(const Header: string): string;
    function GetEnabledCompression: Boolean;
    function GetVerifyCert: Boolean;

    procedure SetEnabledCompression(const Value: Boolean);
    procedure SetVerifyCert(const Value: boolean);

    function SetAsync(const Value: Boolean): IHttpConnection;
    procedure CancelRequest;

    property ResponseCode: Integer read GetResponseCode;
    property ResponseHeader[const Header: string]: string read GetResponseHeader;
    property EnabledCompression: Boolean read GetEnabledCompression write SetEnabledCompression;
    property VerifyCert: boolean read GetVerifyCert write SetVerifyCert;

    function GetOnConnectionLost: THTTPConnectionLostEvent;
    procedure SetOnConnectionLost(AConnectionLostEvent: THTTPConnectionLostEvent);
    property OnConnectionLost: THTTPConnectionLostEvent read GetOnConnectionLost write SetOnConnectionLost;
  end;


implementation

uses
  ProxyUtils,
  System.Types,
  System.SysUtils,
  System.NetConsts,
  Winapi.WinHTTP;

const
  RETRYABLE_ERROR_CODES: TArray<Integer> = [
    ERROR_WINHTTP_CANNOT_CONNECT,
    ERROR_WINHTTP_TIMEOUT,
    ERROR_WINHTTP_NAME_NOT_RESOLVED
  ];

{ THttpConnectionNetHttp }

constructor THttpConnectionNetHttp.Create;
begin
  FHeaders := TStringList.Create;
  FConnectionTimeout := TIMEOUT_CONNECT_DEFAULT;
  FSendTimeout := TIMEOUT_SEND_DEFAULT;
  FResponseTimeout := TIMEOUT_RECEIVE_DEFAULT;
end;

destructor THttpConnectionNetHttp.Destroy;
begin
  FCanceled := True;
  FHeaders.Free;

  inherited;
end;

procedure THttpConnectionNetHttp.DoRequest(AMethod: TMethod; const AURL: string; AContent, AResponse: TStream);
begin
  var LHTTPClient := THTTPClient.Create;
  try
    LHTTPClient.AcceptEncoding := 'utf-8';
    LHTTPClient.ConnectionTimeout := FConnectionTimeout;
    LHTTPClient.SendTimeout := FSendTimeout;
    LHTTPClient.ResponseTimeout := FResponseTimeout;
    LHTTPClient.CustHeaders.Assign(FHeaders);
    LHTTPClient.Accept := FAcceptTypes;
    LHTTPClient.ContentType := FContentTypes;
    LHTTPClient.AcceptLanguage := FAcceptedLanguages;

    if FProxyCredentials.Informed then
    begin
      var LProxySettings := TProxySettings.Create(GetProxyServer);
      LProxySettings.UserName := FProxyCredentials.UserName;
      LProxySettings.Password := FProxyCredentials.Password;
      LHTTPClient.ProxySettings := LProxySettings;
    end;

    try
    if FAsynchronous then
      FResponse := DoASyncRequest(LHTTPClient, AMethod, AURL, AContent, AResponse)
    else
      FResponse := DoSyncRequest(LHTTPClient, AMethod, AURL, AContent, AResponse);
    except
      on Error: ENetHTTPClientException do
      begin
        if IsRetryableError(Error) then
        begin
          var LRetryMode := hrmRaise;

          if Assigned(FOnConnectionLost) then
            FOnConnectionLost(Error, LRetryMode);

          if LRetryMode = hrmRaise then
            raise
          else if LRetryMode = hrmRetry then
            DoRequest(AMethod, AURL, AContent, AResponse);
        end
        else
          raise;
      end;
    end;
  finally
    LHTTPClient.Free;
  end;
end;

function THttpConnectionNetHttp.DoSyncRequest(AHTTPClient: THTTPClient; AMethod: TMethod; const AURL: string; AContent, AResponse: TStream): IHTTPResponse;
begin
  case AMethod of
    mGET: Result := AHTTPClient.Get(AURL, AResponse);
    mPOST: Result := AHTTPClient.Post(AURL, AContent, AResponse);
    mPUT: Result := AHTTPClient.Put(AURL, AContent, AResponse);
    mPATCH: Result := AHTTPClient.Patch(AURL, AContent, AResponse);
    mDELETE: Result := AHTTPClient.Delete(AURL, AResponse);
  end;
end;

function THttpConnectionNetHttp.DoASyncRequest(AHTTPClient: THTTPClient; AMethod: TMethod; const AURL: string; AContent, AResponse: TStream): IHTTPResponse;
var
  LResponse: IAsyncResult;
begin
  FCanceled := False;

  case AMethod of
    mGET: LResponse := AHTTPClient.BeginGet(AURL, AResponse);
    mPOST: LResponse := AHTTPClient.BeginPost(AURL, AContent, AResponse);
    mPUT: LResponse := AHTTPClient.BeginPut(AURL, AContent, AResponse);
    mPATCH: LResponse := AHTTPClient.BeginPatch(AURL, AContent, AResponse);
    mDELETE: LResponse := AHTTPClient.BeginDelete(AURL, AResponse);
  end;

  while not(LResponse.IsCompleted or LResponse.IsCancelled) do
  begin
    sleep(1);

    if FCanceled then
      LResponse.Cancel;

    if not TThread.CurrentThread.ExternalThread and TThread.CurrentThread.CheckTerminated then
      Exit;

    if Assigned(FOnAsyncRequestProcess) then
      FOnAsyncRequestProcess(FCanceled);
  end;

  Result := AHTTPClient.EndAsyncHTTP(LResponse);
end;


procedure THttpConnectionNetHttp.Delete(AUrl: string; AContent, AResponse: TStream);
begin
  DoRequest(mDELETE, AURL, AContent, AResponse);
end;

procedure THttpConnectionNetHttp.Get(AUrl: string; AResponse: TStream);
begin
  DoRequest(mGET, AURL, nil, AResponse);
end;

procedure THttpConnectionNetHttp.Patch(AUrl: string; AContent, AResponse: TStream);
begin
  DoRequest(mPATCH, AURL, AContent, AResponse);
end;

procedure THttpConnectionNetHttp.Post(AUrl: string; AContent, AResponse: TStream);
begin
  DoRequest(mPOST, AURL, AContent, AResponse);
end;

procedure THttpConnectionNetHttp.Put(AUrl: string; AContent, AResponse: TStream);
begin
  DoRequest(mPUT, AURL, AContent, AResponse);
end;

procedure THttpConnectionNetHttp.CancelRequest;
begin
  if FAsynchronous then
    FCanceled := True;
end;

function THttpConnectionNetHttp.ConfigureProxyCredentials(AProxyCredentials: TProxyCredentials): IHttpConnection;
begin
  FProxyCredentials := AProxyCredentials;

  Result := Self;
end;

function THttpConnectionNetHttp.ConfigureTimeout(const ATimeout: TTimeOut): IHttpConnection;
begin
  FConnectionTimeout := ATimeout.ConnectTimeout;
  FSendTimeout := ATimeout.SendTimeout;
  FResponseTimeout := ATimeout.ReceiveTimeout;

  Result := Self;
end;

function THttpConnectionNetHttp.GetEnabledCompression: Boolean;
begin
  Result := False;
end;

function THttpConnectionNetHttp.GetOnConnectionLost: THTTPConnectionLostEvent;
begin
  Result := FOnConnectionLost;
end;

function THttpConnectionNetHttp.GetResponseCode: Integer;
begin
  Result := FResponse.StatusCode;
end;

function THttpConnectionNetHttp.GetResponseHeader(const Header: string): string;
begin
  Result := FResponse.HeaderValue[Header];
end;

function THttpConnectionNetHttp.GetVerifyCert: Boolean;
begin
  Result := FVerifyCert;
end;

function THttpConnectionNetHttp.IsRetryableError(Error: ENetHTTPClientException): Boolean;
begin
  for var ErrorCode in RETRYABLE_ERROR_CODES do
    if Error.Message.Contains(IntToStr(ErrorCode)) then
      Exit(True);

  Result := False;
end;

function THttpConnectionNetHttp.SetAcceptedLanguages(AAcceptedLanguages: string): IHttpConnection;
begin
  FAcceptedLanguages := AAcceptedLanguages;

  Result := Self;
end;

function THttpConnectionNetHttp.SetAcceptTypes(AAcceptTypes: string): IHttpConnection;
begin
  FAcceptTypes := AAcceptTypes;

  Result := Self;
end;

function THttpConnectionNetHttp.SetAsync(const Value: Boolean): IHttpConnection;
begin
  FAsynchronous := Value;

  Result := Self;
end;

function THttpConnectionNetHttp.SetContentTypes(AContentTypes: string): IHttpConnection;
begin
  FContentTypes := AContentTypes;

  Result := Self;
end;

procedure THttpConnectionNetHttp.SetEnabledCompression(const Value: Boolean);
begin
  // Nothing to do
end;

function THttpConnectionNetHttp.SetHeaders(AHeaders: TStrings): IHttpConnection;
begin
  FHeaders.Assign(AHeaders);

  Result := Self;
end;

function THttpConnectionNetHttp.SetOnAsyncRequestProcess(const Value: TAsyncRequestProcessEvent): IHttpConnection;
begin
  FOnAsyncRequestProcess := Value;

  Result := Self;
end;

procedure THttpConnectionNetHttp.SetOnConnectionLost(AConnectionLostEvent: THTTPConnectionLostEvent);
begin
  FOnConnectionLost := AConnectionLostEvent;
end;

procedure THttpConnectionNetHttp.SetVerifyCert(const Value: boolean);
begin
  FVerifyCert := Value;
end;

end.
