import 'package:equatable/equatable.dart';

// Abstract class utama
// Semua state lain akan mewarisi (extends) dari class ini
abstract class AuthCheckState extends Equatable {
  const AuthCheckState();

  @override
  List<Object> get props => [];
}

/// State Awal: Saat aplikasi baru dibuka dan sedang mengecek.
class AuthCheckInitial extends AuthCheckState {}

/// State Terotentikasi: Saat ID perangkat ditemukan di SharedPreferences.
class AuthCheckAuthenticated extends AuthCheckState {}

/// State Tidak Terotentikasi: Saat ID perangkat tidak ditemukan.
class AuthCheckUnauthenticated extends AuthCheckState {}