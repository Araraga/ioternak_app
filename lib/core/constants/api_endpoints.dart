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
  static String getBarnsDashboard(String userId) =>
      '$baseUrl/api/barns-dashboard?user_id=$userId';
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

  // === BATCHES ===
  static String getBatches(String barnId) => '$baseUrl/api/batches?barn_id=$barnId';
  static String getBatchDetail(String batchId) => '$baseUrl/api/batches/$batchId';
  static String get createBatch => '$baseUrl/api/batches';
  static String updateBatch(String batchId) => '$baseUrl/api/batches/$batchId';
  static String closeBatch(String batchId) => '$baseUrl/api/batches/$batchId/close';

  // === POPULATION LOGS ===
  static String getPopulationLogs(String batchId) => '$baseUrl/api/batches/$batchId/population';
  static String addPopulationLog(String batchId) => '$baseUrl/api/batches/$batchId/population';

  // === PRODUCTION LOGS ===
  static String getProductionLogs(String batchId) => '$baseUrl/api/production/$batchId';
  static String get addProductionLog => '$baseUrl/api/production';
  static String getProductionMetrics(String batchId) => '$baseUrl/api/production/$batchId/metrics';

  // === HEALTH ===
  static String getHealthChecks(String batchId) => '$baseUrl/api/health/$batchId';
  static String get addHealthCheck => '$baseUrl/api/health';
  static String getVaccinationSchedule(String batchId) => '$baseUrl/api/health/$batchId/vaccinations';
  static String get addVaccinationRecord => '$baseUrl/api/health/vaccinations';
  static String getDiseaseLogs(String batchId) => '$baseUrl/api/health/$batchId/diseases';
  static String get addDiseaseLog => '$baseUrl/api/health/diseases';

  // === FINANCE ===
  static String getIncome([String? barnId]) =>
      barnId != null && barnId.isNotEmpty
          ? '$baseUrl/api/finance/income?barn_id=$barnId'
          : '$baseUrl/api/finance/income';
  static String get addIncome => '$baseUrl/api/finance/income';
  static String getExpenses([String? barnId]) =>
      barnId != null && barnId.isNotEmpty
          ? '$baseUrl/api/finance/expenses?barn_id=$barnId'
          : '$baseUrl/api/finance/expenses';
  static String get addExpense => '$baseUrl/api/finance/expenses';
  static String getFinancialSummary([String? barnId]) =>
      barnId != null && barnId.isNotEmpty
          ? '$baseUrl/api/finance/summary?barn_id=$barnId'
          : '$baseUrl/api/finance/summary';

  // === TASKS ===
  static String getTasks(String barnId) => '$baseUrl/api/tasks?barn_id=$barnId';
  static String getTaskDetail(String taskId) => '$baseUrl/api/tasks/$taskId';
  static String get createTask => '$baseUrl/api/tasks';
  static String updateTask(String taskId) => '$baseUrl/api/tasks/$taskId';
  static String completeTask(String taskId) => '$baseUrl/api/tasks/$taskId/complete';
  static String deleteTask(String taskId) => '$baseUrl/api/tasks/$taskId';

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
