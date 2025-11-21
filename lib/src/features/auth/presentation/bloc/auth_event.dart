import 'package:equatable/equatable.dart';
import 'package:do_an_ngon/src/features/auth/data/models/auth_response.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String identifier;
  final String password;

  const LoginEvent({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class UpdateUserInfoEvent extends AuthEvent {
  final String? name;
  final String? phone;
  final String? email;

  const UpdateUserInfoEvent({
    this.name,
    this.phone,
    this.email,
  });

  @override
  List<Object?> get props => [name, phone, email];
}

class CompleteAuthEvent extends AuthEvent {
  final AuthResponse authResponse;

  const CompleteAuthEvent(this.authResponse);

  @override
  List<Object?> get props => [authResponse];
}

class RefreshUserProfileEvent extends AuthEvent {
  const RefreshUserProfileEvent();
}

