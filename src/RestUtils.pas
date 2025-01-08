unit RestUtils;

interface

{$I DelphiRest.inc}

const
  MediaType_Json = 'application/json';
  MediaType_Xml = 'text/xml';
  MediaType_Gzip = 'application/gzip';

  LOCALE_PORTUGUESE_BRAZILIAN = 'pt-BR';
  LOCALE_US = 'en-US';

type
  TResponseCode = record
    StatusCode: Integer;
    Reason: string;
  end;

  (* See Status Code Definitions at http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html *)
  TStatusCode = class
  public
    (* 100 CONTINUE *)
    class function CONTINUE: TResponseCode;

    (* 101 Switching Protocols *)
    class function SWITCHING_PROTOCOLS: TResponseCode;

    (* 200 OK *)
    class function OK: TResponseCode;

    (* 201 Created *)
    class function CREATED: TResponseCode;

    (* 202 Accepted *)
    class function ACCEPTED: TResponseCode;

    (* 203 Non-Authoritative Information *)
    class function NON_AUTHORITATIVE_INFORMATION: TResponseCode;

    (* 204 No Content *)
    class function NO_CONTENT: TResponseCode;

    (* 205 Reset Content *)
    class function RESET_CONTENT: TResponseCode;

    (* 206 Partial Content *)
    class function PARTIAL_CONTENT: TResponseCode;

    (* 300 Multiple Choices *)
    class function MULTIPLE_CHOICES: TResponseCode;

    (* 301 Moved Permanently *)
    class function MOVED_PERMANENTLY: TResponseCode;

    (* 302 Found *)
    class function FOUND: TResponseCode;

    (* 303 See Other *)
    class function SEE_OTHER: TResponseCode;

    (* 304 Not Modified *)
    class function NOT_MODIFIED: TResponseCode;

    (* 305 Use Proxy *)
    class function USE_PROXY: TResponseCode;

    (* 307 Temporary Redirect *)
    class function TEMPORARY_REDIRECT: TResponseCode;

    (* 400 Bad Request *)
    class function BAD_REQUEST: TResponseCode;

    (* 401 Unauthorized *)
    class function UNAUTHORIZED: TResponseCode;

    (* 402 Payment Required *)
    class function PAYMENT_REQUIRED: TResponseCode;

    (* 403 Forbidden *)
    class function FORBIDDEN: TResponseCode;

    (* 404 Not Found *)
    class function NOT_FOUND: TResponseCode;

    (* 405 Method Not Allowed *)
    class function METHOD_NOT_ALLOWED: TResponseCode;

    (* 406 Not Acceptable *)
    class function NOT_ACCEPTABLE: TResponseCode;

    (* 407 Proxy Authentication Required *)
    class function PROXY_AUTHENTICATION_REQUIRED: TResponseCode;

    (* 408 Request Timeout *)
    class function REQUEST_TIMEOUT: TResponseCode;

    (* 409 OK *)
    class function CONFLICT: TResponseCode;

    (* 410 Gone *)
    class function GONE: TResponseCode;

    (* 411 Length Required *)
    class function LENGTH_REQUIRED: TResponseCode;

    (* 412 Precondition Failed *)
    class function PRECONDITION_FAILED: TResponseCode;

    (* 413 Request Entity Too Large *)
    class function REQUEST_ENTITY_TOO_LARGE: TResponseCode;

    (* 414 Request-URI Too Long *)
    class function REQUEST_URI_TOO_LONG: TResponseCode;

    (* 415 Unsupported Media Type *)
    class function UNSUPPORTED_MEDIA_TYPE: TResponseCode;

    (* 416 Requested Range Not Satisfiable *)
    class function REQUESTED_RANGE_NOT_SATISFIABLE: TResponseCode;

    (* 417 Expectation Failed *)
    class function EXPECTATION_FAILED: TResponseCode;

    (* 422 Unprocessable Entity *)
    class function UNPROCESSABLE_ENTITY: TResponseCode;

    (* 500 Internal Server Error *)
    class function INTERNAL_SERVER_ERROR: TResponseCode;

    (* 501 Not Implemented *)
    class function NOT_IMPLEMENTED: TResponseCode;

    (* 502 Bad Gateway *)
    class function BAD_GATEWAY: TResponseCode;

    (* 503 Service Unavailable *)
    class function SERVICE_UNAVAILABLE: TResponseCode;

    (* 504 Gateway Timeout *)
    class function GATEWAY_TIMEOUT: TResponseCode;

    (* 505 HTTP Version Not Supported *)
    class function HTTP_VERSION_NOT_SUPPORTED: TResponseCode;

  end;

  TRestUtils = class
  public
    class function Base64Encode(const AValue: String): String;
    class function Base64Decode(const AValue: String): String;
  end;

