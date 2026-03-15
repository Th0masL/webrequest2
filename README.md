# webrequest2

A more powerful, drop-in replacement for the Metatrader 5 Webrequest() method. Based on wininet.dll

#### Highlights

- Interface is fully compatible with the original [WebRequest()](https://www.mql5.com/en/docs/network/webrequest)
- Use non standard Ports
- Allow self signed ssl certs
- Configurable User-Agent string
- Receive timeout support
- Content-Length overflow protection
- Dynamic response reading (handles chunked/streaming responses)

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

 Please note that these Settings make SSL nearly useless. Therefore this flag should never be used in a environment where security matters! For reference check out: <https://docs.microsoft.com/en-us/windows/desktop/winhttp/option-flags>

 The import "kernel32.dll" is used to retrieve the error messages.

#### Configuration

The User-Agent string and log verbosity can be overridden before including the library:

```c++
// Optional: override User-Agent (default is Firefox)
#define INETHTTP_USER_AGENT "MyCustomAgent/1.0"

// Optional: set log verbosity (0=Debug, 1=Info, 2=Warn, 3=Error)
#define WEBREQUEST2_LOG_LEVEL_MIN 2

#include <WebRequest2/WebRequest2.mqh>
```

#### Usage

 1. Clone repo and copy the `Include/WebRequest2` folder into the `MQL5/Include` folder of your MetaTrader installation.
 2. Allow DLLs in your Terminal
 3. Include the library:

```c++
#include <WebRequest2/WebRequest2.mqh>
```

#### Test the library

A comprehensive test suite is provided in `Scripts/TestWebRequest2/TestWebRequest2.mq5` along with a PHP test server in `Server/webrequest2_test.php`.

##### Running the tests

 1. Deploy `Server/webrequest2_test.php` to a web server with PHP
 2. Build the script `Scripts/TestWebRequest2/TestWebRequest2.mq5` using MetaEditor
 3. Copy the built `TestWebRequest2.ex5` to the `Scripts` folder in your MetaTrader5 profile folder
 4. Open MetaTrader5 on a random chart
 5. Allow DLLs in your Terminal
 6. Load the script `TestWebRequest2.ex5` from the `Scripts` folder
 7. Set `Input_BaseURL` to point to your deployed PHP test server
 8. Check the Terminal journal for test results (53+ assertions across 18 test cases)

The test suite covers: status codes, empty/large bodies, Content-Length edge cases, timeouts, binary data, unicode, XML, custom/malformed headers, POST requests, redirects, and memory stress tests.

#### Disclaimer

 You use this software at your own risk!
 PR's welcome :)
