// // lib/view/onboarding_wrapper.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:forfood/services/restaurant/bloc/onboarding/onboarding_bloc.dart';
// import 'package:forfood/services/restaurant/bloc/onboarding/onboarding_state.dart';
// import 'package:forfood/services/restaurant/bloc/auth/auth_bloc.dart';
// import 'package:forfood/services/restaurant/bloc/auth/auth_event.dart';
// import 'package:forfood/view/on_boarding1.dart';
// import 'package:forfood/view/on_boarding2.dart';
// import 'package:forfood/view/on_boarding3.dart';

// class OnboardingWrapper extends StatelessWidget {
//   const OnboardingWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => OnboardingBloc(),
//       child: BlocConsumer<OnboardingBloc, OnboardingState>(
//         listener: (context, state) {
//           // ✅ When onboarding completes, tell AuthBloc
//           if (state is OnboardingCompletedState) {
//             context.read<AuthBloc>().add(
//               const AuthEventOnboardingComplete()
//             );
//           }
//         },
//         builder: (context, state) {
//           // ✅ Show different pages based on state
//           if (state is OnboardingPageState) {
//             switch (state.pageIndex) {
//               case 0:
//                 return const OnBoarding1();
//               case 1:
//                 return const OnBoarding2View();
//               case 2:
//                 return const OnBoarding3View();
//               default:
//                 return const OnBoarding1();
//             }
//           }

//           // Loading or error state
//           return const Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }