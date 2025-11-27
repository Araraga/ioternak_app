class ApiEndpoints {
  static const String baseUrl = "maggenzimiot.onrender.com";

  static String getSensorData(String deviceId) {
    return "https://$baseUrl/api/sensor-data?id=$deviceId";
  }

  static String getSchedule(String deviceId) {
    return "https://$baseUrl/api/schedule?id=$deviceId";
  }

  static String updateSchedule(String deviceId) {
    return "https://$baseUrl/api/schedule?id=$deviceId";
  }

  static String checkDevice(String deviceId) {
    return "https://$baseUrl/api/check-device?id=$deviceId";
  }
}