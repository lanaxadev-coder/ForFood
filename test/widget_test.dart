// import 'package:bloc_test/bloc_test.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:forfood/services/restaurant/auth/auth_provider.dart';
// import 'package:forfood/services/restaurant/auth/auth_user.dart';
// import 'package:forfood/services/restaurant/bloc/signUp/signup_bloc.dart';
// import 'package:forfood/services/restaurant/bloc/signUp/signup_event.dart';
// import 'package:forfood/services/restaurant/bloc/signUp/signup_state.dart';
// import 'package:mocktail/mocktail.dart';

// class _MockAuthProvider extends Mock implements IAuthProvider {}

// void main() {
//   group('SignupBloc', () {
//     late _MockAuthProvider provider;

//     setUp(() {
//       provider = _MockAuthProvider();
//     });

//     blocTest<SignupBloc, SignupState>(
//       'waits for Firebase to provide an SMS verification ID',
//       build: () {
//         when(
//           () => provider.verifyPhoneNumber(
//             phoneNumber: any(named: 'phoneNumber'),
//             codeSent: any(named: 'codeSent'),
//             onError: any(named: 'onError'),
//           ),
//         ).thenAnswer((invocation) async {
//           final callback = invocation.namedArguments[#codeSent]
//               as void Function(String);
//           callback('verification-id');
//         });

//         return SignupBloc(provider);
//       },
//       act: (bloc) => bloc.add(const SignupPhoneSubmitted(
//         phoneNumber: '+15551234567',
//         password: 'secure-password',
//         fullName: 'Test User',
//         role: UserRole.user,
//       )),
//       expect: () => [
//         isA<SignupLoading>(),
//         isA<SignupNavigateToVerification>()
//             .having((state) => state.phoneNumber, 'phone number', '+15551234567'),
//       ],
//     );
//   });
// }