implementation

uses
  {$IFDEF HAS_UNIT_NETENCODING}
  System.NetEncoding, //allows inlining of EncodeString, DecodeString
  {$ENDIF}
  EncdDecd;

{ TStatusCode }

class function TStatusCode.ACCEPTED: TResponseCode;
begin
  Result.StatusCode := 202;
  Result.Reason := 'Accepted';
end;

class function TStatusCode.BAD_GATEWAY: TResponseCode;
begin
  Result.StatusCode := 502;
  Result.Reason := 'Bad Gateway';
end;

class function TStatusCode.BAD_REQUEST: TResponseCode;
begin
  Result.StatusCode := 400;
  Result.Reason := 'Bad Request';
end;

class function TStatusCode.CONFLICT: TResponseCode;
begin
  Result.StatusCode := 409;
  Result.Reason := 'Conflict';
end;

class function TStatusCode.CONTINUE: TResponseCode;
begin
  Result.StatusCode := 100;
  Result.Reason := 'Continue';
end;

class function TStatusCode.Created: TResponseCode;
begin
  Result.StatusCode := 201;
  Result.Reason := 'Created';
end;

class function TStatusCode.EXPECTATION_FAILED: TResponseCode;
begin
  Result.StatusCode := 417;
  Result.Reason := 'Expectation Failed';
end;

class function TStatusCode.FORBIDDEN: TResponseCode;
begin
  Result.StatusCode := 403;
  Result.Reason := 'Forbidden';
end;

class function TStatusCode.FOUND: TResponseCode;
begin
  Result.StatusCode := 302;
  Result.Reason := 'Found';
end;

class function TStatusCode.GATEWAY_TIMEOUT: TResponseCode;
begin
  Result.StatusCode := 504;
  Result.Reason := 'Gateway Timeout';
end;

class function TStatusCode.GONE: TResponseCode;
begin
  Result.StatusCode := 410;
  Result.Reason := 'Gone';
end;

class function TStatusCode.HTTP_VERSION_NOT_SUPPORTED: TResponseCode;
begin
  Result.StatusCode := 505;
  Result.Reason := 'HTTP Version Not Supported';
end;

class function TStatusCode.INTERNAL_SERVER_ERROR: TResponseCode;
begin
  Result.StatusCode := 500;
  Result.Reason := 'Internal Server Error';
end;

class function TStatusCode.LENGTH_REQUIRED: TResponseCode;
begin
  Result.StatusCode := 411;
  Result.Reason := 'Length Required';
end;

class function TStatusCode.METHOD_NOT_ALLOWED: TResponseCode;
begin
  Result.StatusCode := 405;
  Result.Reason := 'Method Not Allowed';
end;

class function TStatusCode.MOVED_PERMANENTLY: TResponseCode;
begin
  Result.StatusCode := 301;
  Result.Reason := 'Moved Permanently';
end;

class function TStatusCode.MULTIPLE_CHOICES: TResponseCode;
begin
  Result.StatusCode := 300;
  Result.Reason := 'Multiple Choices';
end;

class function TStatusCode.NON_AUTHORITATIVE_INFORMATION: TResponseCode;
begin
  Result.StatusCode := 203;
  Result.Reason := 'Non-Authoritative Information';
end;

class function TStatusCode.NOT_ACCEPTABLE: TResponseCode;
begin
  Result.StatusCode := 406;
  Result.Reason := 'Not Acceptable';
end;

