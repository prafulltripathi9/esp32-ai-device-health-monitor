import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class ApiService {
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData is Map<String, dynamic>) {
          return decodedData;
        }

        throw Exception('Invalid API response format');
      }

      throw Exception(
        'API Error: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}