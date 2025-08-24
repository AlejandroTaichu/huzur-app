// lib/screens/auth/login_ekrani.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:huzur_app/main.dart';
import 'package:huzur_app/screens/sureler_ekrani.dart';

class LoginEkrani extends StatefulWidget {
  const LoginEkrani({super.key});
  @override
  State<LoginEkrani> createState() => _LoginEkraniState();
}

class _LoginEkraniState extends State<LoginEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  // Bu fonksiyon, tüm Firebase işlemlerini tek bir yerden yönetir.
  Future<void> _handleAuthAction(
    Future<UserCredential> Function() authAction,
  ) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final credential = await authAction();

      // Başarılı giriş sonrası ana sayfaya yönlendir
      if (credential.user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AnaSayfa()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_isLogin) {
      _handleAuthAction(
        () => FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    } else {
      _handleAuthAction(
        () => FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  void _signInAnonymously() {
    _handleAuthAction(() => FirebaseAuth.instance.signInAnonymously());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[800],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta Adresi',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Lütfen geçerli bir e-posta adresi girin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Şifre'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Şifre en az 6 karakter olmalıdır.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text(_isLogin ? 'GİRİŞ YAP' : 'KAYIT OL'),
                      ),
                    if (!_isLoading)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Hesabın yok mu? Kayıt ol'
                              : 'Zaten bir hesabın var mı? Giriş yap',
                        ),
                      ),
                    if (!_isLoading) const Divider(height: 20),
                    if (!_isLoading)
                      TextButton(
                        onPressed: _signInAnonymously,
                        child: const Text(
                          'Misafir olarak devam et',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
