<?php
/**
 * WebRequest2 Test Server
 *
 * Usage: http://yourserver/webrequest2_test.php?test=<test_name>
 *
 * Test cases:
 *   status_200          - Normal 200 OK with JSON body
 *   status_404          - 404 Not Found with error body
 *   status_500          - 500 Internal Server Error with error body
 *   empty_body          - 200 OK with zero-length body
 *   large_body          - 200 OK with ~500KB body (tests buffer handling)
 *   no_content_length   - Response with Content-Length header removed (chunked)
 *   wrong_content_length- Content-Length says 10 but body is much larger
 *   huge_content_length - Content-Length claims 999999999 but sends small body
 *   slow_response       - 200 OK but body arrives after 5 seconds delay
 *   slow_headers        - Headers arrive after 5 seconds delay
 *   binary_data         - 200 OK with binary (non-UTF8) payload
 *   custom_headers      - 200 OK with several custom response headers
 *   post_echo           - Echoes back the POST body and headers as JSON
 *   redirect            - 302 redirect to ?test=status_200
 *   double_redirect     - Two chained redirects
 *   malformed_headers   - Sends syntactically broken headers
 *   connection_close    - Sends Connection: close header
 *   unicode_body        - Body with multi-byte UTF-8 characters
 *   xml_body            - XML response with appropriate content-type
 *   repeated_calls      - Normal response (caller should hit this N times)
 *   (none / unknown)    - Returns a help page listing all tests
 */

$test = isset($_GET['test']) ? $_GET['test'] : '';

