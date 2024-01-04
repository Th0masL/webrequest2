//+------------------------------------------------------------------+
//|															 				InetHttp |
//|                                    Copyright © 2010, FXmaster.de |
//|                                    Copyright © 2018, T.Bossert   |
//|                                						  www.FXmaster.de |
//|                                     https://github.com/sirtoobii |
//|     programming & support - Alexey Sergeev (profy.mql@gmail.com) |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, FXmaster.de,Copyright © 2018, T.Bossert"
#property link "www.FXmaster.de,https://github.com/sirtoobii"
#property version "1.01"
#property description "WinHttp & WinInet API"
#property library
#property strict

// Useful link to investigate/fix "leaked strings left"
// https://uhoho.hatenablog.jp/entry/2022/10/24/040523

// If not provided, set the Log Verbosity to 1
// Value 0: Show everything (Debug, Info, Warn and Error)
// Value 1: Show only Info, Warn and Error
// Value 2: Show only Warn and Error
// Value 3: Show only Error

// By default, show Info, Warn and Error
#ifndef INETHTTP_LOG_LEVEL_MIN
   #define INETHTTP_LOG_LEVEL_MIN 1
#endif

#define INETHTTP_LOG_DEBUG 0
#define INETHTTP_LOG_INFO 1
#define INETHTTP_LOG_WARN 2
#define INETHTTP_LOG_ERROR 3

#define FALSE 0

#define HINTERNET          int
#define BOOL               int
#define INTERNET_PORT      int
#define LPINTERNET_BUFFERS int
#define DWORD              int
#define DWORD_PTR          int
#define LPDWORD            int &
#define LPVOID             uchar &
#define LPSTR              string
#define LPCWSTR            string &
#define LPCTSTR            string &
#define LPTSTR             string &

#import "Kernel32.dll"
DWORD GetLastError(void);
#import


/*
To fix the problem with "leaked strings left", remove the & from the declaration of the following variables (at least)
InternetOpenW - lpszAgentlpszAgent, lpszProxyName, lpszProxyBypass
InternetConnectW - lpszServerName, lpszUsername, lpszPassword
HttpOpenRequestW - lpszVerb, lpszObjectName, lpszVersion, lpszReferer, lplpszAcceptTypes
*/

#import "wininet.dll"
DWORD InternetAttemptConnect(DWORD dwReserved);
HINTERNET InternetOpenW(LPCTSTR lpszAgent, DWORD dwAccessType, LPCTSTR lpszProxyName, LPCTSTR lpszProxyBypass, DWORD dwFlags);
HINTERNET InternetConnectW(HINTERNET hInternet, LPCTSTR lpszServerName, INTERNET_PORT nServerPort, LPCTSTR lpszUsername, LPCTSTR lpszPassword, DWORD dwService, DWORD dwFlags, DWORD_PTR dwContext);
HINTERNET HttpOpenRequestW(HINTERNET hConnect, LPCTSTR lpszVerb, LPCTSTR lpszObjectName, LPCTSTR lpszVersion, LPCTSTR lpszReferer, LPCTSTR lplpszAcceptTypes, uint /*DWORD*/ dwFlags, DWORD_PTR dwContext);
BOOL HttpSendRequestW(HINTERNET hRequest, LPCTSTR lpszHeaders, DWORD dwHeadersLength, LPVOID lpOptional[], DWORD dwOptionalLength);
BOOL HttpQueryInfoW(HINTERNET hRequest, DWORD dwInfoLevel, LPVOID lpvBuffer[], LPDWORD lpdwBufferLength, LPDWORD lpdwIndex);
HINTERNET InternetOpenUrlW(HINTERNET hInternet, LPCTSTR lpszUrl, LPCTSTR lpszHeaders, DWORD dwHeadersLength, uint /*DWORD*/ dwFlags, DWORD_PTR dwContext);
BOOL InternetReadFile(HINTERNET hFile, LPVOID lpBuffer[], DWORD dwNumberOfBytesToRead, LPDWORD lpdwNumberOfBytesRead);
BOOL InternetCloseHandle(HINTERNET hInternet);
BOOL InternetSetOptionW(HINTERNET hInternet, DWORD dwOption, LPDWORD lpBuffer, DWORD dwBufferLength);
BOOL InternetQueryOptionW(HINTERNET hInternet, DWORD dwOption, LPDWORD lpBuffer, LPDWORD lpdwBufferLength);
#import

