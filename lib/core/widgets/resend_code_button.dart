import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

class ResendCodeButton extends StatefulWidget {
  final int initialSeconds;

  /// 👈 Now async — the button waits for this to complete before
  /// resetting the timer. Resolves when the email is actually sent.
  final Future<void> Function() onResend;

  const ResendCodeButton({
    super.key,
    this.initialSeconds = 45,
    required this.onResend,
  });

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  late int _secondsRemaining;
  Timer? _resendTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    // 👈 Wait for the real send
    await widget.onResend();

    if (!mounted) return;

    // ✅ Email confirmed sent → now restart the timer
    setState(() {
      _secondsRemaining = widget.initialSeconds;
      _isSending = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final canTap = _secondsRemaining == 0 && !_isSending;

    return GestureDetector(
      onTap: canTap ? _handleTap : null,
      child: _isSending
          // 👈 While sending: small spinner + label
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColor.brown,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sending...',
                  style: TextStyle(
                    color: AppColor.brown,
                    fontFamily: 'League Spartan',
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            )
          // Default: countdown or "Resend code"
          : Text(
              _secondsRemaining > 0
                  ? 'Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}'
                  : 'Resend code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.brown,
                fontFamily: 'League Spartan',
                fontSize: 14,
                fontWeight: FontWeight.normal,
                height: 1,
              ),
            ),
    );
  }
}