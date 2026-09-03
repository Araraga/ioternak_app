class ApiEndpoints {
  static const String baseUrl = 'http://38.103.170.74:3000';

  // === AUTH ===
  static String get requestOtp => '$baseUrl/auth/request-otp';
  static String get registerUser => '$baseUrl/auth/register';
  static String get loginUser => '$baseUrl/api/login';

  // === DEVICES ===
  static String getMyDevices(String userId) =>
      '$baseUrl/api/my-devices?user_id=$userId';
  static String checkDevice(String deviceId) =>
      '$baseUrl/api/check-device?id=$deviceId';
  static String get claimDevice => '$baseUrl/api/claim-device';
  static String get releaseDevice => '$baseUrl/api/release-device';
  static String getDeviceStatus(List<String> deviceIds) =>
      '$baseUrl/api/device-status?ids=${deviceIds.join(',')}';

  // === SENSOR DATA ===
  static String getSensorData(String deviceId) =>
      '$baseUrl/api/sensor-data?id=$deviceId';

  // === SCHEDULE ===
  static String getSchedule(String deviceId) =>
      '$baseUrl/api/get-schedule?id=$deviceId';
  static String updateSchedule(String deviceId) =>
      '$baseUrl/api/schedule?id=$deviceId';
  static String triggerFeed(String deviceId) =>
      '$baseUrl/api/trigger-feed?id=$deviceId';

  // === BARNS ===
  static String getBarns(String userId) =>
      '$baseUrl/api/barns?user_id=$userId';
  static String getBarnDetail(String barnId) =>
      '$baseUrl/api/barn/$barnId';
  static String get createBarn => '$baseUrl/api/barn';
  static String updateBarn(String barnId) => '$baseUrl/api/barn/$barnId';
  static String deleteBarn(String barnId) => '$baseUrl/api/barn/$barnId';
  static String getBarnSummary(String barnId) =>
      '$baseUrl/api/barn-summary/$barnId';

  // === BARN FINANCES ===
  static String getBarnFinances(String barnId) =>
      '$baseUrl/api/barn-finances?barn_id=$barnId';
  static String get addBarnFinance => '$baseUrl/api/barn-finances';

  // === BARN FEED LOGS ===
  static String getBarnFeedLogs(String barnId) =>
      '$baseUrl/api/barn-feed-logs?barn_id=$barnId';
  static String get addBarnFeedLog => '$baseUrl/api/barn-feed-logs';

  // === NOTIFICATIONS ===
  static String getNotifications(String userId) =>
      '$baseUrl/api/notifications?user_id=$userId';
  static String markNotificationRead(String notifId) =>
      '$baseUrl/api/notifications/$notifId/read';
  static String get clearNotifications => '$baseUrl/api/notifications/clear';

  // === SUBSCRIPTION ===
  static String getMySubscription(String userId) =>
      '$baseUrl/api/my-subscription?user_id=$userId';

  // === AI CHAT ===
  static String get chat => '$baseUrl/api/chat';

  // === WEATHER (Open-Meteo) ===
  static String weatherForecast(String latitude, String longitude) =>
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&hourly=temperature_2m,relativehumidity_2m,cloudcover,precipitation_probability'
      '&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max'
      '&current_weather=true&timezone=auto'
      '&forecast_days=7';

  // === GEOCODING (Nominatim - free) ===
  static String geocodeCity(String city) =>
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(city)},Indonesia&format=json&limit=1';
}
