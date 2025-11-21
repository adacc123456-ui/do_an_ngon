import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:do_an_ngon/src/features/splash/presentation/bloc/splash_state.dart';
import 'package:do_an_ngon/src/features/splash/domain/usecases/initialize_app_usecase.dart';

part 'splash_event.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final InitializeAppUseCase initializeAppUseCase;

  SplashBloc({
    required this.initializeAppUseCase,
  }) : super(const SplashState(status: SplashStatus.initial)) {
    on<InitializeAppEvent>(_onInitializeApp);
  }

  Future<void> _onInitializeApp(
    InitializeAppEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(state.copyWith(status: SplashStatus.loading));

    final result = await initializeAppUseCase();

    result.fold(
      (failure) {
        // Handle failure if needed
        emit(state.copyWith(status: SplashStatus.completed));
      },
      (_) {
        emit(state.copyWith(status: SplashStatus.completed));
      },
    );
  }
}

