import 'package:firebasedeneme/pages/kitap_secmek.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebasedeneme/services/auth.dart';
import 'package:flutter/material.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController(); 
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode(); 

  bool isLogin = true;
  String? errorMessage;
  String? successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(emailFocusNode);
    });
  }

  Future<void> createUser() async {
    
    if (emailController.text.isEmpty) {
      setState(() {
        errorMessage = "Email alanı boş bırakılamaz.";
        successMessage = null;
      });
      return;
    }

    
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = "Şifreler eşleşmiyor.";
        successMessage = null;
      });
      return;
    }

    
    try {
      await Auth().createUser(
        email: emailController.text,
        password: passwordController.text,
      );
      setState(() {
        successMessage = "Kayıt Başarılı";
        errorMessage = null;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          errorMessage = "Bu email zaten kullanımda.";
          successMessage = null;
        });
      } else if (e.code == 'invalid-email') {
        setState(() {
          errorMessage = "Geçersiz bir email adresi girdiniz.";
          successMessage = null;
        });
      } else {
        setState(() {
          errorMessage = e.message;
          successMessage = null;
        });
      }
    }
  }


  Future<void> logIn() async {
    
    if (emailController.text.isEmpty) {
      setState(() {
        errorMessage = "Email alanı boş bırakılamaz.";
        successMessage = null;
      });
      return;
    }

    
    if (passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "Şifre alanı boş bırakılamaz.";
        successMessage = null;
      });
      return;
    }

    
    try {
      await Auth().logIn(
        email: emailController.text,
        password: passwordController.text,
      );
      setState(() {
        successMessage = "Giriş Başarılı";
        errorMessage = null;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KitapSecimSayfasi()),
      );
    } on FirebaseAuthException catch (e) {
      
      switch (e.code) {
        case 'user-not-found':
          setState(() {
            errorMessage = "Bu email ile kayıtlı bir kullanıcı bulunamadı.";
            successMessage = null;
          });
          break;
        case 'wrong-password':
          setState(() {
            errorMessage = "Yanlış şifre girdiniz.";
            successMessage = null;
          });
          break;
        case 'invalid-email':
          setState(() {
            errorMessage = "Geçersiz bir email adresi girdiniz.";
            successMessage = null;
          });
          break;
        default:
          setState(() {
            errorMessage = "Bir hata oluştu: ${e.message}";
            successMessage = null;
          });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Beklenmeyen bir hata oluştu: ${e.toString()}";
        successMessage = null;
      });
    }
  }
  
  @override
  void dispose() {
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 207, 146, 217),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Text(
                isLogin ? "Giriş Yap" : "Kayıt Ol",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 138, 45, 196),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                focusNode: emailFocusNode,
                decoration: InputDecoration(
                  hintText: "Email",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                focusNode: passwordFocusNode,
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.visiblePassword,
              ),
              if (!isLogin)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      focusNode: confirmPasswordFocusNode,
                      decoration: InputDecoration(
                        hintText: "Şifre Tekrar",
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.visiblePassword,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (successMessage != null) ...[
                Text(
                  successMessage!,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (isLogin) {
                    logIn();
                  } else {
                    createUser();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 184, 253),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(isLogin ? "Giriş Yap" : "Kayıt Ol"),
              ),
              const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  isLogin = !isLogin;
                  errorMessage = null; 
                  successMessage = null; 
                });
              },
              child: Text(
                isLogin ? "Henüz Hesabım Yok." : "Zaten Hesabım Var.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 138, 45, 196),
                ),
              ),
            ),

            ],
          ),
        ),
      ),
    );
  }
}

