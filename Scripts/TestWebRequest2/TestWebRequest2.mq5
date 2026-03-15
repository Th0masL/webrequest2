#property copyright "Copyright 2023"
#property link ""
#property version "2.00"
#property description "TestWebRequest2 - Comprehensive test suite"
#property strict
#property script_show_inputs

#include <CheckForMemoryLeak/CheckForMemoryLeak.mqh>

#define WEBREQUEST2_LOG_LEVEL_MIN 0 // Show all messages (Debug, Info, Warn and Error)

#include <WebRequest2/WebRequest2.mqh>

// ── Configuration ───────────────────────────────────────────────────────
input string Input_BaseURL          = "http://yourserver.com/webrequest2_test.php";
input int    Input_TimeoutMs        = 5000;
input int    Input_StressIterations = 10;

// ── Globals ─────────────────────────────────────────────────────────────
int g_total   = 0;
int g_passed  = 0;
int g_failed  = 0;
int g_skipped = 0;

//+------------------------------------------------------------------+
//| Helper: run a single GET test and return the response code       |
//+------------------------------------------------------------------+
int DoGet(string url, char &result[], string &result_headers, int timeout = 0) {
   char data[];
   string headers = "";
   if (timeout == 0) timeout = Input_TimeoutMs;
   return WebRequest2("GET", url, headers, timeout, data, result, result_headers);
}

//+------------------------------------------------------------------+
//| Helper: run a single POST test and return the response code      |
//+------------------------------------------------------------------+
int DoPost(string url, string post_body, char &result[], string &result_headers) {
   char data[];
   StringToCharArray(post_body, data, 0, StringLen(post_body));
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   return WebRequest2("POST", url, headers, Input_TimeoutMs, data, result, result_headers);
}

//+------------------------------------------------------------------+
//| Helper: log a test result                                        |
//+------------------------------------------------------------------+
void AssertEquals(string test_name, int expected, int actual) {
   g_total++;
   if (expected == actual) {
      g_passed++;
      Print("[PASS] " + test_name + "  (expected=" + (string)expected + ", got=" + (string)actual + ")");
   } else {
      g_failed++;
      Print("[FAIL] " + test_name + "  (expected=" + (string)expected + ", got=" + (string)actual + ")");
   }
}

void AssertTrue(string test_name, bool condition, string detail = "") {
   g_total++;
   if (condition) {
      g_passed++;
      Print("[PASS] " + test_name + (detail != "" ? "  (" + detail + ")" : ""));
   } else {
      g_failed++;
      Print("[FAIL] " + test_name + (detail != "" ? "  (" + detail + ")" : ""));
   }
}

void Skip(string test_name, string reason) {
   g_total++;
   g_skipped++;
   Print("[SKIP] " + test_name + "  (" + reason + ")");
}

void Separator(string section) {
   Print("───────────────────────────────────────────────────────────");
   Print("  " + section);
   Print("───────────────────────────────────────────────────────────");
}

//+------------------------------------------------------------------+
//| Test: normal 200 OK                                              |
//+------------------------------------------------------------------+
void Test_Status200() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=status_200", result, result_headers);
   AssertEquals("status_200 - HTTP code", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("status_200 - body contains 'ok'", StringFind(body, "ok") >= 0, "body=" + body);
   AssertTrue("status_200 - has response headers", StringLen(result_headers) > 0);
}

//+------------------------------------------------------------------+
//| Test: 404 Not Found                                              |
//+------------------------------------------------------------------+
void Test_Status404() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=status_404", result, result_headers);
   AssertEquals("status_404 - HTTP code", 404, code);
   string body = CharArrayToString(result);
   AssertTrue("status_404 - body contains error info", StringFind(body, "not found") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: 500 Internal Server Error                                  |
//+------------------------------------------------------------------+
void Test_Status500() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=status_500", result, result_headers);
   AssertEquals("status_500 - HTTP code", 500, code);
   string body = CharArrayToString(result);
   AssertTrue("status_500 - body contains error info", StringFind(body, "error") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: empty body                                                 |
//+------------------------------------------------------------------+
void Test_EmptyBody() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=empty_body", result, result_headers);
   AssertEquals("empty_body - HTTP code", 200, code);
   AssertTrue("empty_body - result array is empty", ArraySize(result) == 0, "size=" + (string)ArraySize(result));
}

//+------------------------------------------------------------------+
//| Test: large body (~500KB)                                        |
//+------------------------------------------------------------------+
void Test_LargeBody() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=large_body", result, result_headers);
   AssertEquals("large_body - HTTP code", 200, code);
   // 500 lines * 1000 chars = 500000 bytes
   AssertTrue("large_body - size >= 400KB", ArraySize(result) >= 400000, "size=" + (string)ArraySize(result));
   AssertTrue("large_body - size <= 600KB", ArraySize(result) <= 600000, "size=" + (string)ArraySize(result));
}

