import 'package:equatable/equatable.dart';
import 'package:runners_app/models/app_user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends Equatable {
  const new({
    required this.status,
    this.user,
    this.message,
    this.submitting = false,
  });

  const new unknown()
    : status = AuthStatus.unknown,
      user = null,
      message = null,
      submitting = false;

  const new unauthenticated({this.message})
    : status = AuthStatus.unauthenticated,
      user = null,
      submitting = false;

  const new authenticated(AppUser current)
    : status = AuthStatus.authenticated,
      user = current,
      message = null,
      submitting = false;

  final AuthStatus status;
  final AppUser? user;
  final String? message;
  final bool submitting;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? message,
    bool? submitting,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [status, user, message, submitting];
}
