import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';

part 'chat_state.dart';

/// Context bundle yang dikirim ke AI dengan setiap pesan
class KandangContext {
  final String? sensorId;
  final String? pakanId;
  final String? userName;
  final double? lastTemp;
  final double? lastHum;
  final double? lastGas;
  final String? weatherDesc;
  final double? weatherTemp;
  final List<String> activeSchedules;

  const KandangContext({
    this.sensorId,
    this.pakanId,
    this.userName,
    this.lastTemp,
    this.lastHum,
    this.lastGas,
    this.weatherDesc,
    this.weatherTemp,
    this.activeSchedules = const [],
  });

  /// Build a context string to inject into the AI prompt
  String toContextString() {
    final parts = <String>[];
    if (userName != null) parts.add('Nama peternak: $userName');
    if (sensorId != null) parts.add('ID sensor IoPeka: $sensorId');
    if (pakanId != null) parts.add('ID perangkat IoPakan: $pakanId');
    if (lastTemp != null) parts.add('Suhu kandang saat ini: ${lastTemp!.toStringAsFixed(1)}°C');
    if (lastHum != null) parts.add('Kelembapan kandang: ${lastHum!.toStringAsFixed(0)}%');
    if (lastGas != null) parts.add('Kadar amonia kandang: ${lastGas!.toStringAsFixed(1)} PPM');
    if (weatherTemp != null && weatherDesc != null) {
      parts.add('Cuaca luar: $weatherDesc, ${weatherTemp!.toStringAsFixed(0)}°C');
    }
    if (activeSchedules.isNotEmpty) {
      parts.add('Jadwal pakan aktif: ${activeSchedules.join(", ")}');
    }
    if (parts.isEmpty) return '';
    return '[DATA KANDANG REALTIME]\n${parts.join('\n')}\n[/DATA KANDANG REALTIME]';
  }
}

class ChatCubit extends Cubit<ChatState> {
  final ApiService apiService;
  final StorageService storageService;

  List<Map<String, String>> _messages = [];
  KandangContext _ctx = const KandangContext();

  ChatCubit(this.apiService, this.storageService) : super(ChatInitial()) {
    _loadHistory();
  }

  void _loadHistory() {
    _messages = storageService.getChatHistory();
    if (_messages.isNotEmpty) {
      emit(ChatLoaded(List.from(_messages)));
    }
  }

  /// Update real-time kandang context before sending a message
  void updateContext(KandangContext ctx) {
    _ctx = ctx;
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
      // Build enriched context for AI
      final ctxString = _ctx.toContextString();
      final enrichedMessage = ctxString.isNotEmpty
          ? '$ctxString\n\nPertanyaan peternak: $message'
          : message;

      final response = await apiService.post('/api/chat', {
        'message': enrichedMessage,
        'device_id': deviceId.isNotEmpty ? deviceId : null,
        'user_id': userId,
      });

      final aiReply = response['reply'] ?? 'Maaf, tidak ada respons dari AI.';

      _messages.add({'role': 'ai', 'text': aiReply});
      storageService.saveChatHistory(_messages);
      emit(ChatLoaded(List.from(_messages)));
    } catch (e) {
      final errMsg = e.toString().contains('SocketException') || e.toString().contains('Connection')
          ? 'Gagal terhubung ke server. Cek koneksi internet Anda.'
          : 'Gagal mendapat respons: ${e.toString().replaceAll("Exception:", "").trim()}';

      _messages.add({'role': 'ai', 'text': errMsg});
      storageService.saveChatHistory(_messages);
      emit(ChatLoaded(List.from(_messages)));
    }
  }
}
