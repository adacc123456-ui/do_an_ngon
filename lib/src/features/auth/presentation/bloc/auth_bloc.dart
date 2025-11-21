import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_an_ngon/src/core/errors/api_exception.dart';
import 'package:do_an_ngon/src/core/services/local_storage_service.dart';
import 'package:do_an_ngon/src/features/auth/data/models/auth_response.dart';
import 'package:do_an_ngon/src/features/auth/data/repositories/auth_repository.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:do_an_ngon/src/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LocalStorageService _localStorageService;
  final AuthRepository _authRepository;

  AuthBloc({
    required LocalStorageService localStorageService,
    required AuthRepository authRepository,
  })  : _localStorageService = localStorageService,
        _authRepository = authRepository,
        super(const AuthState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<UpdateUserInfoEvent>(_onUpdateUserInfo);
    on<CompleteAuthEvent>(_onCompleteAuth);
    on<RefreshUserProfileEvent>(_onRefreshUserProfile);

    // Check auth status on initialization
    add(const CheckAuthStatusEvent());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final tokens = await _localStorageService.getAuthTokens();
      final userProfile = await _localStorageService.getUserProfile();
      final isVendor = await _localStorageService.isVendorAccount();

      if (tokens != null && userProfile != null) {
        final legacy = await _localStorageService.getAuthState();
        final userId = legacy['userId'] ?? userProfile['id']?.toString() ?? userProfile['_id']?.toString();
        final userName = legacy['userName'] ?? userProfile['name']?.toString();
        final userPhone = legacy['userPhone'] ?? userProfile['phone']?.toString();
        final userEmail = legacy['userEmail'] ?? userProfile['email']?.toString();

        emit(state.copyWith(
          isAuthenticated: true,
          userId: userId,
          userName: userName,
          userPhone: userPhone,
          userEmail: userEmail,
          accessToken: tokens['accessToken']?.toString(),
          refreshToken: tokens['refreshToken']?.toString(),
          isVendor: isVendor,
          userProfile: userProfile,
          isLoading: false,
          clearError: true,
        ));
      } else {
        await _localStorageService.clearAuthState();
        emit(const AuthState());
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Không thể kiểm tra trạng thái đăng nhập'));
    }
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final AuthResponse authResponse = await _authRepository.login(
        identifier: event.identifier,
        password: event.password,
      );

      await _persistAuthResponse(authResponse, emit);
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Đăng nhập thất bại. Vui lòng thử lại.',
      ));
    }
  }

  Future<void> _onCompleteAuth(
    CompleteAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _persistAuthResponse(event.authResponse, emit);
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể lưu thông tin đăng nhập. Vui lòng thử lại.',
      ));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _authRepository.logout();
    } catch (_) {
      // Ignore logout errors – proceed to clear local data
    } finally {
      await _localStorageService.clearAuthState();
      emit(const AuthState());
    }
  }

  Future<void> _onUpdateUserInfo(
    UpdateUserInfoEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      // Gọi API để cập nhật thông tin lên server
      final updatedProfile = await _authRepository.updateUserProfile(
        name: event.name,
        phone: event.phone,
        email: event.email,
      );

      // Cập nhật local storage
      await _localStorageService.updateUserInfo(
        name: event.name,
        phone: event.phone,
        email: event.email,
      );
      await _localStorageService.saveUserProfile(updatedProfile);

      emit(state.copyWith(
        isLoading: false,
        userName: event.name ?? updatedProfile['name']?.toString() ?? state.userName,
        userPhone: event.phone ?? updatedProfile['phone']?.toString() ?? state.userPhone,
        userEmail: event.email ?? updatedProfile['email']?.toString() ?? state.userEmail,
        userProfile: updatedProfile,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể cập nhật thông tin người dùng',
      ));
    }
  }

  Future<void> _persistAuthResponse(
    AuthResponse authResponse,
    Emitter<AuthState> emit,
  ) async {
    final tokens = {
      'accessToken': authResponse.accessToken,
      'refreshToken': authResponse.refreshToken,
      if (authResponse.accessExpires != null)
        'accessExpires': authResponse.accessExpires!.toIso8601String(),
      if (authResponse.refreshExpires != null)
        'refreshExpires': authResponse.refreshExpires!.toIso8601String(),
    };

    final user = authResponse.user;
    await _localStorageService.saveAuthTokens(tokens);
    await _localStorageService.saveUserProfile(user);

    final userId = authResponse.userId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final userName = authResponse.name ?? user['fullName']?.toString() ?? user['username']?.toString() ?? 'Người dùng';
    final userPhone = authResponse.phone ?? user['phone']?.toString();
    final userEmail = authResponse.email ?? user['email']?.toString();

    await _localStorageService.saveAuthState(
      userId: userId,
      userName: userName,
      phone: userPhone,
      email: userEmail,
    );

    emit(state.copyWith(
      isAuthenticated: true,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      userEmail: userEmail,
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      isVendor: authResponse.isVendor,
      userProfile: user,
      isLoading: false,
      clearError: true,
    ));
  }

  Future<void> _onRefreshUserProfile(
    RefreshUserProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isAuthenticated) {
      return;
    }

    try {
      final userProfile = await _authRepository.getUserProfile();
      await _localStorageService.saveUserProfile(userProfile);

      final managedRestaurants = userProfile['managedRestaurants'];
      final isVendor = managedRestaurants is List && managedRestaurants.isNotEmpty;

      emit(state.copyWith(
        userProfile: userProfile,
        isVendor: isVendor,
      ));
    } catch (_) {
      // Silently fail - keep current state
    }
  }
}

