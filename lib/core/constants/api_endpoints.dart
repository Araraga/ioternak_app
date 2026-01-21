class ApiEndpoints {
  // IP VPS Anda (TETAP SAMA)
  static const String baseUrl = 'http://76.13.17.144';

  // =======================================================
  // [UPDATE PENTING] BAGIAN AUTHENTICATION
  // =======================================================

  // 1. Endpoint BARU: Request OTP
  static String get requestOtp {
    return "$baseUrl/auth/request-otp";
  }

  // 2. Endpoint UPDATE: Register sekarang lewat route /auth
  // Sebelumnya: /api/register -> Sekarang: /auth/register
  static String get registerUser {
    return "$baseUrl/auth/register";
  }

  // 3. Login User (Tetap di /api/login sesuai server.js)
  static String get loginUser {
    return "$baseUrl/api/login";
  }

  // =======================================================
  // BAGIAN DEVICE & SENSOR (TIDAK BERUBAH DARI KODE LAMA)
  // =======================================================

  static String getSensorData(String deviceId) {
    return "$baseUrl/api/sensor-data?id=$deviceId";
  }

  static String getSchedule(String deviceId) {
    return "$baseUrl/api/schedule?id=$deviceId";
  }

  static String updateSchedule(String deviceId) {
    return "$baseUrl/api/schedule?id=$deviceId";
  }

  static String checkDevice(String deviceId) {
    return "$baseUrl/api/check-device?id=$deviceId";
  }

  static String getMyDevices(String userId) {
    return "$baseUrl/api/my-devices?user_id=$userId";
  }

  static String get claimDevice {
    return "$baseUrl/api/claim-device";
  }

  static String get releaseDevice {
    return "$baseUrl/api/release-device";
  }
}
