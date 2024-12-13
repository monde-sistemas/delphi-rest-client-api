unit HttpConnectionNetHttp;

interface
uses
  HttpConnection,
  Classes,
  System.Net.URLClient,
  System.Net.HttpClientComponent,
  System.Net.HttpClient;

type
  TMethodRequest = (mrGET, mrPOST, mrPUT, mrPATCH, mrDELETE);
  
  THttpConnectionNetHttp = class(TInterfacedObject, IHttpConnection)
  private
    FNetHTTPClient: TNetHTTPClient;
    FNetHTTPRequest: TNetHTTPRequest;
    FResponse: IHTTPResponse;
    FVerifyCert: Boolean;
    procedure DoRequest(AMethod: TMethodRequest; const AUrl: string; AContent, AResponse: TStream);
  public
    OnConnectionLost: THTTPConnectionLostEvent;

    constructor Create;
    destructor Destroy; override;

    function SetAcceptTypes(AAcceptTypes: string): IHttpConnection;
    function SetAcceptedLanguages(AAcceptedLanguages: string): IHttpConnection;
    function SetContentTypes(AContentTypes: string): IHttpConnection;
    function SetHeaders(AHeaders: TStrings): IHttpConnection;

    procedure Get(AUrl: string; AResponse: TStream);
    procedure Post(AUrl: string; AContent: TStream; AResponse: TStream);
    procedure Put(AUrl: string; AContent: TStream; AResponse: TStream);
    procedure Patch(AUrl: string; AContent: TStream; AResponse: TStream);
    procedure Delete(AUrl: string; AContent: TStream; AResponse: TStream);

    function GetResponseCode: Integer;
    function GetResponseHeader(const Name: string): string;

    function SetAsync(const Value: Boolean): IHttpConnection;
    procedure CancelRequest;

    function GetEnabledCompression: Boolean;
    procedure SetEnabledCompression(const Value: Boolean);

    function GetOnConnectionLost: THTTPConnectionLostEvent;
    procedure SetOnConnectionLost(AConnectionLostEvent: THTTPConnectionLostEvent);

    procedure SetVerifyCert(const Value: boolean);
    function GetVerifyCert: boolean;

    function ConfigureTimeout(const ATimeOut: TTimeOut): IHttpConnection;
    function ConfigureProxyCredentials(AProxyCredentials: TProxyCredentials): IHttpConnection;

    function SetOnAsyncRequestProcess(const Value: TAsyncRequestProcessEvent): IHttpConnection;
  end;

implementation

uses
  ProxyUtils,
  System.SysUtils;

procedure THttpConnectionNetHttp.CancelRequest;
begin

end;

function THttpConnectionNetHttp.ConfigureProxyCredentials(AProxyCredentials: TProxyCredentials): IHttpConnection;
begin
  var ProxyIPAddr := GetProxyServerIP;
  var ProxyPort := GetProxyServerPort;
  FNetHTTPClient.ProxySettings := TProxySettings.Create(ProxyIPAddr, ProxyPort, AProxyCredentials.UserName, AProxyCredentials.Password);

  Result := Self;
end;

function THttpConnectionNetHttp.ConfigureTimeout(const ATimeOut: TTimeOut): IHttpConnection;
begin
  FNetHTTPClient.SendTimeout := ATimeOut.SendTimeout;
  FNetHTTPClient.ConnectionTimeout := ATimeOut.ConnectTimeout;
  FNetHTTPClient.ResponseTimeout := ATimeOut.ReceiveTimeout;

  Result := Self;
end;

constructor THttpConnectionNetHttp.Create;
begin
  FNetHTTPClient := TNetHTTPClient.Create(nil);
  FNetHTTPClient.HandleRedirects := True;

  FNetHTTPRequest := TNetHTTPRequest.Create(FNetHTTPClient);
  FNetHTTPRequest.Client := FNetHTTPClient;
end;

procedure THttpConnectionNetHttp.Delete(AUrl: string; AContent, AResponse: TStream);
begin
  DoRequest(mrDELETE, AUrl, Acontent, AResponse);
end;

