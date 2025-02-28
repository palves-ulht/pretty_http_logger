import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:test/test.dart';
import 'package:http_parser/http_parser.dart';


void main() {

  group('HttpClientWithMiddleware Tests', ()
  {
    late MockClient mockClient;
    late HttpClientWithMiddleware httpClientWithMiddleware;
    late StringBuffer buffer;
    late ZoneSpecification spec;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"id": 1, "title": "Test Post"}', 200, request: request);
      });
      httpClientWithMiddleware = HttpClientWithMiddleware.build(
        client: mockClient,
          middlewares: [
            HttpLogger(logLevel: LogLevel.BODY),
          ]);
      buffer = StringBuffer();
      spec = ZoneSpecification(
        print: (_, __, ___, String msg) {
          buffer.writeln(msg); // Capture print statements
        },
      );
    });

    test('Logs GET request and response', () async {
      // Arrange: Mock HTTP GET request
      final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');

      // Act: Perform HTTP request in a custom zone with overridden print behavior
      await Zone.current.fork(specification: spec).run(() async {
        var response = await httpClientWithMiddleware.get(url);
        expect(response.statusCode, 200);
      });

      expect(buffer.toString().trim(),
      '''
╔╣ Request ║ Method.GET 
║  https://jsonplaceholder.typicode.com/posts/1
╚══════════════════════════════════════════════════════════════════════════════════════════╝

╔╣ Response ║ Method.GET ║ Status: 200
║  https://jsonplaceholder.typicode.com/posts/1
╚══════════════════════════════════════════════════════════════════════════════════════════╝
╔ Body
║
║    {
║         id: 1,
║         title: "Test Post"
║    }
║
╚══════════════════════════════════════════════════════════════════════════════════════════╝''');
    });

    test('Send multi-part request', () async {
      // Arrange: Mock HTTP GET request
      final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');

      // Act: Perform HTTP request in a custom zone with overridden print behavior
      await Zone.current.fork(specification: spec).run(() async {
        var request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Token xxx';
        request.fields['field1'] = "value1";
        request.files.add(http.MultipartFile.fromString(
          'raw_file',
          'file content',
          filename: 'file.txt',
          contentType: MediaType('text', 'plain'),
        ));
        var response = await httpClientWithMiddleware.send(request);
        expect(response.statusCode, 200);
      });

      expect(buffer.toString().trim(),
          '''
╔╣ Request ║ Method.POST 
║  https://jsonplaceholder.typicode.com/posts/1
╚══════════════════════════════════════════════════════════════════════════════════════════╝
╔ Query Parameters 
╟ Authorization: Token xxx
╚══════════════════════════════════════════════════════════════════════════════════════════╝
╔ Form _data | 408 
╟ field1: value1
╟ fileName: file.txt
╟ field: raw_file
╟ contentType: text/plain; charset=utf-8
╚══════════════════════════════════════════════════════════════════════════════════════════╝

╔╣ Response ║ Method.POST ║ Status: 200
║  https://jsonplaceholder.typicode.com/posts/1
╚══════════════════════════════════════════════════════════════════════════════════════════╝
╔ Body
║
║    {
║         id: 1,
║         title: "Test Post"
║    }
║
╚══════════════════════════════════════════════════════════════════════════════════════════╝''');
    });
  });
}
