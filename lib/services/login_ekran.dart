// lib/screens/auth/login_ekran.dart
import 'package:flutter/material.dart';
import 'package:huzur_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginEkrani extends StatefulWidget {
  const LoginEkrani({super.key});
  @override
  State<LoginEkrani> createState() => _LoginEkraniState();
}

class _LoginEkraniState extends State<LoginEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLogin = true;
  bool _isLoading = false;

  // GÜNCELLENDİ: Tüm auth fonksiyonlarını tek bir yerde toplayan ana fonksiyon
  Future<void> _performAuthAction(
      Future<UserCredential?> Function() authFunction) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final userCredential = await authFunction();
      // Eğer işlem başarılıysa ve bir kullanıcı döndüyse, bir önceki ekrana dön.
      if (userCredential != null && mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      // Kullanıcı Google girişini iptal ettiyse sessiz kal
      if (e.code == 'USER_CANCELLED') {
        // Hiçbir şey yapma
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Bir hata oluştu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilinmeyen bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // GÜNCELLENDİ: Artık ana fonksiyonu çağırıyorlar
  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_isLogin) {
      _performAuthAction(() => _authService.signInWithEmail(
          _emailController.text, _passwordController.text));
    } else {
      _performAuthAction(() => _authService.createUserWithEmail(
          _emailController.text, _passwordController.text));
    }
  }

  void _signInAnonymously() {
    _performAuthAction(() => _authService.signInAnonymously());
  }

  void _signInWithGoogle() {
    _performAuthAction(() => _authService.signInWithGoogle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.mosque_outlined,
                    size: 80, color: Colors.blue.shade300),
                const SizedBox(height: 20),
                Text(
                  'Huzur\'a Hoş Geldiniz',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('E-posta'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            (value == null || !value.contains('@'))
                                ? 'Geçerli bir e-posta girin.'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Şifre'),
                        obscureText: true,
                        validator: (value) =>
                            (value == null || value.length < 6)
                                ? 'Şifre en az 6 karakter olmalıdır.'
                                : null,
                      ),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade400,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _submit,
                          child: Text(_isLogin ? 'GİRİŞ YAP' : 'KAYIT OL'),
                        ),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'Hesabın yok mu? Kayıt ol'
                              : 'Zaten bir hesabın var mı? Giriş yap',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SignInButton(
                        Buttons.google,
                        text: "Google ile Devam Et",
                        onPressed: _signInWithGoogle,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _signInAnonymously,
                        child: Text(
                          'Misafir olarak devam et',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.blue.shade300),
      ),
    );
  }
}
