import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async'; // Dùng cho TimeoutException
import '../main.dart';
import '../session/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'photo_list_screen.dart';


class SignUpScreen extends StatefulWidget
{
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

// ========================
// AuthService với hàm mới
// ========================
class AuthService
{
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  static const int _timeoutSeconds = 10; // Thời gian chờ tối đa (10 giây)

  // Hàm đăng ký bằng email
  Future<UserCredential?> signUpWithEmail({
    required String name,
    required String email,
    required String password
  }) async
  {
    try
    {
      final userCredential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(const Duration(seconds: _timeoutSeconds));
      await userCredential.user?.updateDisplayName(name);
      return userCredential;
    }
    on TimeoutException
    {
      throw Exception('Hết thời gian chờ. Vui lòng kiểm tra kết nối mạng.');
    }
  }

  // Hàm xác thực Google chung cho đăng ký và đăng nhập
  Future<UserCredential?> authenticateWithGoogle({
    required bool isSignUp,
    BuildContext? context
  }) async
  {
    try
    {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: _timeoutSeconds)
      );
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: _timeoutSeconds)
      );
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential).timeout(
        const Duration(seconds: _timeoutSeconds)
      );

      if (isSignUp && userCredential.additionalUserInfo?.isNewUser == false) 
      {
        await _auth.signOut();
        throw Exception('Tài khoản Google này đã được đăng ký.');
      }

      return userCredential; // Trả về userCredential mà không hiển thị SnackBar
    }
    on TimeoutException
    {
      throw Exception('Hết thời gian chờ. Vui lòng kiểm tra kết nối mạng.');
    }
    catch (e)
    {
      if (context != null && context.mounted) 
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isSignUp ? "Đăng ký" : "Đăng nhập"} bằng Google thất bại: $e'))
        );
      }
      rethrow;
    }
  }
}

// =========================
// SignUpScreen
// =========================
class _SignUpScreenState extends State<SignUpScreen>
{
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  final logger = Logger();
  final AuthService _authService = AuthService();

  @override
  void initState()
  {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose()
  {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() => setState(() => _obscurePassword = !_obscurePassword);

  Future<void> _signUpWithEmail() async
  {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    if (password != _confirmPasswordController.text)
    {
      _showSnackBar('Mật khẩu không khớp');
      return;
    }

    setState(() => _isEmailLoading = true);
    try
    {
      final userCredential = await _authService.signUpWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: password
      );

      if (userCredential != null)
      {
        _handleLoginSuccess(
          userCredential.user!.uid,
          _emailController.text.trim(),
          _nameController.text.trim()
        );
        _showSnackBar('Đăng ký thành công cho ${_nameController.text}');
        await Future.delayed(const Duration(seconds: 2));
        _navigateToLogin();
      }
    }
    catch (e)
    {
      _showErrorDialog(e.toString());
    }
    finally
    {
      setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async
  {
    setState(() => _isGoogleLoading = true);
    try
    {
      final userCredential = await _authService.authenticateWithGoogle(
        isSignUp: true,
        context: context
      );
      if (userCredential != null)
      {
        _handleLoginSuccess(
          userCredential.user!.uid,
          userCredential.user!.email ?? '',
          userCredential.user!.displayName ?? ''
        );
        _showSnackBar('Đăng ký thành công với Google: ${userCredential.user?.displayName ?? ''}');
        await Future.delayed(const Duration(seconds: 2));
        // _navigateToLogin();
        // Quay lại PhotoListScreen
        if (mounted)
        {
          Navigator.pop(context); // Quay lại LoginScreen
          Navigator.pop(context); // Quay lại PhotoListScreen
        }
      }
    }
    catch (e)
    {
      _showErrorDialog(e.toString());
    }
    finally
    {
      setState(() => _isGoogleLoading = false);
    }
  }

  void _showSnackBar(String message)
  {
    if (mounted)
    {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _navigateToLogin()
  {
    if (mounted)
    {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyApp())
      );
    }
    else
    {
      logger.w("Warning: Tried to navigate after widget was unmounted.");
    }
  }

  Future<void> _handleLoginSuccess(String userId, String email, String userName) async
  {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('email', email);
    await prefs.setString('userName', userName);

    UserSession.userId = userId;
    UserSession.email = email;
    UserSession.userName = userName;

  }

  String _mapFirebaseError(String code)
  {
    switch (code)
    {
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return '機器 khẩu quá yếu.';
      default:
      return 'Đã xảy ra lỗi: $code';
    }
  }

  void _showErrorDialog(String message)
  {
    if (mounted)
    {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đăng ký thất bại'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')
            )
          ]
        )
      );
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.purple.shade600]
          )
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tạo tài khoản',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bắt đầu hành trình của bạn ngay hôm nay',
                          style: TextStyle(fontSize: 16, color: Colors.white70)
                        ),
                        const SizedBox(height: 40),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Họ tên',
                          validator: (value) => value?.isEmpty ?? true ? 'Nhập họ tên' : null
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value)
                          {
                            if (value?.isEmpty ?? true) return 'Nhập email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) return 'Email không hợp lệ';
                            return null;
                          }
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          obscureText: _obscurePassword,
                          suffixIcon: _buildPasswordToggle(),
                          validator: (value) => (value?.length ?? 0) < 6 ? 'Mật khẩu ít nhất 6 ký tự' : null
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Nhập lại mật khẩu',
                          obscureText: _obscurePassword,
                          suffixIcon: _buildPasswordToggle(),
                          validator: (value) => (value?.length ?? 0) < 6 ? 'Mật khẩu ít nhất 6 ký tự' : null
                        ),
                        const Spacer(),
                        _buildSignUpButton(),
                        const SizedBox(height: 20),
                        _buildGoogleSignUpButton()
                      ]
                    )
                  )
                )
              )
            ]
          )
        )
      )
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator
  })
  {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1)),
        suffixIcon: suffixIcon
      ),
      validator: validator
    );
  }

  Widget _buildPasswordToggle()
  {
    return IconButton(
      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
      onPressed: _togglePasswordVisibility
    );
  }

  Widget _buildSignUpButton()
  {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isEmailLoading ? null : _signUpWithEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8
        ),
        child: _isEmailLoading
          ? const CircularProgressIndicator(color: Colors.blue)
          : const Text('Đăng ký', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
      )
    );
  }

  Widget _buildGoogleSignUpButton()
  {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        child: _isGoogleLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const[
              Icon(Icons.g_mobiledata, color: Colors.white),
              SizedBox(width: 8),
              Text('Đăng ký với Google', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold))
            ]
          )
      )
    );
  }
}


