import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KitapDinleListele extends StatefulWidget {
  const KitapDinleListele({super.key});

  @override
  _KitapDinleListeleState createState() => _KitapDinleListeleState();
}

class _KitapDinleListeleState extends State<KitapDinleListele> {
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

  void _toggleFavorite(String kitapAdi, String kitapUrl) async {
    if (_user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      final favoriteRef = userDoc.collection('favori_kitap_dinleme').doc(kitapAdi);

      if (_favoriler[kitapAdi] == true) {
        
        await favoriteRef.delete();
        setState(() {
          _favoriler[kitapAdi] = false;
        });
      } else {
        
        await favoriteRef.set({
          'kitap_adi': kitapAdi,
          'kitap_url': kitapUrl,
        });
        setState(() {
          _favoriler[kitapAdi] = true;
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
      final favoriteBooksSnapshot = await userDoc.collection('favori_kitap_dinleme').get();

      for (var doc in favoriteBooksSnapshot.docs) {
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
            "KİTAPLAR",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 138, 45, 196),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('kitap_dinleme').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Hata: ${snapshot.error}"));
              }

              final kitaplar = snapshot.data!.docs;

              if (kitaplar.isEmpty) {
                return const Center(child: Text("Dinlenebilecek kitap bulunamadı."));
              }

              return ListView.builder(
                itemCount: kitaplar.length,
                itemBuilder: (context, index) {
                  final kitap = kitaplar[index];
                  final kitapAdi = kitap['kitap_adi'];
                  final kitapUrl = kitap['kitap_url'];
                  final kitapGorsel = kitap['kitap_jpg']; 

                  bool isFavori = _favoriler[kitapAdi] ?? false;
                  bool isPlaying = _playingStatus[kitapAdi] ?? false;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: kitapGorsel != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                kitapGorsel,
                                width: 60, 
                                height: 100, 
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.book, size: 80),
                      title: Text(
                        kitapAdi,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis, 
                        maxLines: 2, 
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          IconButton(
                            icon: Icon(
                              isFavori ? Icons.favorite : Icons.favorite_border,
                              color: isFavori ? Colors.red : null,
                            ),
                            onPressed: () {
                              _toggleFavorite(kitapAdi, kitapUrl);
                            },
                          ),
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
                              color: Colors.blueAccent,
                            ),
                            onPressed: () {
                              _toggleAudio(kitapAdi, kitapUrl);
                            },
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
      ),
    );
  }
}
