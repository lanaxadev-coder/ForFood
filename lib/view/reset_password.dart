// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:forfood/core/theme/app_color.dart';
// import 'package:forfood/core/widgets/snack_bar.dart';


// class ResetPasswordView extends StatefulWidget {
//   final UserRole role;
//   final bool isEmail;
//   final String? identifier;

//   const ResetPasswordView({
//     super.key,
//     required this.role,
//     required this.isEmail,
//     required this.identifier,
//   });

//   @override
//   State<ResetPasswordView> createState() => _ResetPasswordViewState();
// }

// class _ResetPasswordViewState extends State<ResetPasswordView> {
//   final _smsCodeController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   @override
//   void dispose() {
//     _smsCodeController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _submit() {
//     final smsCode = _smsCodeController.text.trim();
//     final password = _passwordController.text;
//     final confirmation = _confirmPasswordController.text;

//     if (!widget.isEmail && smsCode.length != 6) {
//       AppSnackbar.showError(context, 'Enter the 6-digit code sent to your phone.');
//       return;
//     }
//     if (password.length < 6) {
//       AppSnackbar.showError(context, 'Password must be at least 6 characters.');
//       return;
//     }
//     if (password != confirmation) {
//       AppSnackbar.showError(context, 'Passwords do not match.');
//       return;
//     }

//     context.read<AuthBloc>().add(AuthEventResetPassword(
//           newPassword: password,
//           confirmPassword: confirmation,
//           role: widget.role,
//           // Phone resets must present the code stored by sendPasswordResetSMS.
//           smsCode: widget.isEmail ? null : smsCode,
//         ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<AuthBloc, AuthState>(
//       listener: (context, state) {
//         if (state is AuthStateForgotPassword && state.exception != null) {
//           AppSnackbar.showError(context, state.exception.toString());
//         }
//         if (state is AuthStatePasswordResetSuccess) {
//           AppSnackbar.showSuccess(context, 'Password reset successfully!');
//           Navigator.popUntil(context, (route) => route.isFirst);
//         }
//       },
//       builder: (context, state) {
//         final isLoading = state.isLoading;
//         return Scaffold(
//           backgroundColor: AppColor.yellow,
//           appBar: AppBar(
//             backgroundColor: AppColor.yellow,
//             foregroundColor: AppColor.white,
//             elevation: 0,
//             title: const Text('Reset Password'),
//           ),
//           body: SafeArea(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Text(
//                       widget.isEmail
//                           ? 'Use the link in your email to reset your password.'
//                           : 'Enter the code sent to ${widget.identifier ?? 'your phone'}.',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                     const SizedBox(height: 24),
//                     if (!widget.isEmail) ...[
//                       TextField(
//                         controller: _smsCodeController,
//                         keyboardType: TextInputType.number,
//                         maxLength: 6,
//                         decoration: const InputDecoration(
//                           labelText: 'SMS verification code',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                     ],
//                     TextField(
//                       controller: _passwordController,
//                       obscureText: true,
//                       decoration: const InputDecoration(
//                         labelText: 'New password',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _confirmPasswordController,
//                       obscureText: true,
//                       decoration: const InputDecoration(
//                         labelText: 'Confirm password',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     FilledButton(
//                       onPressed: isLoading ? null : _submit,
//                       style: FilledButton.styleFrom(backgroundColor: AppColor.orange),
//                       child: Text(isLoading ? 'Resetting...' : 'Reset password'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
