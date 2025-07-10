class AiInsightQuery {
  final String query;
  final String? tenantId;

  AiInsightQuery({
    required this.query,
    this.tenantId,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      if (tenantId != null) 'tenantId': tenantId,
    };
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  final String? color;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      color: json['color'],
    );
  }
}

class AiInsightResponse {
  final String insight;
  final Map<String, dynamic> data;
  final List<String> suggestions;
  final List<ChartDataPoint> chartData;

  AiInsightResponse({
    required this.insight,
    required this.data,
    required this.suggestions,
    required this.chartData,
  });

  factory AiInsightResponse.fromJson(Map<String, dynamic> json) {
    return AiInsightResponse(
      insight: json['insight'] ?? '',
      data: json['data'] ?? {},
      suggestions: List<String>.from(json['suggestions'] ?? []),
      chartData: (json['chartData'] as List<dynamic>?)
              ?.map((item) => ChartDataPoint.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final AiInsightResponse? aiResponse;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.aiResponse,
  });
}
