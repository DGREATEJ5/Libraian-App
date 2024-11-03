import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> processText(String text) async {
  final url = Uri.parse('https://final-thesis-model-a5eb5b7e0b84.herokuapp.com/predict');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'text': text}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to process text');
  }
}
