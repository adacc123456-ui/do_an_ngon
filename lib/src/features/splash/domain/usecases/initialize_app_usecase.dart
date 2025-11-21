import 'package:dartz/dartz.dart';
import 'package:do_an_ngon/src/core/error/failures.dart';
import 'package:do_an_ngon/src/features/splash/domain/repositories/splash_repository.dart';

class InitializeAppUseCase {
  final SplashRepository repository;

  InitializeAppUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.initializeApp();
  }
}

