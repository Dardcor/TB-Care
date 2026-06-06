import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../../app/config/app_constants.dart';

class GeminiService extends GetxService {
  final List<String> _apiKeys = [];
  final Dio _dio = Dio();
  final List<Map<String, dynamic>> _chatHistory = [];
  String? _currentApiKey;

  Future<GeminiService> init() async {
    final rawKeys = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (rawKeys.isEmpty) return this;

    _apiKeys.addAll(
      rawKeys.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
    );

    if (_apiKeys.isNotEmpty) {
      _currentApiKey = _apiKeys[Random().nextInt(_apiKeys.length)];
    }

    return this;
  }

  bool get isAvailable => _currentApiKey != null;

  Future<void> _ensureInitialized() async {
    if (_currentApiKey != null) return;
    
    final rawKeys = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (rawKeys.isNotEmpty && _apiKeys.isEmpty) {
      _apiKeys.addAll(
        rawKeys.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }
    
    if (_apiKeys.isNotEmpty) {
      _currentApiKey = _apiKeys[Random().nextInt(_apiKeys.length)];
    }
  }

  Future<String> sendMessage(String userMessage) async {
    await _ensureInitialized();
    
    if (!isAvailable) {
      return 'Maaf, Tuberku AI sedang ada kendala. '
          'Silahkan coba beberapa saat lagi.';
    }

    return await _executeWithRetry(userMessage);
  }

  Future<String> _executeWithRetry(String userMessage, {int retries = 1}) async {
    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/${AppConstants.geminiModel}:generateContent?key=$_currentApiKey';
      
      final currentMessage = {
        "role": "user",
        "parts": [
          {"text": userMessage}
        ]
      };
      
      final contents = [..._chatHistory, currentMessage];

      final data = {
        "systemInstruction": {
          "parts": [
            {"text": AppConstants.geminiSystemPrompt + " Jika kamu menggunakan informasi dari pencarian internet, kamu bisa menyebutkannya, tetapi usahakan penjelasan tetap berfokus pada ringkasan yang informatif."}
          ]
        },
        "contents": contents,
        "tools": [
          {
            "googleSearch": {}
          }
        ],
        "generationConfig": {
          "temperature": 0.7
        }
      };

      final response = await _dio.post(url, data: data);

      if (response.statusCode == 200) {
        final resData = response.data;
        final candidates = resData['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            String responseText = parts[0]['text'] ?? 'Maaf, tidak ada respons dari AI. Coba beberapa saat lagi.';
            
            // Collect grounding sources/links if available
            final groundingMetadata = candidates[0]['groundingMetadata'];
            if (groundingMetadata != null) {
              final chunks = groundingMetadata['groundingChunks'] as List?;
              if (chunks != null && chunks.isNotEmpty) {
                final linksMap = <String, String>{};
                for (var chunk in chunks) {
                  final web = chunk['web'];
                  if (web != null && web['uri'] != null) {
                    final uri = web['uri'] as String;
                    final title = web['title'] as String? ?? uri;
                    linksMap[uri] = title;
                  }
                }
                if (linksMap.isNotEmpty) {
                  responseText += '\n\nSumber referensi dari pencarian web:\n' + linksMap.entries.map((e) => '• [${e.value}](${e.key})').join('\n');
                }
              }
            }

            // Strip markdown characters (* and #) for clean text UI
            responseText = responseText.replaceAll('*', '').replaceAll('#', '');

            _chatHistory.add(currentMessage);
            _chatHistory.add({
              "role": "model",
              "parts": [
                {"text": responseText}
              ]
            });

            return responseText;
          }
        }
      }
      return 'Maaf, tidak ada respons dari AI. Coba beberapa saat lagi.';
    } on DioException catch (e) {
      if (e.response?.statusCode == 429 || (e.response?.data.toString().contains('quota') ?? false)) {
        if (retries > 0 && _apiKeys.length > 1) {
          _currentApiKey = _apiKeys[Random().nextInt(_apiKeys.length)];
          return await _executeWithRetry(userMessage, retries: retries - 1);
        }
        return 'Maaf, kuota harian AI telah habis. Silakan coba lagi besok.';
      }
      
      if (e.response?.data.toString().contains('safety') ?? false) {
        return 'Maaf, pertanyaan tersebut tidak dapat dijawab karena alasan keamanan. '
            'Silakan ajukan pertanyaan lain seputar TBC.';
      }
      return 'Maaf, Tuberku AI sedang tidak tersedia (AI Error: ${e.message}). Coba beberapa saat lagi.';
    } catch (e) {
      return 'Maaf, terjadi kesalahan (System Error: ${e.toString().split('\n')[0]}). Periksa koneksi internet Anda dan coba lagi.';
    }
  }

  void resetChat() {
    _chatHistory.clear();
    if (_apiKeys.isNotEmpty) {
      _currentApiKey = _apiKeys[Random().nextInt(_apiKeys.length)];
    }
  }
}