#define OPEN_TYPE_PRECONFIG         0               // use default configuration
#define INTERNET_SERVICE_FTP        1               // Ftp service
#define INTERNET_SERVICE_HTTP       3               // Http service
#define HTTP_QUERY_CONTENT_LENGTH   5
#define HTTP_QUERY_STATUS_CODE      19              // Http status code
#define HTTP_QUERY_RAW_HEADERS_CRLF 22              // Response Headers

#define INTERNET_FLAG_PRAGMA_NOCACHE   0x00000100   // no caching of page
#define INTERNET_FLAG_KEEP_CONNECTION  0x00400000   // keep connection
#define INTERNET_FLAG_SECURE           0x00800000   // SSL TLS
#define INTERNET_FLAG_RELOAD           0x80000000   // get page from server when calling it
#define INTERNET_OPTION_SECURITY_FLAGS 31

#define ERROR_INTERNET_INVALID_CA              12045
#define INTERNET_FLAG_IGNORE_CERT_DATE_INVALID 0x00002000
#define INTERNET_FLAG_IGNORE_CERT_CN_INVALID   0x00001000
#define SECURITY_FLAG_IGNORE_CERT_CN_INVALID   INTERNET_FLAG_IGNORE_CERT_CN_INVALID
#define SECURITY_FLAG_IGNORE_CERT_DATE_INVALID INTERNET_FLAG_IGNORE_CERT_DATE_INVALID
#define SECURITY_FLAG_IGNORE_REVOCATION        0x00000080
#define SECURITY_FLAG_IGNORE_UNKNOWN_CA        0x00000100
#define SECURITY_FLAG_IGNORE_WRONG_USAGE       0x00000200
//------------------------------------------------------------------ struct tagRequest
struct tagRequest {
   string stVerb;     // method of the GET/POST request
   string stObject;   // path to the page "/get.php?a=1" or "/index.htm"
   string stHead;     // request header,
                      // "Content-Type: multipart/form-data; boundary=1BEF0A57BE110FD467A\r\n"
   // or "Content-Type: application/x-www-form-urlencoded"
   string stData;      // additional string of information
   bool fromFile;      // if =true, then stData is the name of the data file
   string stOut;       // field for receiving the answer
   bool toFile;        // if =true, then stOut is the name of file for receiving the answer
   int resCode;        // HTTP response code
   string resHeader;   // Raw Response Header (max 1024 Bytes)
   bool useSSL;        // Use secure connection
   bool trustSelf;     // Trust self signed
   void Init(string aVerb, string aObject, string aHead, string aData, bool from, string aOut, bool to, bool uSSL, bool sSign);
};
//------------------------------------------------------------------ class MqlNet
void tagRequest::Init(string aVerb, string aObject, string aHead, string aData, bool from, string aOut, bool to, bool uSSL, bool sSign) {
   stVerb = aVerb;       // method of the GET/POST request
   stObject = aObject;   // path to the page "/get.php?a=1" or "/index.htm"
   stHead = aHead;       // request header, "Content-Type: application/x-www-form-urlencoded"
   stData = aData;       // additional string of information
   fromFile = from;      // if =true, then stData is the name of the data file
   stOut = aOut;         // field for receiving the answer
   toFile = to;          // if =true, then stOut is the name of file for receiving the answer
   resCode = -1;
   resHeader = "";
   useSSL = uSSL;
   trustSelf = sSign;
}
//------------------------------------------------------------------ class MqlNet
class MqlNet {
 public:
   string Host;                                                                    // host name
   int Port;                                                                       // port
   string User;                                                                    // user name
   string Pass;                                                                    // user password
   int Service;                                                                    // service type
                                                                                   // obtained parameters
   int hSession;                                                                   // session descriptor
   int hConnect;                                                                   // connection descriptor
 public:
   MqlNet();                                                                       // class constructor
   ~MqlNet();                                                                      // destructor
   bool Open(string aHost, int aPort, string aUser, string aPass, int aService);   // create a session and open a connection
   void Close();                                                                   // close the session and the connection
   bool Request(tagRequest &req, uchar &inData[], uchar &outData[]);               // send the request
   void ReadPage(int hRequest, uchar &outData[]);
   int GetContentSize(int hURL);                                                   // get information about the size of downloaded page
   string GetHTTPHeaders(int hRequest);                                            // Get all result headers
   int GetHTTPStatusCode(int hRequest);                                            // returns the status code of a request
   bool CheckTerminal();                                                           // Checks terminal if DLL's are allowed
   void LogError(int pLevel, string pMsg);                                           // Log message
};
//------------------------------------------------------------------ MqlNet
void MqlNet::MqlNet() {
   hSession = -1;
   hConnect = -1;
   Host = "";
   User = "";
   Pass = "";
   Service = -1;   // zeroize the parameters
}
//------------------------------------------------------------------ ~MqlNet
void MqlNet::~MqlNet() {
   Close();   // close all descriptors
}
//------------------------------------------------------------------ Open
bool MqlNet::Open(string aHost, int aPort, string aUser, string aPass, int aService) {
   LogError(INETHTTP_LOG_DEBUG, "MqlNet::Open - Start function.");
   if (aHost == "") {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::Open - Host not specified");
      return (false);
   }
   if (!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED)) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::Open - DLL not allowed");
      return (false);
   }   // checking whether DLLs are allowed in the terminal
   if (!MQL5InfoInteger(MQL5_DLLS_ALLOWED)) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::Open - DLL not allowed");
      return (false);
   }                         // checking whether DLLs are allowed in the terminal
   if (hSession > 0 || hConnect > 0)
      Close();               // close if a session was determined
   LogError(INETHTTP_LOG_DEBUG, "MqlNet::Open - Open Inet...");   // print a message about the attempt of opening in the journal
   if (InternetAttemptConnect(0) != 0) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::Open - Err InternetAttemptConnect");
      return (false);
   }   // exit if the attempt to check the current Internet connection failed
   // string UserAgent = "Metatrader 5";
   string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0";
   string nill = "";
   hSession = InternetOpenW(UserAgent, OPEN_TYPE_PRECONFIG, nill, nill, 0);   // open session
   if (hSession <= 0) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::Open - Err create Session using InternetOpenW");
      Close();
      return (false);
   }   // exit if the attempt to open the session failed
   hConnect = InternetConnectW(hSession, aHost, aPort, aUser, aPass, aService, 0, 0);
   if (hConnect <= 0) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::Open - Err create Connect using InternetConnectW");
      Close();
      return (false);
   }
   Host = aHost;
   Port = aPort;
   User = aUser;
   Pass = aPass;
   Service = aService;
   return (true);   // otherwise all the checks are successfully finished
}
//------------------------------------------------------------------ Close
void MqlNet::Close() {
   LogError(INETHTTP_LOG_DEBUG, "MqlNet::Close - Start function.");
   if (hSession > 0) {
      InternetCloseHandle(hSession);
      hSession = -1;
      LogError(INETHTTP_LOG_DEBUG, "MqlNet::Close - Close Session...");
   }
   if (hConnect > 0) {
      InternetCloseHandle(hConnect);
      hConnect = -1;
      LogError(INETHTTP_LOG_DEBUG, "MqlNet::Close - Close Connect...");
   }
}
//------------------------------------------------------------------ Request
bool MqlNet::Request(tagRequest &req, uchar &inData[], uchar &outData[]) {
   LogError(INETHTTP_LOG_DEBUG, "MqlNet::Request - Start function.");
   if (!CheckTerminal())
      return false;
   uchar data[];
   int hRequest;
   int hSend = 0;
   string Vers = "HTTP/1.1";
   string nill = "";
   int lastError = 0;
   if (hSession <= 0 || hConnect <= 0) {
      Close();
      if (!Open(Host, Port, User, Pass, Service)) {
         LogError(INETHTTP_LOG_ERROR, "MqlNet::Request - Err Connect using Open");
         Close();
         return (false);
      }
   }
   string nuller = NULL;
   // creating descriptor of the request
   if (req.useSSL) {
      hRequest =
          HttpOpenRequestW(hConnect, req.stVerb, req.stObject, Vers, nuller, nuller, INTERNET_FLAG_KEEP_CONNECTION | INTERNET_FLAG_RELOAD | INTERNET_FLAG_PRAGMA_NOCACHE | INTERNET_FLAG_SECURE, 0);
   } else {
      hRequest = HttpOpenRequestW(hConnect, req.stVerb, req.stObject, Vers, nuller, nuller, INTERNET_FLAG_KEEP_CONNECTION | INTERNET_FLAG_RELOAD | INTERNET_FLAG_PRAGMA_NOCACHE, 0);
   }
   // Get last error code
   if (hRequest <= 0) {
      lastError = Kernel32::GetLastError();
      LogError(INETHTTP_LOG_ERROR, "MqlNet::Request - Err HttpOpenRequestW=" + (string) lastError);
      InternetCloseHandle(hConnect);
      return (false);
   }
   // Set certificate policity (warning this configuration is very unsecure and shouldn't be used where security matters!)
   if (req.trustSelf) {
      int dwFlags;
      int dwBuffLen = sizeof(dwFlags);
      InternetQueryOptionW(hRequest, INTERNET_OPTION_SECURITY_FLAGS, dwFlags, dwBuffLen);
      dwFlags |= SECURITY_FLAG_IGNORE_UNKNOWN_CA;
      dwFlags |= INTERNET_FLAG_IGNORE_CERT_DATE_INVALID;
      dwFlags |= SECURITY_FLAG_IGNORE_CERT_CN_INVALID;
      dwFlags |= SECURITY_FLAG_IGNORE_REVOCATION;
      bool rez = InternetSetOptionW(hRequest, INTERNET_OPTION_SECURITY_FLAGS, dwFlags, sizeof(dwFlags));
      if (!rez) {
         lastError = Kernel32::GetLastError();
         LogError(INETHTTP_LOG_ERROR, "MqlNet::Request - Err InternetSetOptionW=" + (string) lastError);
      }
   }
   // sending the request
   int n = 0;
   while (n < 3) {
      n++;
      // send
      hSend = HttpSendRequestW(hRequest, req.stHead, StringLen(req.stHead), inData, ArraySize(inData));
      if (hSend <= 0) {
         lastError = Kernel32::GetLastError();
         LogError(INETHTTP_LOG_ERROR, "MqlNet::Request - Err HttpSendRequestW=" + (string) lastError + ". Attempts Count: " + (string)n);
      } else
         break;
   }
   if (hSend > 0) {
      req.resCode = GetHTTPStatusCode(hRequest);   // Get response code
      req.resHeader = GetHTTPHeaders(hRequest);    // Get Header
      ReadPage(hRequest, outData);                 // Read data from server
   }
   InternetCloseHandle(hRequest);
   InternetCloseHandle(hSend);   // close all handles
   if (hSend <= 0)
      Close();
   return (true);
}
//------------------------------------------------------------------ ReadPage
void MqlNet::ReadPage(int hRequest, uchar &outData[]) {
   LogError(INETHTTP_LOG_DEBUG, "MqlNet::ReadPage - Start function.");
   if (!CheckTerminal())
      return;
   // read the page
   int bufferSize = 100;
   uchar ch[100];
   string toStr = "";
   int dwBytes, h = -1;
   long content_size = GetContentSize(hRequest);
   ArrayResize(outData, GetContentSize(hRequest));
   int index = 0;
   while (InternetReadFile(hRequest, ch, bufferSize, dwBytes)) {
      if (dwBytes <= 0)
         break;
      for (int i = 0; i < dwBytes; i++) {
         outData[i + index] = ch[i];
      }
      index += dwBytes;
   }
}
//------------------------------------------------------------------ GetContentSize
int MqlNet::GetContentSize(int hRequest) {
   LogError(INETHTTP_LOG_DEBUG, "MqlNet::GetContentSize - Start function.");
   if (!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED)) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::GetContentSize - DLL not allowed");
      return (false);
   }   // checking whether DLLs are allowed in the terminal
   if (!MQL5InfoInteger(MQL5_DLLS_ALLOWED)) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::GetContentSize - DLL not allowed");
      return (false);
   }   // checking whether DLLs are allowed in the terminal
   int len = 32, ind = 0;
   uchar buf[32];
   bool Res = HttpQueryInfoW(hRequest, HTTP_QUERY_CONTENT_LENGTH, buf, len, ind);
   if (!Res) {
      int lastError = Kernel32::GetLastError();
      LogError(INETHTTP_LOG_ERROR, "MqlNet::GetContentSize - Err QueryInfo (Size)" + (string) lastError);
      return (-1);
   }
   // This is a workaround because CharArrayToString does somehow not work...
   string s;
   for (int i = 0; i < len; i++) {
      StringAdd(s, CharToString(buf[i]));
   }
   // ToDo Overflow prodection!
   return ((int) StringToInteger(s));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MqlNet::GetHTTPStatusCode(int hRequest) {
   LogError(INETHTTP_LOG_DEBUG, "MqlNet::GetHTTPStatusCode - Start function.");
   if (!CheckTerminal())
      return -1;
   uchar cBuff[32];
   int cBuffLength = 32;
   int cBuffIndex = 0;
   bool Res = HttpQueryInfoW(hRequest, HTTP_QUERY_STATUS_CODE, cBuff, cBuffLength, cBuffIndex);
   if (!Res) {
      int lastError = Kernel32::GetLastError();
      LogError(INETHTTP_LOG_ERROR, "MqlNet::GetHTTPStatusCode - Err QueryInfo (Status)" + (string) lastError);
      return (-1);
   }
   string s = "";
   for (int i = 0; i < cBuffLength; i++) {
      StringAdd(s, CharToString(cBuff[i]));
   }
   StringTrimRight(s);
   int http_code = (int) StringToInteger(s);
   return http_code;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MqlNet::GetHTTPHeaders(int hRequest) {
   LogError(INETHTTP_LOG_DEBUG, "MqlNet::GetHTTPHeaders - Start function.");
   if (!CheckTerminal()) {
      return "";
   }
   uchar cBuff[1024];
   int cBuffLength = 1024;
   int cBuffIndex = 0;
   HttpQueryInfoW(hRequest, HTTP_QUERY_RAW_HEADERS_CRLF, cBuff, cBuffLength, cBuffIndex);
   string s = "";
   // This is a workaround because CharArrayToString does somehow not work...
   for (int i = 0; i < cBuffLength; i++) {
      StringAdd(s, CharToString(cBuff[i]));
   }
   StringTrimRight(s);
   return s;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MqlNet::CheckTerminal() {
   if (!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED)) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::CheckTerminal - DLL not allowed");
      return (false);
   }   // checking whether DLLs are allowed in the terminal
   if (!MQL5InfoInteger(MQL5_DLLS_ALLOWED)) {
      LogError(INETHTTP_LOG_ERROR, "MqlNet::CheckTerminal - DLL not allowed");
      return (false);
   }   // checking whether DLLs are allowed in the terminal
   return true;
}
//+------------------------------------------------------------------+

void MqlNet::LogError(int pLevel, string pMsg) {

   // If the log level is not at least the verbosity, do not show it
   if (pLevel < INETHTTP_LOG_LEVEL_MIN) {
      return;
   } 

   switch (pLevel) {
   case INETHTTP_LOG_DEBUG:
      Print("++InetHttp[DEBUG] " + pMsg);
      break;
   case INETHTTP_LOG_INFO:
      Print("++InetHttp[INFO] " + pMsg);
      break;
   case INETHTTP_LOG_WARN:
      Print("--InetHttp[WARN] " + pMsg);
      break;
   case INETHTTP_LOG_ERROR:
      Print("--InetHttp[ERROR] " + pMsg);
      break;
   }
}