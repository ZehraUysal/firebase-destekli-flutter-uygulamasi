import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pdf_viewer_page.dart';

class Favorilerim extends StatefulWidget {
  final String kitapTuru; 
  final String userId;

  const Favorilerim({
    Key? key,
    required this.kitapTuru,
    required this.userId,
  }) : super(key: key);

  @override
  _FavorilerimState createState() => _FavorilerimState();
}

class _FavorilerimState extends State<Favorilerim> {
  late AudioPlayer _audioPlayer;
  late User? _user;
  Map<String, bool> _favoriler = {};
  Map<String, bool> _playingStatus = {};
  Map<String, int> _devamSureleri = {};
  String? _currentPlayingBook;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _user = FirebaseAuth.instance.currentUser;
    _getFavoriler();
    _getDevamSureleri();
  }

  void _toggleAudio(String kitapAdi, String url, {bool baslangic = false}) async { 
    if (_currentPlayingBook == kitapAdi && _playingStatus[kitapAdi] == true) {
      
      await _audioPlayer.pause();
      setState(() {
        _playingStatus[kitapAdi] = false;
      });
    } else {
      if (_currentPlayingBook != null && _currentPlayingBook != kitapAdi) {
        
        setState(() {
          _playingStatus[_currentPlayingBook!] = false;
        });
        await _audioPlayer.stop();
      }

      
      if (baslangic) {
        
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url)); 
      } else {
        if (_playingStatus[kitapAdi] == false) {
          
          final currentPosition = await _audioPlayer.getCurrentPosition();
          _devamSureleri[kitapAdi] = currentPosition?.inSeconds ?? 0;
        }

        await _audioPlayer.play(UrlSource(url));
        await _audioPlayer.seek(Duration(seconds: _devamSureleri[kitapAdi] ?? 0));
      }

      setState(() {
        _playingStatus[kitapAdi] = true;
        _currentPlayingBook = kitapAdi;
      });
    }
  }

  void _removeFromFavorites(String kitapId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection(widget.kitapTuru) 
          .doc(kitapId)
          .delete(); 

      
      setState(() {
        
      });
    } catch (e) {
      print("Favorilerden çıkarma hatası: $e");
    }
  }

  void _saveProgress(String kitapAdi, String kitapUrl) async {
    if (_user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      final kaydedilenRef = userDoc.collection('kaydedilen_kitaplar').doc(kitapAdi);
      final currentPosition = await _audioPlayer.getCurrentPosition();

      if (currentPosition != null) {
        await kaydedilenRef.set({
          'kitap_adi': kitapAdi,
          'kitap_url': kitapUrl,
          'devam_suresi': currentPosition.inSeconds,
        });
        setState(() {
          _devamSureleri[kitapAdi] = currentPosition.inSeconds;
        });
      }
    }
  }
  void _getDevamSureleri() async {
    if (_user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      final kaydedilenSnapshot = await userDoc.collection('kaydedilen_kitaplar').get();

      for (var doc in kaydedilenSnapshot.docs) {
        setState(() {
          _devamSureleri[doc['kitap_adi']] = doc['devam_suresi'];
        });
      }
    }
  }

  void _getFavoriler() async {
    if (_user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      
      
      final favoriteBooksDinlemeSnapshot = await userDoc.collection('favori_kitap_dinleme').get(); 
      
      for (var doc in favoriteBooksDinlemeSnapshot.docs) {
        setState(() {
          _favoriler[doc['kitap_adi']] = true;
        });
      }
      
      
      final favoriteBooksOkumaSnapshot = await userDoc.collection('favori_kitap_okuma').get();
      
      for (var doc in favoriteBooksOkumaSnapshot.docs) {
        setState(() {
          _favoriler[doc['kitap_adi']] = true;
        });
      }
    }
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _audioPlayer.stop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          title: const Text(
            "Favorilerim",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 138, 45, 196),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users')
                .doc(widget.userId)
                .collection(widget.kitapTuru) 
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Hata: ${snapshot.error}"));
              }

              final kitaplar = snapshot.data!.docs;

              if (kitaplar.isEmpty) {
                return const Center(child: Text("Favori kitap bulunamadı."));
              }
              return ListView.builder(
                itemCount: kitaplar.length,
                itemBuilder: (context, index) {
                  final kitapAdi = kitaplar[index]['kitap_adi'];
                  final kitapUrl = kitaplar[index]['kitap_url'];
                  final kitapId = kitaplar[index].id;
                  bool isPlaying = _playingStatus[kitapAdi] ?? false;
                  String kitapYazari = '';
                  Widget actionButton;

                  
                  if (widget.kitapTuru == 'favori_kitap_okuma') {
                    kitapYazari = kitaplar[index]['kitap_yazari'] ?? 'Bilinmiyor';
                    actionButton = ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PDFViewerPage(
                              pdfUrl: kitapUrl, 
                              kitapAdi: kitapAdi, 
                            ),
                          ),
                        );
                      },
                      child: const Text("Oku", style: TextStyle(fontSize: 16)),
                    );
                  }
                  
                  else {
                    actionButton = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.save,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            _saveProgress(kitapAdi, kitapUrl);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.replay,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            _toggleAudio(kitapAdi, kitapUrl, baslangic: true);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: _playingStatus[kitapAdi] ?? false ? Colors.blueAccent : Colors.black,
                          ),
                          onPressed: () {
                            _toggleAudio(kitapAdi, kitapUrl);
                          },
                        ),
                      ],
                    );
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        kitapAdi,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: widget.kitapTuru == 'favori_kitap_okuma'
                          ? Text("Yazar: $kitapYazari", style: TextStyle(fontSize: 14, color: Colors.grey[700]))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                         
                        IconButton(
                          icon: Icon(
                            _favoriler[kitapAdi] == true ? Icons.favorite : Icons.favorite_border,
                            color: _favoriler[kitapAdi] == true ? Colors.red : null,
                          ),
                          onPressed: () {
                           _removeFromFavorites(kitapId);
                          },
                        ),
                          actionButton, 
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}



