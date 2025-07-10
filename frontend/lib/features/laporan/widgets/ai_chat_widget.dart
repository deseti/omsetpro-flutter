import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ai_insight_model.dart';
import '../../../providers/ai_insight_provider.dart';
import '../../../providers/providers.dart';

class AiChatWidget extends ConsumerStatefulWidget {
  const AiChatWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends ConsumerState<AiChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatProvider.notifier).addSampleQuestions();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    final token = ref.read(accessTokenProvider);
    final userProfile = ref.read(userProfileProvider);

    ref.read(aiChatProvider.notifier).sendQuery(
      query: query,
      token: token ?? '',
      tenantId: userProfile?['tenantId']?.toString(),
    );

    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),

          // Chat content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? 400 : 250,
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final aiState = ref.watch(aiChatProvider);
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: aiState.chatHistory.length,
                        itemBuilder: (context, index) {
                          final message = aiState.chatHistory[index];
                          return _buildMessageBubble(message);
                        },
                      );
                    },
                  ),
                ),

                // Loading indicator
                Consumer(
                  builder: (context, ref, child) {
                    final aiState = ref.watch(aiChatProvider);
                    if (aiState.isLoading) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('AI sedang berpikir...'),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Input area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Tanya tentang bisnis Anda...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          maxLines: null,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final aiState = ref.watch(aiChatProvider);
                          return IconButton(
                            onPressed: aiState.isLoading ? null : _sendMessage,
                            icon: const Icon(Icons.send),
                            color: Theme.of(context).primaryColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (message.aiResponse != null) ...[
                    const SizedBox(height: 8),
                    _buildAiResponseWidgets(message.aiResponse!),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiResponseWidgets(AiInsightResponse response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart data if available
        if (response.chartData.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            height: 120,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildSimpleChart(response.chartData),
          ),
        ],

        // Suggestions
        if (response.suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...response.suggestions.map((suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $suggestion'),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSimpleChart(List<ChartDataPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.take(5).map((point) {
        final height = (point.value / maxValue) * 80;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              point.value.toStringAsFixed(0),
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 40,
              child: Text(
                point.label,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
