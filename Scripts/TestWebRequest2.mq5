#property copyright "Copyright 2023"
#property link ""
#property version "1.01"
#property description "TestWebRequest2"
#property strict

#define WEBREQUEST2_LOG_LEVEL_MIN 0 // Only show Warn and Error messages

#include "../Libraries/WebRequest2/WebRequest2.mq5"

// Input parameters
input string Input_HTTP_URL = "http://ifconfig.me/ip";
input string Input_HTTPS_URL = "https://ifconfig.me/ip";
// "https://nfs.faireconomy.media/ff_calendar_thisweek.xml";
input string Input_HTTPS_URL2 = "";

void OnStart() {

   string RequestHeaders = "";
   char Data[];
   char HTTPResult[];
   char HTTPSResult[];
   string HTTPResultHeaders;
   string HTTPSResultHeaders;
   int HTTPResponseCode;
   int HTTPSResponseCode;
   int TimeoutInMs = 1000;

   Print("TestWebRequest2 - Start of script");

   if (Input_HTTP_URL != "") {
      Print("TestWebRequest2 - Preparing sending request to " + Input_HTTP_URL);
      // Send the HTTP request
      HTTPResponseCode = WebRequest2("GET", Input_HTTP_URL, RequestHeaders, TimeoutInMs, Data, HTTPResult, HTTPResultHeaders);
      // Show the HTTP response
      Print("TestWebRequest2 - HTTP Response Code:" + (string) HTTPResponseCode);
      Print("TestWebRequest2 - HTTP Response:");
      Print("TestWebRequest2 - " + CharArrayToString(HTTPResult));
   
      // Sleep 2 seconds
      Sleep(2000);
      Print("TestWebRequest2 - ===================================");
   }
   
   if (Input_HTTPS_URL != "") {
      Print("TestWebRequest2 - Preparing sending request to " + Input_HTTPS_URL);
      // Send the HTTPS request
      HTTPSResponseCode = WebRequest2("GET", Input_HTTPS_URL, RequestHeaders, TimeoutInMs, Data, HTTPSResult, HTTPSResultHeaders);
      // Show the HTTPS response
      Print("TestWebRequest2 - HTTPS Response Code:" + (string) HTTPSResponseCode);
      Print("TestWebRequest2 - HTTPS Response:");
      Print("TestWebRequest2 - " + CharArrayToString(HTTPSResult));
   
      // Sleep 2 seconds
      Sleep(2000);
      Print("TestWebRequest2 - ===================================");
   }

   if (Input_HTTPS_URL2 != "") {
      Print("TestWebRequest2 - Preparing sending request to " + Input_HTTPS_URL2);
      // Send the HTTPS request
      HTTPSResponseCode = WebRequest2("GET", Input_HTTPS_URL2, RequestHeaders, TimeoutInMs, Data, HTTPSResult, HTTPSResultHeaders);
      // Show the HTTPS response
      Print("TestWebRequest2 - HTTPS Response Code:" + (string) HTTPSResponseCode);
      Print("TestWebRequest2 - HTTPS Response:");
      Print("TestWebRequest2 - " + CharArrayToString(HTTPSResult));
   }
   
   
   
   Print("TestWebRequest2 - End of script");
}
