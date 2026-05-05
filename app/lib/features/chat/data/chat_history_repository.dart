import 'dart:async';
import 'dart:convert';
import 'package:jansetu/core/storage/secure_storage_service.dart';
import 'package:jansetu/features/chat/domain/models/chat_session.dart';

class ChatHistoryRepository {
  final SecureStorageService _storage;
  final _updateController = StreamController<void>.broadcast();

  ChatHistoryRepository._internal({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  static final ChatHistoryRepository _instance = ChatHistoryRepository._internal();

  factory ChatHistoryRepository({SecureStorageService? storage}) {
    return _instance;
  }

  Stream<void> get onHistoryChanged => _updateController.stream;

  Future<List<ChatSession>> getChatSessions() async {
    try {
      final jsonString = await _storage.readChatHistory();
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) => ChatSession.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    } catch (e) {
      return [];
    }
  }

  Future<void> saveChatSession(ChatSession session) async {
    final currentSessions = await getChatSessions();
    final existingIndex = currentSessions.indexWhere((s) => s.id == session.id);

    if (existingIndex >= 0) {
      currentSessions[existingIndex] = session;
    } else {
      currentSessions.insert(0, session);
    }

    final encoded = jsonEncode(currentSessions.map((s) => s.toJson()).toList());
    await _storage.writeChatHistory(encoded);
    _updateController.add(null);
  }
}
