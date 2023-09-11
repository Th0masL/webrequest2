# webrequest2
A more powerful, drop-in replacement for the Metatrader 5 Webrequest() method. Based on wininet.dll
#### Highlights
- Interface is fully compatible with the original [WebRequest()](https://www.mql5.com/en/docs/network/webrequest)
- Use non standard Ports
- Allow self signed ssl certs

#### Interface
```c++
int  WebRequest2(
   const string      method,                // HTTP method
   const string      url,                   // URL
   const string      headers,               // headers 
   int               timeout,               // timeout
   char              &data[],               // the array of the HTTP message body
   char              &result[],             // an array containing server response data
   string            &result_headers,       // headers of server response
   const int         port=NULL,             // Define custom port
   const bool        allowInsecure=false,   // Allow self signed certs
   const bool        useSSL=NULL            // Use SSL encrypted connection
   );
```
`Return value` HTTP server response code or -1 for an error.

#### Remarks
 If `allowInsecure` is set to `true` the following flags are set: 
 ```c++
 SECURITY_FLAG_IGNORE_UNKNOWN_CA
 INTERNET_FLAG_IGNORE_CERT_DATE_INVALID
 SECURITY_FLAG_IGNORE_CERT_CN_INVALID
 SECURITY_FLAG_IGNORE_REVOCATION
 ```
 Please note that these Settings make SSL nearly useless. Therefore this flag should never be used in a environment where security matters! For reference check out: https://docs.microsoft.com/en-us/windows/desktop/winhttp/option-flags
 
 The import "kernel32.dll" is used to retrieve the error messages.
 
 #### Usage
 1. Clone repo and copy the contents of `Libraries` folder into the corresponding folder of your MetaTrader installation.
 2. Allow DLLs in your Terminal
 3. Import Library:
```c++
#include <..\Libraries\WebRequest2\WebRequest2.mq5>
```

 #### Test the library

 You can use the script `Scripts/TestWebRequest2.mq5` as an example of how you can detect your Public IP by doing an HTTP/HTTPS request using this `WebRequest` library.

 1. Build the script `Scripts/TestWebRequest2.mq5` using MetaEditor
 2. Copy the file `TestWebRequest2.ex5` that has been built to the `Scripts` folder in your MetaTrader5 profile folder
 3. Open MetaTrader5 on a random chart
 4. Allow DLLs in your Terminal
 5. Load the script `TestWebRequest2.ex5` from the `Scripts` folder
 6. In the Terminal journal, verify that your Public IP address has been detected correctly
 
 #### Disclaimer
 You use this software at your own risk!
 PR's welcome :)