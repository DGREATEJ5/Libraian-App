import 'dart:convert';
import 'package:http/http.dart' as http;

class CutterNumberService {
  final String baseUrl;

  CutterNumberService(this.baseUrl);

  Future<String?> getCutterNumber(String author, String title) async {
    final url = Uri.parse('$baseUrl/get-cutter-number');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'author': author, 'title': title}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['cutter_number'];
    } else {
      throw Exception('Failed to retrieve Cutter Number');
    }
  }
}