destructor THttpConnectionNetHttp.Destroy;
begin
  FNetHTTPRequest.Free;
  FNetHTTPClient.Free;
  inherited;
end;

procedure THttpConnectionNetHttp.DoRequest(AMethod: TMethodRequest; const AUrl: string; AContent, AResponse: TStream);
begin
  var Attempts := 1;
  
  while Attempts > 0 do
  begin
    try
      case AMethod of
        mrGET: FResponse := FNetHTTPClient.Get(AUrl, AResponse);
        mrPOST: FResponse := FNetHTTPClient.Post(AUrl, AContent, AResponse);
        mrPUT: FResponse := FNetHTTPClient.Put(AUrl, AContent, AResponse);
        mrPATCH: FResponse := FNetHTTPClient.Patch(AUrl, AContent, AResponse);
        mrDELETE: FResponse := FNetHTTPClient.Delete(AUrl, AResponse);
      end;

      if assigned(FResponse) then
        Attempts := 0
      else
        Attempts := Attempts - 1;
    except
      on E: Exception do
      begin
        Attempts := Attempts - 1;

        if Attempts = 0 then
          raise E;
      end;
    end;
  end;
end;

procedure THttpConnectionNetHttp.Get(AUrl: string; AResponse: TStream);
begin
  DoRequest(mrGET, AUrl, nil, AResponse);
end;

function THttpConnectionNetHttp.GetEnabledCompression: Boolean;
begin
  Result := False;
end;

function THttpConnectionNetHttp.GetOnConnectionLost: THTTPConnectionLostEvent;
begin
  Result := nil;
end;

function THttpConnectionNetHttp.GetResponseCode: Integer;
begin
  Result := FResponse.StatusCode;
end;

function THttpConnectionNetHttp.GetResponseHeader(const Name: string): string;
begin
  Result := FResponse.HeaderValue[Name];
end;

function THttpConnectionNetHttp.GetVerifyCert: boolean;
begin
  Result := FVerifyCert;
end;

procedure THttpConnectionNetHttp.Patch(AUrl: string; AContent, AResponse: TStream);
begin
  DoRequest(mrPATCH, AUrl, AContent, AResponse);
end;

procedure THttpConnectionNetHttp.Post(AUrl: string; AContent, AResponse: TStream);
begin
  DoRequest(mrPOST, AUrl, AContent, AResponse);
end;

procedure THttpConnectionNetHttp.Put(AUrl: string; AContent, AResponse: TStream);
begin
  DoRequest(mrPUT, AUrl, AContent, AResponse);
end;

function THttpConnectionNetHttp.SetAcceptedLanguages(AAcceptedLanguages: string): IHttpConnection;
begin
  FNetHTTPClient.AcceptLanguage := AAcceptedLanguages;

  Result := Self;
end;

function THttpConnectionNetHttp.SetAcceptTypes(AAcceptTypes: string): IHttpConnection;
begin
  FNetHTTPClient.Accept := AAcceptTypes;

  Result := Self;
end;

function THttpConnectionNetHttp.SetAsync(const Value: Boolean): IHttpConnection;
begin
  FNetHTTPRequest.Asynchronous := Value;

  Result := Self;
end;

function THttpConnectionNetHttp.SetContentTypes(AContentTypes: string): IHttpConnection;
begin
  FNetHTTPClient.ContentType := AContentTypes;

  Result := Self;
end;

procedure THttpConnectionNetHttp.SetEnabledCompression(const Value: Boolean);
begin
  //Nothing to do
end;

function THttpConnectionNetHttp.SetHeaders(AHeaders: TStrings): IHttpConnection;
begin
  for var I := 0 to AHeaders.Count - 1 do
    FNetHTTPClient.CustHeaders.Add(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);

  Result := Self;
end;

function THttpConnectionNetHttp.SetOnAsyncRequestProcess(const Value: TAsyncRequestProcessEvent): IHttpConnection;
begin

end;

procedure THttpConnectionNetHttp.SetOnConnectionLost(AConnectionLostEvent: THTTPConnectionLostEvent);
begin

end;

procedure THttpConnectionNetHttp.SetVerifyCert(const Value: boolean);
begin
  FVerifyCert := Value;
end;

end.
