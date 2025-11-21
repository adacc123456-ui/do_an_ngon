import 'package:dartz/dartz.dart';
import 'package:do_an_ngon/src/core/error/failures.dart';

abstract class SplashRepository {
  Future<Either<Failure, void>> initializeApp();
}

