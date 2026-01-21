import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ApiService apiService;
  final StorageService storageService;

  List<Map<String, String>> _messages = [];

  ChatCubit(this.apiService, this.storageService) : super(ChatInitial()) {
    _loadHistory();
  }

  void _loadHistory() {
    _messages = storageService.getChatHistory();
    if (_messages.isNotEmpty) {
      emit(ChatLoaded(List.from(_messages)));
    }
  }

  void deleteChatHistory() async {
    _messages.clear();
    await storageService.clearChatHistory();
    emit(ChatLoaded(List.from(_messages)));
  }

  Future<void> sendMessage(
    String message,
    String deviceId,
    String? userId,
  ) async {
    if (message.trim().isEmpty) return;

    _messages.add({'role': 'user', 'text': message});
    storageService.saveChatHistory(_messages);
    emit(ChatLoading(List.from(_messages)));

    try {
      final response = await apiService.post('/api/chat', {
        'message': message,
        'device_id': deviceId,
        'user_id': userId,
      });

      final aiReply = response['reply'] ?? 'Maaf, tidak ada respons.';

      _messages.add({'role': 'ai', 'text': aiReply});
      storageService.saveChatHistory(_messages);
      emit(ChatLoaded(List.from(_messages)));
    } catch (e) {
      _messages.add({'role': 'ai', 'text': 'Gagal terhubung: $e'});
      storageService.saveChatHistory(_messages);
      emit(ChatLoaded(List.from(_messages)));
    }
  }
}