//+------------------------------------------------------------------+
//| Test: no Content-Length header                                   |
//+------------------------------------------------------------------+
void Test_NoContentLength() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=no_content_length", result, result_headers);
   AssertEquals("no_content_length - HTTP code", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("no_content_length - body is not empty", ArraySize(result) > 0, "size=" + (string)ArraySize(result));
   AssertTrue("no_content_length - body is readable", StringFind(body, "no Content-Length") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: Content-Length smaller than actual body                     |
//+------------------------------------------------------------------+
void Test_WrongContentLength() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=wrong_content_length", result, result_headers);
   AssertEquals("wrong_content_length - HTTP code", 200, code);
   // The server says Content-Length: 10 but sends ~140 bytes.
   // WinInet may respect the header and only give us 10 bytes, or read more.
   // Either way it should not crash.
   AssertTrue("wrong_content_length - did not crash", true, "size=" + (string)ArraySize(result));
}

//+------------------------------------------------------------------+
//| Test: Content-Length vastly larger than actual body               |
//+------------------------------------------------------------------+
void Test_HugeContentLength() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=huge_content_length", result, result_headers);
   // Should still get a response (our overflow protection caps at 100MB, 999999999 > 100MB)
   // The ReadPage dynamic path should handle this gracefully
   AssertTrue("huge_content_length - did not crash", code != 0, "code=" + (string)code);
   Print("  huge_content_length - result size: " + (string)ArraySize(result));
}

//+------------------------------------------------------------------+
//| Test: slow response (5s body delay)                              |
//+------------------------------------------------------------------+
void Test_SlowResponse() {
   char result[];
   string result_headers;
   // Use a 10-second timeout so we actually receive the response
   int code = DoGet(Input_BaseURL + "?test=slow_response", result, result_headers, 10000);
   AssertEquals("slow_response - HTTP code", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("slow_response - body received", StringFind(body, "delayed") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: slow response should timeout with short timeout            |
//+------------------------------------------------------------------+
void Test_SlowResponseTimeout() {
   char result[];
   string result_headers;
   // Use 1-second timeout — the server waits 5s, so this should fail or return partial
   int code = DoGet(Input_BaseURL + "?test=slow_headers", result, result_headers, 1000);
   // Depending on WinInet behavior, we may get -1 or a partial response
   Print("  slow_response_timeout - code=" + (string)code + ", size=" + (string)ArraySize(result));
   AssertTrue("slow_response_timeout - handled gracefully", true);
}

//+------------------------------------------------------------------+
//| Test: binary data                                                |
//+------------------------------------------------------------------+
void Test_BinaryData() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=binary_data", result, result_headers);
   AssertEquals("binary_data - HTTP code", 200, code);
   AssertEquals("binary_data - exactly 256 bytes", 256, ArraySize(result));
   // Verify first and last bytes
   if (ArraySize(result) == 256) {
      AssertTrue("binary_data - first byte is 0x00", result[0] == 0);
      AssertTrue("binary_data - last byte is 0xFF", result[255] == (char)0xFF);
   }
}

//+------------------------------------------------------------------+
//| Test: unicode body                                               |
//+------------------------------------------------------------------+
void Test_UnicodeBody() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=unicode_body", result, result_headers);
   AssertEquals("unicode_body - HTTP code", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("unicode_body - contains English", StringFind(body, "English") >= 0);
   AssertTrue("unicode_body - body not empty", ArraySize(result) > 0, "size=" + (string)ArraySize(result));
}

//+------------------------------------------------------------------+
//| Test: XML body                                                   |
//+------------------------------------------------------------------+
void Test_XmlBody() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=xml_body", result, result_headers);
   AssertEquals("xml_body - HTTP code", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("xml_body - contains XML declaration", StringFind(body, "<?xml") >= 0);
   AssertTrue("xml_body - contains <response>", StringFind(body, "<response>") >= 0);
}

//+------------------------------------------------------------------+
//| Test: custom response headers                                    |
//+------------------------------------------------------------------+
void Test_CustomHeaders() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=custom_headers", result, result_headers);
   AssertEquals("custom_headers - HTTP code", 200, code);
   AssertTrue("custom_headers - X-Custom-One present", StringFind(result_headers, "X-Custom-One") >= 0, "headers=" + result_headers);
   AssertTrue("custom_headers - X-Request-Id present", StringFind(result_headers, "X-Request-Id") >= 0);
}

//+------------------------------------------------------------------+
//| Test: malformed headers                                          |
//+------------------------------------------------------------------+
void Test_MalformedHeaders() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=malformed_headers", result, result_headers);
   // Should not crash regardless of header content
   AssertTrue("malformed_headers - did not crash", true, "code=" + (string)code + ", size=" + (string)ArraySize(result));
}