class function TStatusCode.NOT_FOUND: TResponseCode;
begin
  Result.StatusCode := 404;
  Result.Reason := 'Not Found';
end;

class function TStatusCode.NOT_IMPLEMENTED: TResponseCode;
begin
  Result.StatusCode := 501;
  Result.Reason := 'Not Implemented';
end;

class function TStatusCode.NOT_MODIFIED: TResponseCode;
begin
  Result.StatusCode := 304;
  Result.Reason := 'Not Modified';
end;

class function TStatusCode.NO_CONTENT: TResponseCode;
begin
  Result.StatusCode := 204;
  Result.Reason := 'No Content';
end;

class function TStatusCode.OK: TResponseCode;
begin
  Result.StatusCode := 200;
  Result.Reason := 'OK';
end;

class function TStatusCode.PARTIAL_CONTENT: TResponseCode;
begin
  Result.StatusCode := 206;
  Result.Reason := 'Partial Content';
end;

class function TStatusCode.PAYMENT_REQUIRED: TResponseCode;
begin
  Result.StatusCode := 402;
  Result.Reason := 'Payment Required';
end;

class function TStatusCode.PRECONDITION_FAILED: TResponseCode;
begin
  Result.StatusCode := 412;
  Result.Reason := 'Precondition Failed';
end;

class function TStatusCode.PROXY_AUTHENTICATION_REQUIRED: TResponseCode;
begin
  Result.StatusCode := 407;
  Result.Reason := 'Proxy Authentication Required';
end;

class function TStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE: TResponseCode;
begin
  Result.StatusCode := 416;
  Result.Reason := 'Requested Range Not Satisfiable';
end;

class function TStatusCode.REQUEST_ENTITY_TOO_LARGE: TResponseCode;
begin
  Result.StatusCode := 413;
  Result.Reason := 'Request Entity Too Large';
end;

class function TStatusCode.REQUEST_TIMEOUT: TResponseCode;
begin
  Result.StatusCode := 408;
  Result.Reason := 'Request Timeout';
end;

class function TStatusCode.REQUEST_URI_TOO_LONG: TResponseCode;
begin
  Result.StatusCode := 414;
  Result.Reason := 'Request-URI Too Long';
end;

class function TStatusCode.RESET_CONTENT: TResponseCode;
begin
  Result.StatusCode := 205;
  Result.Reason := 'Reset Content';
end;

class function TStatusCode.SEE_OTHER: TResponseCode;
begin
  Result.StatusCode := 303;
  Result.Reason := 'See Other';
end;

class function TStatusCode.SERVICE_UNAVAILABLE: TResponseCode;
begin
  Result.StatusCode := 503;
  Result.Reason := 'Service Unavailable';
end;

class function TStatusCode.SWITCHING_PROTOCOLS: TResponseCode;
begin
  Result.StatusCode := 101;
  Result.Reason := 'Switching Protocols';
end;

class function TStatusCode.TEMPORARY_REDIRECT: TResponseCode;
begin
  Result.StatusCode := 307;
  Result.Reason := 'Temporary Redirect';
end;

class function TStatusCode.UNAUTHORIZED: TResponseCode;
begin
  Result.StatusCode := 401;
  Result.Reason := 'Unauthorized';
end;

class function TStatusCode.UNPROCESSABLE_ENTITY: TResponseCode;
begin
  Result.StatusCode := 422;
  Result.Reason := 'Unprocessable Entity';
end;

class function TStatusCode.UNSUPPORTED_MEDIA_TYPE: TResponseCode;
begin
  Result.StatusCode := 415;
  Result.Reason := 'Unsupported Media Type';
end;

class function TStatusCode.USE_PROXY: TResponseCode;
begin
  Result.StatusCode := 305;
  Result.Reason := 'Use Proxy';
end;

{ TRestUtils }

class function TRestUtils.Base64Decode(const AValue: String): String;
begin
  Result := EncdDecd.DecodeString(AValue);
end;

class function TRestUtils.Base64Encode(const AValue: String): String;
begin
  Result := EncdDecd.EncodeString(AValue);
end;

end.
