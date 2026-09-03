import 'package:bloc/bloc.dart';
import 'notification_state.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final ApiService _api;
  final StorageService _storage;

  NotificationCubit({required ApiService api, required StorageService storage})
    : _api = api,
      _storage = storage,
      super(NotificationInitial());

  Future<void> fetchNotifications() async {
    try {
      emit(NotificationLoading());
      final userId = _storage.getUserIdFromDB();
      if (userId == null) {
        emit(const NotificationLoaded(notifications: [], unreadCount: 0));
        return;
      }
      final notifs = await _api.getNotifications(userId);
      final unread =
          notifs.where((n) => n['is_read'] == false || n['is_read'] == 0).length;
      await _storage.saveNotificationCount(unread);
      emit(NotificationLoaded(notifications: notifs, unreadCount: unread));
    } catch (e) {
      emit(NotificationError('Gagal memuat notifikasi: $e'));
    }
  }

  Future<void> markRead(String notifId) async {
    try {
      await _api.markNotificationRead(notifId);
      await fetchNotifications();
    } catch (_) {}
  }
}