switch ($test) {

    // ── Basic status codes ──────────────────────────────────────────────
    case 'status_200':
        header('Content-Type: application/json');
        echo json_encode([
            'status'  => 'ok',
            'test'    => 'status_200',
            'message' => 'This is a normal 200 response.',
        ]);
        break;

    case 'status_404':
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode([
            'status'  => 'error',
            'test'    => 'status_404',
            'message' => 'Resource not found.',
        ]);
        break;

    case 'status_500':
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode([
            'status'  => 'error',
            'test'    => 'status_500',
            'message' => 'Internal server error.',
        ]);
        break;

    // ── Body size edge cases ────────────────────────────────────────────
    case 'empty_body':
        header('Content-Type: text/plain');
        // Intentionally send nothing
        break;

    case 'large_body':
        header('Content-Type: text/plain');
        // ~500KB of data in 500 lines of 1000 chars each
        $line = str_repeat('A', 999) . "\n";
        for ($i = 0; $i < 500; $i++) {
            echo $line;
        }
        break;

    // ── Content-Length mismatch scenarios ────────────────────────────────
    case 'no_content_length':
        // Response without Content-Length — nginx will use chunked transfer encoding,
        // which means the client won't get a Content-Length header to pre-allocate with
        header('Content-Type: text/plain');
        $body = 'This response has no Content-Length header. The client must read until the connection closes.';
        echo $body;
        break;

    case 'wrong_content_length':
        $body = 'This body is much longer than the Content-Length header claims. '
              . 'The extra data should still be readable if the client handles this correctly.';
        header('Content-Type: text/plain');
        header('Content-Length: 10');  // Lie: says 10, actual is ~140+
        echo $body;
        break;

    case 'huge_content_length':
        $body = 'Small body.';
        header('Content-Type: text/plain');
        header('Content-Length: 999999999');  // Way larger than actual
        echo $body;
        // Close immediately — client should handle the disconnect
        break;

    // ── Timing / timeout scenarios ──────────────────────────────────────
    case 'slow_response':
        header('Content-Type: text/plain');
        // Flush headers immediately, then delay the body
        ob_end_flush();
        flush();
        sleep(5);
        echo 'This response was delayed by 5 seconds.';
        break;

    case 'slow_headers':
        // Delay before sending anything at all
        sleep(5);
        header('Content-Type: text/plain');
        echo 'Headers were delayed by 5 seconds.';
        break;

    // ── Special content types ───────────────────────────────────────────
    case 'binary_data':
        header('Content-Type: application/octet-stream');
        // 256 bytes: 0x00..0xFF
        $bin = '';
        for ($i = 0; $i < 256; $i++) {
            $bin .= chr($i);
        }
        echo $bin;
        break;

    case 'unicode_body':
        header('Content-Type: text/plain; charset=utf-8');
        echo "Hello World - English\n";
        echo "Héllo Wörld - Accented\n";
        echo "こんにちは世界 - Japanese\n";
        echo "Привет мир - Russian\n";
        echo "🌍🌎🌏 - Emoji\n";
        break;

    case 'xml_body':
        header('Content-Type: application/xml');
        echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
        echo "<response>\n";
        echo "  <status>ok</status>\n";
        echo "  <test>xml_body</test>\n";
        echo "  <message>This is an XML response.</message>\n";
        echo "  <items>\n";
        for ($i = 1; $i <= 5; $i++) {
            echo "    <item id=\"$i\">Item $i</item>\n";
        }
        echo "  </items>\n";
        echo "</response>\n";
        break;

    // ── Header scenarios ────────────────────────────────────────────────
    case 'custom_headers':
        header('Content-Type: application/json');
        header('X-Custom-One: value-one');
        header('X-Custom-Two: value-two');
        header('X-Request-Id: test-12345');
        header('X-Timestamp: ' . time());
        echo json_encode([
            'status'  => 'ok',
            'test'    => 'custom_headers',
            'message' => 'Check the response headers for X-Custom-* values.',
        ]);
        break;

    case 'malformed_headers':
        // Send raw output to bypass PHP's header handling
        header('Content-Type: text/plain');
        header("X-Bad-Header-1: value\x00with-null");
        header("X-Bad-Header-2: line1\r\n continued");
        echo 'Response with unusual headers.';
        break;

    case 'connection_close':
        header('Content-Type: text/plain');
        header('Connection: close');
        echo 'This response includes Connection: close.';
        break;

    // ── POST handling ───────────────────────────────────────────────────
    case 'post_echo':
        header('Content-Type: application/json');
        $raw_body = file_get_contents('php://input');
        echo json_encode([
            'status'         => 'ok',
            'test'           => 'post_echo',
            'method'         => $_SERVER['REQUEST_METHOD'],
            'content_type'   => isset($_SERVER['CONTENT_TYPE']) ? $_SERVER['CONTENT_TYPE'] : '',
            'content_length' => isset($_SERVER['CONTENT_LENGTH']) ? (int)$_SERVER['CONTENT_LENGTH'] : 0,
            'body'           => $raw_body,
            'body_length'    => strlen($raw_body),
        ]);
        break;

    // ── Redirects ───────────────────────────────────────────────────────
    case 'redirect':
        $base = strtok($_SERVER['REQUEST_URI'], '?');
        header('Location: ' . $base . '?test=status_200');
        http_response_code(302);
        echo 'Redirecting...';
        break;

    case 'double_redirect':
        $base = strtok($_SERVER['REQUEST_URI'], '?');
        header('Location: ' . $base . '?test=redirect');
        http_response_code(302);
        echo 'Redirecting (step 1 of 2)...';
        break;

    // ── Memory stress scenarios ────────────────────────────────────────
    case 'large_headers':
        // Response with many headers — stresses GetHTTPHeaders() 1024-byte buffer
        // Keep under nginx's default proxy_buffer_size (4k/8k)
        header('Content-Type: text/plain');
        for ($i = 0; $i < 20; $i++) {
            header('X-Stress-' . $i . ': ' . str_repeat('v', 40));
        }
        echo 'Response with ~20 large headers.';
        break;

    case 'varied_sizes':
        // Returns a body of the size specified by ?size= (default 1000)
        // Useful for testing many different ArrayResize paths
        $size = isset($_GET['size']) ? max(1, min(1000000, (int)$_GET['size'])) : 1000;
        header('Content-Type: text/plain');
        echo str_repeat('X', $size);
        break;

    case 'incremental_chunks':
        // Sends body in small incremental flushes — forces many read iterations
        // and repeated ArrayResize when Content-Length is missing
        header('Content-Type: text/plain');
        header('X-Accel-Buffering: no');  // Tell nginx not to buffer
        for ($i = 0; $i < 100; $i++) {
            echo "chunk-$i:" . str_repeat('.', 50) . "\n";
            if (ob_get_level()) ob_flush();
            flush();
        }
        break;

    // ── Repeated calls (for stress / leak detection) ────────────────────
    case 'repeated_calls':
        header('Content-Type: application/json');
        echo json_encode([
            'status'    => 'ok',
            'test'      => 'repeated_calls',
            'timestamp' => microtime(true),
            'memory'    => memory_get_usage(),
        ]);
        break;

    // ── Default: help page ──────────────────────────────────────────────
    default:
        header('Content-Type: text/plain');
        echo "WebRequest2 Test Server\n";
        echo "=======================\n\n";
        echo "Usage: ?test=<test_name>\n\n";
        echo "Available tests:\n";
        $tests = [
            'status_200'          => 'Normal 200 OK with JSON body',
            'status_404'          => '404 Not Found with error body',
            'status_500'          => '500 Internal Server Error',
            'empty_body'          => '200 OK with empty body',
            'large_body'          => '~500KB response body',
            'no_content_length'   => 'Response without Content-Length',
            'wrong_content_length'=> 'Content-Length smaller than actual body',
            'huge_content_length' => 'Content-Length vastly larger than actual body',
            'slow_response'       => '5s delay before body',
            'slow_headers'        => '5s delay before headers',
            'binary_data'         => '256 bytes of binary (0x00-0xFF)',
            'unicode_body'        => 'Multi-language UTF-8 text',
            'xml_body'            => 'XML response',
            'custom_headers'      => 'Response with custom X- headers',
            'malformed_headers'   => 'Headers with unusual characters',
            'connection_close'    => 'Response with Connection: close',
            'post_echo'           => 'Echoes POST body and headers as JSON',
            'redirect'            => '302 redirect to status_200',
            'double_redirect'     => 'Two chained 302 redirects',
            'large_headers'       => '50 large custom headers (~4KB of headers)',
            'varied_sizes'        => 'Body of ?size=N bytes (1-1000000)',
            'incremental_chunks'  => '100 small flushed chunks (no Content-Length)',
            'repeated_calls'      => 'Simple response for stress testing',
        ];
        foreach ($tests as $name => $desc) {
            echo "  $name" . str_repeat(' ', 24 - strlen($name)) . "- $desc\n";
        }
        break;
}
