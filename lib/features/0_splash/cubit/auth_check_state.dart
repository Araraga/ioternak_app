import 'package:equatable/equatable.dart';

abstract class AuthCheckState extends Equatable {
  const AuthCheckState();

  @override
  List<Object> get props => [];
}

class AuthCheckInitial extends AuthCheckState {}

class AuthCheckAuthenticated extends AuthCheckState {}

class AuthCheckUnauthenticated extends AuthCheckState {}