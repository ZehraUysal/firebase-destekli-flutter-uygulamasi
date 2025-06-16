import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'pdf_viewer_page.dart'; 

class KitapIsmiGoster extends StatefulWidget {
  const KitapIsmiGoster({super.key});


  @override
  _KitapIsmiGosterState createState() => _KitapIsmiGosterState();
}

class _KitapIsmiGosterState extends State<KitapIsmiGoster> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _user;
  Map<String, bool> _favoriler = {}; 

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _getFavoriler(); 
  }

  
  void _getFavoriler() async {
    if (_user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      final favoriteBooksSnapshot = await userDoc.collection('favori_kitap_okuma').get();

      
      for (var doc in favoriteBooksSnapshot.docs) {
        setState(() {
          _favoriler[doc['kitap_adi']] = true;
        });
      }
    }
  }

  
  void _toggleFavorite(String kitapAdi, String kitapUrl, String kitapYazari) async {
    if (_user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      final favoriteRef = userDoc.collection('favori_kitap_okuma').doc(kitapAdi);

      if (_favoriler[kitapAdi] == true) {
       
        await favoriteRef.delete();
        setState(() {
          _favoriler[kitapAdi] = false;
        });
      } else {
        
        await favoriteRef.set({
          'kitap_adi': kitapAdi,
          'kitap_url': kitapUrl,
          'kitap_yazari': kitapYazari,
        });
        setState(() {
          _favoriler[kitapAdi] = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], 
      appBar: AppBar(
        title: const Text("KİTAPLAR", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 138, 45, 196), 
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('kitap_okuma').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Hata: ${snapshot.error}"));
            }

            final kitaplar = snapshot.data!.docs;

            if (kitaplar.isEmpty) {
              return const Center(child: Text("Kitap bulunamadı."));
            }

            return ListView.builder(
              itemCount: kitaplar.length,
              itemBuilder: (context, index) {
                final kitapAdi = kitaplar[index]['kitap_adi'];
                final pdfUrl = kitaplar[index]['kitap_url'];
                final kitapYazari = kitaplar[index]['kitap_yazari'];
                final kitapGorsel = kitaplar[index]['kitap_jpg']; 

                
                bool isFavori = _favoriler[kitapAdi] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Görsel
                        kitapGorsel != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8), 
                                child: Image.network(
                                  kitapGorsel,
                                  width: 100, 
                                  height: 150, 
                                  fit: BoxFit.cover, 
                                ),
                              )
                            : const Icon(Icons.book, size: 100), 

                        const SizedBox(width: 10), 

                        
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: [
                              const SizedBox(height: 10), 
                              Text(
                                kitapAdi,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center, 
                              ),
                              const SizedBox(height: 8),
                              Text(
                                kitapYazari,
                                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center, 
                              ),
                            ],
                          ),
                        ),

                        
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            
                            IconButton(
                              icon: Icon(
                                isFavori ? Icons.favorite : Icons.favorite_border,
                                color: isFavori ? Colors.red : null,
                              ),
                              onPressed: () {
                                _toggleFavorite(kitapAdi, pdfUrl, kitapYazari);
                              },
                            ),
                            
                            ElevatedButton(
                              onPressed: () {
                                
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewerPage(
                                      pdfUrl: pdfUrl,
                                      kitapAdi: kitapAdi, 
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              child: const Text("Oku"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
