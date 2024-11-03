import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiServiceBooks {
  final String apiKey;

  GeminiServiceBooks(this.apiKey);

  Future<String?> extractBookDetails(String extractedText) async {
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
        "from this book can u get the Title, Volume(optional if there is, one only), Edition(optional if there is, one only), Author(s), Copyright(remove special character c, get from first Copyright word to the first dot), ISBN (include ISBN word. "
        "put it in one paragraph, dont put new characters just combine it by not putting comma. Add ',' for every Author(s). dont do it like Title: like that. Dont put anything that isnt from the text. (extracted text: $extractedText)";

    final content = Content.text(prompt);

    final response = await chat.sendMessage(content);
    return response.text?.trim(); // Return the processed text as the book details
  }
}
