import '../entities/user_entity.dart';
import '../repositories/user_repository_interface.dart';

class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repository);

  final UserRepositoryInterface _repository;

  Future<UserEntity?> call() => _repository.getCurrentUser();
}
