#property copyright "Copyright 2023"
#property link ""
#property version "1.00"
#property description "TestWebRequest2"

#include "../Libraries/WebRequest2/WebRequest2.mq5"

// Input parameters
input string Input_HTTP_URL = "http://ifconfig.me/ip";
input string Input_HTTPS_URL = "https://ifconfig.me/ip";

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

   // Send the HTTP request
   HTTPResponseCode = WebRequest2("GET", Input_HTTP_URL, RequestHeaders, TimeoutInMs, Data, HTTPResult, HTTPResultHeaders);

   // Show the HTTP response
   Print("HTTP Response Code:" + (string) HTTPResponseCode);
   Print("HTTP Response:");
   Print(CharArrayToString(HTTPResult));

   // Sleep 2 seconds
   Sleep(2000);

   // Send the HTTPS request
   HTTPSResponseCode = WebRequest2("GET", Input_HTTPS_URL, RequestHeaders, TimeoutInMs, Data, HTTPSResult, HTTPSResultHeaders);

   // Show the HTTPS response
   Print("HTTPS Response Code:" + (string) HTTPSResponseCode);
   Print("HTTPS Response:");
   Print(CharArrayToString(HTTPSResult));
}