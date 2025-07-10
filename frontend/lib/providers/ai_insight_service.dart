import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/ai_insight_model.dart';
import '../utils/api_config.dart';

class AiInsightService {
  static Future<AiInsightResponse> queryInsight({
    required String query,
    required String token,
    String? tenantId,
  }) async {
    try {
      // Fallback ke URL config jika NetworkService gagal
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/ai-insight/query');
      
      final body = AiInsightQuery(
        query: query,
        tenantId: tenantId,
      ).toJson();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AiInsightResponse.fromJson(data);
      } else {
        throw Exception('Failed to get AI insight: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AI Insight Service Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<List<ChatMessage>> getChatHistory({
    required String token,
    String? tenantId,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/ai-insight/chat-history');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (tenantId != null) 'tenantId': tenantId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return ChatMessage(
            id: item['id'] ?? '',
            message: item['message'] ?? '',
            isUser: item['isUser'] ?? false,
            timestamp: DateTime.parse(item['timestamp'] ?? DateTime.now().toIso8601String()),
            aiResponse: item['aiResponse'] != null 
                ? AiInsightResponse.fromJson(item['aiResponse'])
                : null,
          );
        }).toList();
      } else {
        throw Exception('Failed to get chat history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Chat History Service Error: $e');
      return []; // Return empty list on error
    }
  }
}
