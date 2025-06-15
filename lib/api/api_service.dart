// api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://reg-model-deffhegbbac0anfx.switzerlandnorth-01.azurewebsites.net"; // ML model server
  static const String backendBaseUrl =
      "https://graduation-project-production-39f0.up.railway.app"; // Railway backend

  static const String ocrEndpoint = "http://4.182.248.150:5000/ocr";

  /// 🔄 Fetch waiting time predictions (Q25, Q50, Q75)
  static Future<Map<String, dynamic>?> fetchWaitingTimeFull({
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

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("❌ Model response error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception during waiting time call: $e");
      return null;
    }
  }

  /// 💰 Fetch route price from the database
  static Future<String?> fetchPrice({
    required String from,
    required String to,
  }) async {
    final uri = Uri.parse("$backendBaseUrl/get_price?from=$from&to=$to");

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['price'];
      } else {
        print("❌ Failed to fetch price: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching price: $e");
      return null;
    }
  }

  /// 🔍 OCR text extraction using a separate ML service
  static Future<String?> extractTextFromImage(String imagePath) async {
    final uri = Uri.parse(ocrEndpoint);
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final Map<String, dynamic> map = jsonDecode(response.body);
        final List<dynamic>? lines = map['detected_text'] as List<dynamic>?;
        if (lines != null && lines.isNotEmpty) {
          return lines.map((e) => e.toString()).join(' ');
        }
      }
      return null;
    } catch (e) {
      print("❌ OCR error: $e");
      return null;
    }
  }
}





