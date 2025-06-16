import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kitap_oku_listele.dart';
import 'kitap_dinle_listele.dart';
import 'favorilerim.dart';
import 'login_register_page.dart';

class KitapSecimSayfasi extends StatelessWidget {
  const KitapSecimSayfasi({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginRegisterPage()),
      );
    } catch (e) {
      print("Sign out error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "HOŞGELDİNİZ",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 138, 45, 196),
        elevation: 5,
      ),
      body: CustomPaint(
        painter: PaintSplatPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                _buildButton(
                  context,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const KitapIsmiGoster()),
                    );
                  },
                  icon: Icons.book,
                  text: "Kitap Oku",
                ),
                const SizedBox(height: 20),

                _buildButton(
                  context,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const KitapDinleListele()),
                    );
                  },
                  icon: Icons.headphones,
                  text: "Kitap Dinle",
                ),
                const SizedBox(height: 50),

                if (user != null) ...[
                  _buildButton(
                    context,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Favorilerim(
                            kitapTuru: 'favori_kitap_okuma',
                            userId: user.uid,
                          ),
                        ),
                      );
                    },
                    icon: Icons.favorite,
                    text: "Favori Okuma Kitaplarım",
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    context,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Favorilerim(
                            kitapTuru: 'favori_kitap_dinleme',
                            userId: user.uid,
                          ),
                        ),
                      );
                    },
                    icon: Icons.favorite,
                    text: "Favori Dinleme Kitaplarım",
                  ),
                ],
                if (user == null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Lütfen giriş yapın ve favorilere erişin.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 150),

                if (user != null) ...[
                  _buildButton(
                    context,
                    onPressed: () => _signOut(context),
                    icon: Icons.exit_to_app,
                    text: "Çıkış Yap",
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required VoidCallback onPressed, required IconData icon, required String text}) {
    return InkWell(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.withOpacity(0.5), Colors.purple.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class PaintSplatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    Random random = Random();

    
    for (int i = 0; i < 100; i++) {
      
      paint.color = Color.fromRGBO(
        (190 + random.nextInt(30)), 
        (150 + random.nextInt(30)), 
        (200 + random.nextInt(30)), 
        random.nextDouble() * 0.4 + 0.2, 
      );

      
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = random.nextDouble() * 50 + 20; 

      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; 
  }
}







