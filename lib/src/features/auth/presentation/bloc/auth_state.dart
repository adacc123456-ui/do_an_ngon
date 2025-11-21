import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final String? userId;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final bool isLoading;
  final String? accessToken;
  final String? refreshToken;
  final bool isVendor;
  final String? errorMessage;
  final Map<String, dynamic>? userProfile;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.isLoading = false,
    this.accessToken,
    this.refreshToken,
    this.isVendor = false,
    this.errorMessage,
    this.userProfile,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    bool? isLoading,
    String? accessToken,
    String? refreshToken,
    bool? isVendor,
    String? errorMessage,
    Map<String, dynamic>? userProfile,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isVendor: isVendor ?? this.isVendor,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userProfile: userProfile ?? this.userProfile,
    );
  }

  @override
  List<Object?> get props => [
        isAuthenticated,
        userId,
        userName,
        userPhone,
        userEmail,
        isLoading,
        accessToken,
        refreshToken,
        isVendor,
        errorMessage,
        userProfile,
      ];
}

