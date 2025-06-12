// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl =
      "https://reg-model-deffhegbbac0anfx.switzerlandnorth-01.azurewebsites.net";

  // (OCR endpoint here)
  static const String ocrEndpoint = "http://4.182.248.150:5000/ocr";

  /// ⏳ Waiting Time Prediction
  /// Returns the first element of "Q50_prediction" as a String, or null on failure.
  static Future<String?> fetchWaitingTime({
    required int age,
    required String gender,
    required String from,
    required String to,
    required String time,
    required String isRainy,
    required String isWeekend,
  }) async {
    final uri = Uri.parse("$baseUrl/predict");
    final payload = {
      "Age": age,
      "Gender": gender,
      "From": from,
      "To": to,
      "Time": time,
      "IsRainy": isRainy,
      "IsWeekend": isWeekend,
    };

    print("📤 Sending POST to $uri");
    print("📝 Request Body: ${jsonEncode(payload)}");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("📥 Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;

        // Grab Q50_prediction (an array) and return its first element
        final q50List = bodyJson["Q50_prediction"] as List<dynamic>?;
        if (q50List != null && q50List.isNotEmpty) {
          return q50List[0].toString();
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print("❌ Exception during API call: $e");
      return null;
    }
  }

  /// 🔍 OCR Text Extraction (unchanged)

  /// 🔍 OCR Text Extraction via multipart/form-data
  /// Expects JSON of the form:
  /// {
  ///   "detected_text": ["line1", "line2", …]
  /// }
  /// Posts the image file itself (not Base64) under the `image` field,
  /// parses the `"detected_text"` array, and returns it joined with spaces.
  static Future<String?> extractTextFromImage(String imagePath) async {
    final uri = Uri.parse(ocrEndpoint);
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    print("📤 OCR multipart POST → $uri");
    print("    imagePath: $imagePath");

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print("📥 OCR status: ${response.statusCode}");
    print("📥 OCR body:   ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> map = jsonDecode(response.body);
      final List<dynamic>? lines = map['detected_text'] as List<dynamic>?;
      if (lines != null && lines.isNotEmpty) {
        // join all lines into a single string
        return lines.map((e) => e.toString()).join(' ');
      }
    }
    return null;
  }
}




