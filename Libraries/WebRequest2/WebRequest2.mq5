//+------------------------------------------------------------------+
//|															 		   Webrequest2 |
//|                                      Copyright © 2018, T.Bossert |
//|                                     https://github.com/sirtoobii |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, T.Bossert"
#property link "https://github.com/sirtoobii"
#property version "1.00"
#property library
#include "InetHttp.mqh"
MqlNet INet;
int WebRequest2(const string method,                // HTTP-Methode
                const string url,                   // URL-Adresse
                const string headers,               // Headers
                int timeout,                        // Timeout
                char &data[],                       // Array des Body einer HTTP-Nachricht
                char &result[],                     // Array mit den Daten der Serverantwort
                string &result_headers,             // Headers der Serverantwort
                const int port = NULL,              // Define custom port
                const bool allowInsecure = false,   // Allow self signed certs
                const bool useSSL = NULL            // Use SSL encrypted connection
                ) export {
   Print(url);
   int Port = port;
   bool UseSSL = useSSL;
   string Host = "";
   string Path = "";
   string lower_Url = url;
   string Head = headers;
   string file = "";
   tagRequest req;
   StringToLower(lower_Url);
   int offset = 0;
   // Determine Ports if not set
   if ((StringFind(lower_Url, "http") == -1) && (port == NULL)) {
      LogError(2, "Please specifiy eighter a port or Http(s) with the url parameter");
      return -1;
   }
   if (port == NULL && StringFind(lower_Url, "https://") != -1) {
      Port = 443;
      UseSSL = true;
   } else if (port == NULL) {
      Port = 80;
      UseSSL = false;
   }
   // Remove http(s):// and define offset for spliting
   if (StringReplace(lower_Url, "https://", "")) {
      offset = 8;
   }
   if (StringReplace(lower_Url, "http://", "")) {
      offset = 7;
   }
   // Determine host and path from url parameter
   int path_start = StringFind(lower_Url, "/", 0);
   if (path_start > 0) {
      Host = StringSubstr(lower_Url, 0, path_start);
      Path = StringSubstr(url, path_start + offset);
      LogError(0, "Set Host to: " + Host + " and Path: " + Path + " with Port: " + IntegerToString(Port) + " SSL=" + (string) UseSSL + " Insecure=" + (string) allowInsecure);
   } else {
      Host = lower_Url;
      LogError(0, "Set Host to: " + Host + " with Port: " + IntegerToString(Port) + " SSL=" + (string) UseSSL + " Insecure=" + (string) allowInsecure);
   }
   // Open connection
   if (!INet.Open(Host, Port, "", "", INTERNET_SERVICE_HTTP))
      return -1;
   if (method == "GET")
      req.Init(method, Path, Head, "", false, file, false, UseSSL, allowInsecure);
   if (method == "POST")
      req.Init(method, Path, Head, "", false, file, false, UseSSL, allowInsecure);
   INet.Request(req, data, result);
   result_headers = req.resHeader;
   return req.resCode;
}

void LogError(int level, string msg) {
   switch (level) {
   case 0:
      Print("++Webrequest2[INFO] " + msg);
      break;
   case 1:
      Print("--Webrequest2[WARN] " + msg);
      break;
   case 2:
      Print("--Webrequest2[ERROR] " + msg);
      break;
   }
}