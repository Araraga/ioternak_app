part of 'chat_cubit.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {
  final List<Map<String, String>> oldMessages;
  ChatLoading(this.oldMessages);
}

class ChatLoaded extends ChatState {
  final List<Map<String, String>> messages;
  ChatLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
