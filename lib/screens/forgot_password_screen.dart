import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/services/api_client.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';

/// Password reset for riders and partners.
///
/// Two steps against the backend:
///   POST /auth/{role}/forgot-password  { email }  or  { phone }
///   POST /auth/{role}/reset-password   { email|phone, otp, newPassword }
///
/// Exactly one identifier is allowed, which is why this screen makes the
/// customer pick a channel rather than sending whatever is filled in. The
/// reset signs every device out, so they have to log in again afterwards -
/// that is the point of it.
class ForgotPasswordScreen extends StatefulWidget {
  /// 'rider' or 'vendor' - decides which endpoints are called.
  final String role;

  const ForgotPasswordScreen({super.key, required this.role});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Channel { email, phone }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  _Channel _channel = _Channel.email;
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  bool get _isRider => widget.role == 'rider';

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(String message, {bool bad = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bad ? const Color(0xFFDC2626) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// `{ email: ... }` or `{ phone: ... }` - never both, the server rejects that.
  Map<String, dynamic> get _identifierBody {
    final value = _identifierController.text.trim();
    return _channel == _Channel.email ? {'email': value} : {'phone': value};
  }

  String? _validateIdentifier() {
    final value = _identifierController.text.trim();
    if (value.isEmpty) {
      return _channel == _Channel.email ? 'Enter your registered email address' : 'Enter your registered mobile number';
    }
    if (_channel == _Channel.email && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'That does not look like an email address';
    }
    if (_channel == _Channel.phone && value.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'Enter a 10-digit mobile number';
    }
    return null;
  }

  Future<void> _sendCode() async {
    final problem = _validateIdentifier();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.post('/auth/${widget.role}/forgot-password', _identifierBody);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _busy = false;
      });
      _toast(res['message']?.toString() ?? 'Reset code sent.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    if (otp.length < 4) {
      setState(() => _error = 'Enter the code we sent you');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Your new password must be at least 8 characters');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiClient.instance.post('/auth/${widget.role}/reset-password', {
        ..._identifierBody,
        'otp': otp,
        'newPassword': password,
      });
      if (!mounted) return;
      _toast('Password updated. Please sign in with your new password.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: const CustomBackButton(),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _codeSent ? 'Enter the code' : 'Where should we send the code?',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'We sent a code to ${_identifierController.text.trim()}. Enter it below with your new password.'
                    : _isRider
                        ? 'We will send a reset code to your registered email or mobile number.'
                        : 'We will send a reset code to the email or mobile registered for your shop.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 24),

              if (!_codeSent) ...[
                SegmentedButton<_Channel>(
                  segments: const [
                    ButtonSegment(value: _Channel.email, label: Text('Email'), icon: Icon(Icons.mail_outline)),
                    ButtonSegment(value: _Channel.phone, label: Text('Mobile'), icon: Icon(Icons.phone_outlined)),
                  ],
                  selected: {_channel},
                  onSelectionChanged: (s) => setState(() {
                    _channel = s.first;
                    _identifierController.clear();
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _identifierController,
                  keyboardType: _channel == _Channel.email ? TextInputType.emailAddress : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _channel == _Channel.email ? 'Registered email' : 'Registered mobile number',
                    hintText: _channel == _Channel.email ? 'you@example.com' : '9876543210',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Reset code',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    helperText: 'At least 8 characters',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _busy ? null : (_codeSent ? _resetPassword : _sendCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _codeSent ? 'Set New Password' : 'Send Reset Code',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              if (_codeSent) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _otpController.clear();
                              _passwordController.clear();
                              _error = null;
                            }),
                    child: const Text('Use a different email or number'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
