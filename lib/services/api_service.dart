import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://kathline-subcutaneous-irreconcilably.ngrok-free.dev/api";

  static Future<String> checkHealth() async {
    final response = await http.get(
      Uri.parse("$baseUrl/health"),
      headers: {'ngrok-skip-browser-warning': 'true'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["message"] as String;
    }
    throw Exception("Failed to connect to backend");
  }

  static Future<Map<String, dynamic>> analyzePrescription(
    File imageFile, {
    String lang = "en",
    String? userId,
  }) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/prescription"),
    );

    request.headers['ngrok-skip-browser-warning'] = 'true';

    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );
    request.fields['lang'] = lang;
    if (userId != null) {
      request.fields['user_id'] = userId;
    }

    var response = await request.send();

    var responseData = await response.stream.bytesToString();
    return json.decode(responseData);
  }

  static Future<Map<String, dynamic>> analyzeMedicalReport(File reportFile,
      {String lang = "en", String? userId}) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/report"),
    );
    request.headers['ngrok-skip-browser-warning'] = 'true';

    request.files.add(
      await http.MultipartFile.fromPath("file", reportFile.path),
    );
    request.fields['lang'] = lang;
    if (userId != null) {
      request.fields['user_id'] = userId;
    }

    var response = await request.send();

    var responseData = await response.stream.bytesToString();

    final decoded = json.decode(responseData);

    return decoded;
  }

  static Future<String> analyzeSkin(File imageFile,
      {String lang = "en", String? userId}) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/skin"),
    );
    request.headers['ngrok-skip-browser-warning'] = 'true';

    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );
    request.fields['lang'] = lang;
    if (userId != null) {
      request.fields['user_id'] = userId;
    }

    var response = await request.send();

    var responseData = await response.stream.bytesToString();

    final decoded = json.decode(responseData);

    return decoded["analysis"];
  }

  static Future<String> queryAssistant(String query,
      {String lang = "en"}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/chat"),
      headers: {'ngrok-skip-browser-warning': 'true'},
      body: {
        'query': query,
        'lang': lang,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["response"] as String;
    }
    throw Exception("Failed to get assistant response");
  }

  static Future<String> checkSymptoms(String symptoms,
      {String? userId, String lang = 'en'}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/symptoms"),
      headers: {
        "Content-Type": "application/json",
        'ngrok-skip-browser-warning': 'true'
      },
      body: jsonEncode({
        "symptoms": symptoms,
        "lang": lang,
        if (userId != null) "user_id": userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["response"] as String;
    }
    throw Exception("Failed to check symptoms");
  }

  static Future<Map<String, dynamic>> getHealthSummary(String userId,
      {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse("$baseUrl/health-summary?user_id=$userId&lang=$lang"),
      headers: {'ngrok-skip-browser-warning': 'true'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Failed to fetch health summary");
  }
}
