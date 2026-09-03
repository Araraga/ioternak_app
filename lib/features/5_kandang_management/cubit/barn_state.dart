import 'package:equatable/equatable.dart';

abstract class BarnState extends Equatable {
  const BarnState();
  @override
  List<Object?> get props => [];
}

class BarnInitial extends BarnState {}

class BarnLoading extends BarnState {}

class BarnLoaded extends BarnState {
  final List<dynamic> barns;
  const BarnLoaded({required this.barns});
  @override
  List<Object?> get props => [barns];
}

class BarnError extends BarnState {
  final String message;
  const BarnError(this.message);
  @override
  List<Object?> get props => [message];
}

class BarnCreating extends BarnState {}

class BarnCreated extends BarnState {
  final Map<String, dynamic> barn;
  const BarnCreated(this.barn);
  @override
  List<Object?> get props => [barn];
}
