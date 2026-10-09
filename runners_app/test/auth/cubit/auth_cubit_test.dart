import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/auth/auth.dart';
import 'package:runners_app/models/app_user.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

void main() {
  late _MockAuthRepository repository;

  const user = AppUser(
    id: 'user-1',
    phoneNumber: '+260971000001',
    fullName: 'Amina Banda',
    role: 'requester',
    isVerified: false,
  );

  setUp(() {
    repository = _MockAuthRepository();
  });

  blocTest<AuthCubit, AuthState>(
    'emits authenticated when restore finds a user',
    setUp: () {
      when(repository.restore).thenAnswer((_) async => user);
    },
    build: () => AuthCubit(repository),
    act: (cubit) => cubit.restore(),
    expect: () => [const AuthState.authenticated(user)],
  );

  blocTest<AuthCubit, AuthState>(
    'emits unauthenticated when login fails',
    setUp: () {
      when(
        () => repository.login(
          phoneNumber: any(named: 'phoneNumber'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ApiException(
          code: 'UNAUTHORIZED',
          message: 'Phone number or password is incorrect',
        ),
      );
    },
    build: () => AuthCubit(repository),
    act: (cubit) =>
        cubit.login(phoneNumber: '970000000', password: 'password123'),
    expect: () => [
      const AuthState(status: AuthStatus.unknown, submitting: true),
      const AuthState.unauthenticated(
        message: 'Phone number or password is incorrect',
      ),
    ],
  );
}
