import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  final String message;
  ProfileSuccess(this.message);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileCubit extends Cubit<ProfileState> {
  final StorageService _storage;
  final ApiService _api;

  ProfileCubit(this._storage, this._api) : super(ProfileInitial());

  Future<void> updateName(String newName) async {
    try {
      emit(ProfileLoading());
      final phone = _storage.getUserPhone();

      if (phone == null) throw Exception("Nomor HP tidak ditemukan.");
      await _api.registerUser(newName, phone);
      await _storage.saveUserProfile(newName, phone);

      emit(ProfileSuccess("Nama berhasil diperbarui."));
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll("Exception:", "")));
    }
  }

  Future<void> logout() async {
    await _storage.clearAllData();
  }
}
