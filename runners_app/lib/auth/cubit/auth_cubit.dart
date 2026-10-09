import 'package:bloc/bloc.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/auth/cubit/auth_state.dart';
import 'package:runners_app/auth/data/auth_repository.dart';
import 'package:runners_app/models/app_user.dart';

class AuthCubit extends Cubit<AuthState> {
  new(this._repository) : super(const AuthState.unknown());

  final AuthRepository _repository;

  Future<void> restore() async {
    try {
      final user = await _repository.restore();
      if (isClosed) return;
      emit(
        user == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(user),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(AuthState.unauthenticated(message: error.message));
    }
  }

  Future<void> login(String phoneNumber) async {
    await _submit(() => _repository.login(phoneNumber.trim()));
  }

  Future<void> register({
    required String phoneNumber,
    required String fullName,
    required String role,
  }) async {
    await _submit(
      () => _repository.register(
        phoneNumber: phoneNumber.trim(),
        fullName: fullName.trim(),
        role: role,
      ),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    if (isClosed) return;
    emit(const AuthState.unauthenticated());
  }

  Future<void> _submit(Future<AppUser> Function() action) async {
    emit(state.copyWith(submitting: true, clearMessage: true));
    try {
      final user = await action();
      if (isClosed) return;
      emit(AuthState.authenticated(user));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(AuthState.unauthenticated(message: error.message));
    }
  }
}
