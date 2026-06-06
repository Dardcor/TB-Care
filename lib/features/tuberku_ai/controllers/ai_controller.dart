import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../app/config/app_constants.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? source;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.source,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: (json['text'] ?? json['content'] ?? '').toString(),
        isUser: json['isUser'] != null ? json['isUser'] as bool : json['role'] == 'user',
        timestamp: json['timestamp'] != null 
            ? DateTime.parse(json['timestamp'] as String)
            : json['created_at'] != null 
                ? DateTime.parse(json['created_at'] as String) 
                : DateTime.now(),
        source: json['source'] as String?,
      );
}

class AiController extends GetxController {
  final _gemini = Get.find<GeminiService>();
  final _supabase = Get.find<SupabaseService>();
  final _storage = GetStorage();

  final messages = <ChatMessage>[].obs;
  final sessions = <Map<String, dynamic>>[].obs;
  final currentSessionId = Rx<String?>(null);
  
  final isTyping = false.obs;
  final isLoadingHistory = false.obs;
  bool _isShowingResponse = false;
  
  final textController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadSessions();

    // Handle pre-filled question from article
    final preFilledQuestion = Get.arguments as String?;
    if (preFilledQuestion != null && preFilledQuestion.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sendMessage(preFilledQuestion);
      });
    }
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> loadSessions() async {
    final result = await _supabase.getChatSessions();
    sessions.assignAll(result);
  }

  Future<void> startNewChat() async {
    messages.clear();
    currentSessionId.value = null;
    _gemini.resetChat();
  }

  Future<void> loadSession(String sessionId) async {
    isLoadingHistory.value = true;
    currentSessionId.value = sessionId;
    
    try {
      final history = await _supabase.getChatMessages(sessionId);
      final loadedMessages = history.map((e) => ChatMessage.fromJson(e)).toList();
      messages.assignAll(loadedMessages);
      _scrollToBottom();
      Get.back(); // Close history dialog
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat history');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> sendMessage([String? overrideText]) async {
    if (isTyping.value || _isShowingResponse) return; // Anti-spam: check both waiting and typing animation
    
    final text = overrideText ?? textController.text.trim();
    if (text.isEmpty) return;

    // Create session if not exists
    if (currentSessionId.value == null) {
      final title = text.length > 30 ? '${text.substring(0, 30)}...' : text;
      currentSessionId.value = await _supabase.createChatSession(title);
      loadSessions(); // refresh history list
    }

    // Add user message to UI
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);
    
    // Save to Supabase
    _supabase.saveChatMessage(
      sessionId: currentSessionId.value!,
      role: 'user',
      content: text,
    );

    textController.clear();
    _scrollToBottom();

    // Show typing indicator while waiting for Gemini
    isTyping.value = true;

    // Get AI response from Gemini
    final response = await _gemini.sendMessage(text);

    String? source; // Removed hardcoded Kemenkes RI source
    // Hide typing indicator (the dots) once we start displaying the text
    isTyping.value = false;

    // Add empty message to start typing effect
    final aiMsg = ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      source: source,
    );
    messages.add(aiMsg);

    // Keep a local flag or use isTyping for the duration of the typing animation if needed
    // Actually, I'll use a local variable to prevent re-entering sendMessage if still typing
    _isShowingResponse = true;

    // Typing effect logic
    String currentText = '';
    final fullResponse = response;
    
    for (int i = 0; i < fullResponse.length; i++) {
      currentText += fullResponse[i];
      
      messages[messages.length - 1] = ChatMessage(
        text: currentText,
        isUser: false,
        timestamp: aiMsg.timestamp,
        source: source,
      );

      // Typing speed
      int delay = fullResponse.length > 200 ? 4 : 12;
      await Future.delayed(Duration(milliseconds: delay));
      
      if (i % 15 == 0) _scrollToBottom();
    }

    _isShowingResponse = false;

    // Save full message to Supabase
    _supabase.saveChatMessage(
      sessionId: currentSessionId.value!,
      role: 'model',
      content: fullResponse,
    );

    _scrollToBottom();
  }

  void sendQuickQuestion(String question) {
    sendMessage(question);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final position = scrollController.position.maxScrollExtent;
        scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
