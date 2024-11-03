import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;

  GeminiService(this.apiKey);

  Future<String?> getClassificationNumber(String title, String abstract) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );

    final chat = model.startChat();
    final prompt =
        "Give me the classification number (ddc) of this thesis: '$title'. ABSTRACT: '$abstract'. JUST GIVE ME THE NUMBER. NO OTHER CHARACTERS";
    final content = Content.text(prompt);

    final response = await chat.sendMessage(content);
    return response.text?.trim(); // Return the classification number
  }

  Future<String?> getSubjects(String title, String abstract) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );

    final chat = model.startChat();
    final prompt =
        "Give me the subjects of this TITLE: '$title'. ABSTRACT: '$abstract'. \n\nNUMBER THE RESULTS ALSO NO '*' CHARACTERS IN BETWEEN OF SUBJECTS, JUST THE SUBJECTS NO NEED DESCRIPTIONS.";
    final content = Content.text(prompt);

    final response = await chat.sendMessage(content);
    return response.text?.trim(); // Return the subjects
  }
}
