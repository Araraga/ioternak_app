import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/chat_cubit.dart';

class AiAssistantPage extends StatelessWidget {
  final String? deviceId;

  const AiAssistantPage({super.key, this.deviceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatCubit(context.read<ApiService>(), context.read<StorageService>()),
      child: const _AiAssistantView(),
    );
  }
}

class _AiAssistantView extends StatelessWidget {
  const _AiAssistantView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        // 1. MEMPERBESAR TINGGI APPBAR
        toolbarHeight: 80,

        // 2. MEMBERI MARGIN BAWAH PADA KONTEN TITLE
        title: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: [
              const SizedBox(width: 20), // Margin Kiri
              // FOTO PROFIL
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 24,

                  backgroundImage: AssetImage('assets/images/ai.png'),
                ),
              ),

              const SizedBox(width: 16),

              // NAMA PROF JAGO
              const Text(
                "Prof. Jago",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 10.0,
            ), // Margin bawah icon hapus juga
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 28),
              tooltip: "Hapus Chat",
              onPressed: () {
                _showDeleteConfirmDialog(context);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                List<Map<String, String>> messages = [];
                if (state is ChatLoading) {
                  messages = state.oldMessages;
                } else if (state is ChatLoaded) {
                  messages = state.messages;
                }

                if (messages.isEmpty && state is! ChatLoading) {
                  return const _EmptyStateWidget();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length + (state is ChatLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (state is ChatLoading && index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.only(left: 8, top: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: AssetImage(
                                'assets/images/ai.png',
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 40,
                              height: 20,
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final msg = messages[index];
                    final isUser = msg['role'] == 'user';

                    return _ChatBubble(
                      message: msg['text'] ?? '',
                      isUser: isUser,
                    );
                  },
                );
              },
            ),
          ),
          const _MessageInputArea(),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Chat?"),
        content: const Text(
          "Semua riwayat percakapan dengan Prof. Jago akan dihapus permanen.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              context.read<ChatCubit>().deleteChatHistory();
              Navigator.pop(ctx);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET BUBBLE CHAT ---
class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/ai.png'),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(0),
                  bottomRight: isUser
                      ? const Radius.circular(0)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET PLACEHOLDER (TANPA GAMBAR) ---
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3. MENGHAPUS GAMBAR LINGKARAN DI SINI
            Text(
              "Halo! Saya Prof. Jago",
              style: TextStyle(
                fontSize: 26, // Lebih Besar lagi agar menarik
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Asisten pintar IoTernak Anda. Tanyakan kondisi kandang, jadwal pakan, atau tips beternak!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET INPUT MODERN ---
class _MessageInputArea extends StatefulWidget {
  const _MessageInputArea();

  @override
  State<_MessageInputArea> createState() => _MessageInputAreaState();
}

class _MessageInputAreaState extends State<_MessageInputArea> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<AiAssistantPage>();
    final deviceId = parent?.deviceId ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Margin bawah form (bottom: 30)
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "Tanya Prof. Jago...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      final storage = context.read<StorageService>();
                      final userId = storage.getUserIdFromDB();

                      context.read<ChatCubit>().sendMessage(
                        text,
                        deviceId,
                        userId,
                      );
                      _controller.clear();

                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
