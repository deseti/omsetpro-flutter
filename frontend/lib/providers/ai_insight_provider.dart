import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_insight_model.dart';
import 'ai_insight_service.dart';

// AI Chat State
class AiChatState {
  final List<ChatMessage> chatHistory;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.chatHistory = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? chatHistory,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      chatHistory: chatHistory ?? this.chatHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// AI Chat Notifier
class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier() : super(const AiChatState());

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> sendQuery({
    required String query,
    required String token,
    String? tenantId,
  }) async {
    if (query.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedHistory = [...state.chatHistory, userMessage];
    state = state.copyWith(
      chatHistory: updatedHistory,
      isLoading: true,
      error: null,
    );

    try {
      final aiResponse = await AiInsightService.queryInsight(
        query: query,
        token: token,
        tenantId: tenantId,
      );

      // Add AI response message
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: aiResponse.insight,
        isUser: false,
        timestamp: DateTime.now(),
        aiResponse: aiResponse,
      );

      state = state.copyWith(
        chatHistory: [...updatedHistory, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: 'Maaf, terjadi kesalahan saat memproses pertanyaan Anda. Silakan coba lagi.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        chatHistory: [...updatedHistory, errorMessage],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadChatHistory({
    required String token,
    String? tenantId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final history = await AiInsightService.getChatHistory(
        token: token,
        tenantId: tenantId,
      );

      state = state.copyWith(
        chatHistory: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearChatHistory() {
    state = state.copyWith(chatHistory: []);
  }

  void addSampleQuestions() {
    final sampleQuestions = [
      'Produk apa yang paling laris bulan ini?',
      'Berapa total keuntungan minggu lalu?',
      'Kapan waktu terbaik untuk jualan?',
      'Produk mana yang stoknya hampir habis?',
      'Bagaimana performa penjualan hari ini?',
    ];

    if (state.chatHistory.isEmpty) {
      final welcomeMessage = ChatMessage(
        id: 'welcome',
        message: 'Halo! Saya asisten AI OmsetPro. Tanya apa saja tentang bisnis Anda!\n\nContoh pertanyaan:\n${sampleQuestions.map((q) => '• $q').join('\n')}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(chatHistory: [welcomeMessage]);
    }
  }
}

// Provider
final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>(
  (ref) => AiChatNotifier(),
);