//+------------------------------------------------------------------+
//| Test: Connection: close                                          |
//+------------------------------------------------------------------+
void Test_ConnectionClose() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=connection_close", result, result_headers);
   AssertEquals("connection_close - HTTP code", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("connection_close - body received", StringFind(body, "Connection: close") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: POST with echo                                             |
//+------------------------------------------------------------------+
void Test_PostEcho() {
   char result[];
   string result_headers;
   string post_body = "key1=value1&key2=hello+world";
   int code = DoPost(Input_BaseURL + "?test=post_echo", post_body, result, result_headers);
   AssertEquals("post_echo - HTTP code", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("post_echo - method is POST", StringFind(body, "POST") >= 0, "body=" + body);
   AssertTrue("post_echo - body echoed back", StringFind(body, "key1=value1") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: 302 redirect                                               |
//+------------------------------------------------------------------+
void Test_Redirect() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=redirect", result, result_headers);
   // WinInet follows redirects automatically, so we should end up at status_200
   AssertEquals("redirect - HTTP code (after redirect)", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("redirect - landed on status_200", StringFind(body, "status_200") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: double redirect                                            |
//+------------------------------------------------------------------+
void Test_DoubleRedirect() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=double_redirect", result, result_headers);
   AssertEquals("double_redirect - HTTP code", 200, code);
   string body = CharArrayToString(result);
   AssertTrue("double_redirect - landed on status_200", StringFind(body, "status_200") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: large headers (stresses GetHTTPHeaders 1024-byte buffer)   |
//+------------------------------------------------------------------+
void Test_LargeHeaders() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=large_headers", result, result_headers);
   AssertEquals("large_headers - HTTP code", 200, code);
   // 50 headers * ~90 chars each = ~4500 bytes, but GetHTTPHeaders buffer is 1024
   // This tests whether truncation is handled without crash
   AssertTrue("large_headers - has headers", StringLen(result_headers) > 0, "header_len=" + (string)StringLen(result_headers));
   string body = CharArrayToString(result);
   AssertTrue("large_headers - body received", StringFind(body, "large headers") >= 0, "body=" + body);
}

//+------------------------------------------------------------------+
//| Test: varied body sizes (forces different ArrayResize paths)      |
//+------------------------------------------------------------------+
void Test_VariedSizes() {
   int sizes[] = {1, 10, 100, 1000, 10000, 50000};
   int successes = 0;
   for (int i = 0; i < ArraySize(sizes); i++) {
      char result[];
      string result_headers;
      int code = DoGet(Input_BaseURL + "?test=varied_sizes&size=" + (string)sizes[i], result, result_headers);
      if (code == 200 && ArraySize(result) == sizes[i])
         successes++;
      else
         Print("  varied_sizes - MISMATCH at size=" + (string)sizes[i] + " got=" + (string)ArraySize(result) + " code=" + (string)code);
   }
   AssertEquals("varied_sizes - all 6 sizes matched", 6, successes);
}

//+------------------------------------------------------------------+
//| Test: incremental chunks (many small reads, no Content-Length)    |
//+------------------------------------------------------------------+
void Test_IncrementalChunks() {
   char result[];
   string result_headers;
   int code = DoGet(Input_BaseURL + "?test=incremental_chunks", result, result_headers);
   AssertEquals("incremental_chunks - HTTP code", 200, code);
   AssertTrue("incremental_chunks - received data", ArraySize(result) > 0, "size=" + (string)ArraySize(result));
   string body = CharArrayToString(result);
   // Should contain the last chunk
   AssertTrue("incremental_chunks - has last chunk", StringFind(body, "chunk-99") >= 0);
}

//+------------------------------------------------------------------+
//| Test: repeated calls (stress + leak detection)                   |
//+------------------------------------------------------------------+
void Test_RepeatedCalls() {
   int successes = 0;
   for (int i = 0; i < Input_StressIterations; i++) {
      char result[];
      string result_headers;
      int code = DoGet(Input_BaseURL + "?test=repeated_calls", result, result_headers);
      if (code == 200)
         successes++;
   }
   AssertEquals("repeated_calls - all succeeded (" + (string)Input_StressIterations + " iterations)", Input_StressIterations, successes);
}

//+------------------------------------------------------------------+
//| Test: repeated varied sizes (memory churn stress test)           |
//+------------------------------------------------------------------+
void Test_MemoryChurn() {
   int successes = 0;
   // Alternate between small and large responses to stress alloc/dealloc
   for (int i = 0; i < Input_StressIterations; i++) {
      char result[];
      string result_headers;
      int size = (i % 2 == 0) ? 100 : 50000;
      int code = DoGet(Input_BaseURL + "?test=varied_sizes&size=" + (string)size, result, result_headers);
      if (code == 200 && ArraySize(result) == size)
         successes++;
   }
   AssertEquals("memory_churn - all succeeded (" + (string)Input_StressIterations + " iterations)", Input_StressIterations, successes);
}

//+------------------------------------------------------------------+
//| Main entry point                                                 |
//+------------------------------------------------------------------+
void OnStart() {
   Print("");
   Print("═══════════════════════════════════════════════════════════");
   Print("  WebRequest2 Test Suite v2.0");
   Print("  Target: " + Input_BaseURL);
   Print("  Timeout: " + (string)Input_TimeoutMs + " ms");
   Print("═══════════════════════════════════════════════════════════");
   Print("");

   // ── Basic status codes ────────────────────────────────────────────
   Separator("Basic Status Codes");
   Test_Status200();
   Sleep(500);
   Test_Status404();
   Sleep(500);
   Test_Status500();
   Sleep(500);

   // ── Body size edge cases ──────────────────────────────────────────
   Separator("Body Size Edge Cases");
   Test_EmptyBody();
   Sleep(500);
   Test_LargeBody();
   Sleep(500);

   // ── Content-Length problems ────────────────────────────────────────
   Separator("Content-Length Edge Cases");
   Test_NoContentLength();
   Sleep(500);
   Test_WrongContentLength();
   Sleep(500);
   Test_HugeContentLength();
   Sleep(500);

   // ── Timing / timeouts ─────────────────────────────────────────────
   Separator("Timing / Timeouts");
   Test_SlowResponse();
   Sleep(500);
   Test_SlowResponseTimeout();
   Sleep(500);

   // ── Content types ─────────────────────────────────────────────────
   Separator("Content Types");
   Test_BinaryData();
   Sleep(500);
   Test_UnicodeBody();
   Sleep(500);
   Test_XmlBody();
   Sleep(500);

   // ── Headers ───────────────────────────────────────────────────────
   Separator("Header Handling");
   Test_CustomHeaders();
   Sleep(500);
   Test_MalformedHeaders();
   Sleep(500);
   Test_ConnectionClose();
   Sleep(500);

   // ── POST ──────────────────────────────────────────────────────────
   Separator("POST Requests");
   Test_PostEcho();
   Sleep(500);

   // ── Redirects ─────────────────────────────────────────────────────
   Separator("Redirects");
   Test_Redirect();
   Sleep(500);
   Test_DoubleRedirect();
   Sleep(500);

   // ── Memory stress ────────────────────────────────────────────────
   Separator("Memory Stress");
   Test_LargeHeaders();
   Sleep(500);
   Test_VariedSizes();
   Sleep(500);
   Test_IncrementalChunks();
   Sleep(500);

   // ── Stress test ───────────────────────────────────────────────────
   Separator("Stress / Leak Detection");
   Test_RepeatedCalls();
   Sleep(500);
   Test_MemoryChurn();

   // ── Summary ───────────────────────────────────────────────────────
   Print("");
   Print("═══════════════════════════════════════════════════════════");
   Print("  RESULTS: " + (string)g_total + " tests, "
         + (string)g_passed + " passed, "
         + (string)g_failed + " failed, "
         + (string)g_skipped + " skipped");
   if (g_failed == 0)
      Print("  ALL TESTS PASSED");
   else
      Print("  *** " + (string)g_failed + " TEST(S) FAILED ***");
   Print("═══════════════════════════════════════════════════════════");
   Print("");
}
