//+------------------------------------------------------------------+
//|															 		   Webrequest2 |
//|                                      Copyright © 2018, T.Bossert |
//|                                     https://github.com/sirtoobii |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, T.Bossert"
#property link "https://github.com/sirtoobii"
#property version "1.00"
#property library
#property strict

// If not provided, set the Log Verbosity to 1
// Value 0: Show everything (Debug, Info, Warn and Error)
// Value 1: Show only Info, Warn and Error
// Value 2: Show only Warn and Error
// Value 3: Show only Error
// By default, show Info, Warn and Error
#ifndef WEBREQUEST2_LOG_LEVEL_MIN
   #define WEBREQUEST2_LOG_LEVEL_MIN 2
#endif

#define WEBREQUEST2_LOG_DEBUG 0
#define WEBREQUEST2_LOG_INFO 1
#define WEBREQUEST2_LOG_WARN 2
#define WEBREQUEST2_LOG_ERROR 3

// Set the same verbosity level for the INETHTTP library we will use in this script
#define INETHTTP_LOG_LEVEL_MIN WEBREQUEST2_LOG_LEVEL_MIN

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
   LogError(WEBREQUEST2_LOG_DEBUG, "Start of WebRequest2.");
   LogError(WEBREQUEST2_LOG_DEBUG, "URL:" + url);
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
      LogError(WEBREQUEST2_LOG_ERROR, "Please specifiy eighter a port or Http(s) with the url parameter");
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
      LogError(WEBREQUEST2_LOG_DEBUG, "Set Host to: " + Host + " and Path: " + Path + " with Port: " + IntegerToString(Port) + " SSL=" + (string) UseSSL + " Insecure=" + (string) allowInsecure);
   } else {
      Host = lower_Url;
      LogError(WEBREQUEST2_LOG_DEBUG, "Set Host to: " + Host + " with Port: " + IntegerToString(Port) + " SSL=" + (string) UseSSL + " Insecure=" + (string) allowInsecure);
   }

   // Open connection
   LogError(WEBREQUEST2_LOG_DEBUG, "Calling INet.Open ...");
   if (!INet.Open(Host, Port, "", "", INTERNET_SERVICE_HTTP))
      return -1;
   LogError(WEBREQUEST2_LOG_DEBUG, "Calling req.Init ...");
   if (method == "GET")
      req.Init(method, Path, Head, "", false, file, false, UseSSL, allowInsecure);
   if (method == "POST")
      req.Init(method, Path, Head, "", false, file, false, UseSSL, allowInsecure);
   LogError(WEBREQUEST2_LOG_DEBUG, "Calling INet.Request ...");
   INet.Request(req, data, result);
   result_headers = req.resHeader;
   LogError(WEBREQUEST2_LOG_DEBUG, "Calling INet.Close ...");
   INet.Close();
   LogError(WEBREQUEST2_LOG_DEBUG, "End of WebRequest2.");
   return req.resCode;
}

void LogError(int pLevel, string pMsg) {

   // If the log level is not at least the verbosity, do not show it
   if (pLevel < WEBREQUEST2_LOG_LEVEL_MIN) {
      return;
   } 

   switch (pLevel) {
   case WEBREQUEST2_LOG_DEBUG:
      Print("++WebRequest2[DEBUG] " + pMsg);
      break;
   case WEBREQUEST2_LOG_INFO:
      Print("++WebRequest2[INFO] " + pMsg);
      break;
   case WEBREQUEST2_LOG_WARN:
      Print("--WebRequest2[WARN] " + pMsg);
      break;
   case WEBREQUEST2_LOG_ERROR:
      Print("--WebRequest2[ERROR] " + pMsg);
      break;
   }
}