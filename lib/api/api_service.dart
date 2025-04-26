// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ← your new regression endpoint
  static const String baseUrl =
      "https://reg-model-deffhegbbac0anfx.switzerlandnorth-01.azurewebsites.net";

  // (You still have your OCR endpoint here if needed, but we’re focusing on /predict today.)
  static const String ocrEndpoint = "http://72.146.224.5:5000/ocr";

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
  static Future<String?> extractTextFromImage(String base64Image) async {
    final uri = Uri.parse(ocrEndpoint);
    final payload = {"image": base64Image};

    print("📤 Sending OCR POST to $uri");
    print("📝 OCR Body: ${jsonEncode(payload)}");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("📥 OCR Status Code: ${response.statusCode}");
      print("📥 OCR Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result["text"];
      } else {
        return null;
      }
    } catch (e) {
      print("❌ OCR Exception: $e");
      return null;
    }
  }
}




