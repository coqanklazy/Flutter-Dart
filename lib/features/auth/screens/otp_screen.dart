import 'package:flutter/material.dart';
import 'dart:async';
import 'reset_password_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'registration' hoặc 'password_reset'
  final Map<String, String>? registrationData; // username, password, fullName

  const OTPScreen({
    super.key,
    required this.email,
    this.purpose = 'password_reset',
    this.registrationData,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  int _resendSeconds = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _resendSeconds = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  Future<void> _verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập đủ 6 chữ số'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (widget.purpose == 'registration') {
      await _handleRegistrationOTP(otp);
    } else {
      await _handlePasswordResetOTP(otp);
    }
  }

  Future<void> _handleRegistrationOTP(String otp) async {
    final data = widget.registrationData!;
    final response = await AuthService.verifyRegistrationOTP(
      email: widget.email,
      otpCode: otp,
      username: data['username']!,
      password: data['password']!,
      fullName: data['fullName']!,
      role: data['role'] ?? 'ADMIN',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      // Đăng ký thành công → vào Home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Đăng ký thành công! Bạn có thể đăng nhập ngay bây giờ. 🎉',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      // Quay về màn hình đăng nhập
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showError(response.errorMessage);
    }
  }

  Future<void> _handlePasswordResetOTP(String otp) async {
    // Chỉ cần xác minh OTP rồi chuyển sang màn hình đặt lại mật khẩu
    // OTP sẽ được truyền sang ResetPasswordScreen để gọi API
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ResetPasswordScreen(email: widget.email, otpCode: otp),
      ),
    );
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    late final ApiResponse response;
    if (widget.purpose == 'registration') {
      final data = widget.registrationData!;
      response = await AuthService.sendRegistrationOTP(
        email: widget.email,
        username: data['username']!,
        fullName: data['fullName'],
      );
    } else {
      response = await AuthService.sendPasswordResetOTP(widget.email);
    }

    if (!mounted) return;
    setState(() => _isResending = false);

    if (response.success) {
      _startTimer();
      // Xoá OTP cũ
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi lại mã OTP!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      _showError(response.errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Mask email: ex****@gmail.com
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].length <= 2) return email;
    final name = parts[0];
    return '${name.substring(0, 2)}${'*' * (name.length - 2)}@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isRegistration = widget.purpose == 'registration';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Back Button Row
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Center(
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        isRegistration
                            ? Icons.verified_user_rounded
                            : Icons.lock_reset_rounded,
                        size: 40,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nhập Mã OTP',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mã xác thực 6 chữ số đã được gửi đến\n${_maskEmail(widget.email)}',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // OTP Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // OTP input fields - 6 ô
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 40,
                          height: 58,
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            enabled: !_isLoading,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.blueAccent,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              }
                              if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                              // Tự động xác nhận khi nhập đủ 6 số
                              if (index == 5 && value.isNotEmpty) {
                                String otp = _controllers
                                    .map((c) => c.text)
                                    .join();
                                if (otp.length == 6) {
                                  _verifyOTP();
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _verifyOTP,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isLoading ? 'Đang xác thực...' : 'Xác Nhận',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          disabledBackgroundColor: Colors.blueAccent
                              .withOpacity(0.7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Không nhận được mã? ',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: _canResend ? _resendOTP : null,
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _canResend
                                      ? 'Gửi lại'
                                      : 'Gửi lại (${_resendSeconds}s)',
                                  style: TextStyle(
                                    color: _canResend
                                        ? Colors.blueAccent
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
