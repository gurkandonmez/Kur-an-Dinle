import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:diacritic/diacritic.dart';
import 'package:just_audio/just_audio.dart';

// ======= AYAR =======
// Emülatörde PC'nin localhost'u 10.0.2.2'dır. Portu kendi HTTP portunla değiştir.
const String kBase = 'http://10.0.2.2:5035';

void main() => runApp(const QuranApp());

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sesli Kur’an',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B86E5),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Hoş geldiniz',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SurahListPage()),
                    ),
                child: const Text('Uygulamaya Başla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ MODELLER ------------------
class Surah {
  final int id;
  final String name;
  final int ayahCount;
  final String revelationType;
  Surah({
    required this.id,
    required this.name,
    required this.ayahCount,
    required this.revelationType,
  });
  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
    id: j['id'],
    name: j['name'],
    ayahCount: j['ayahCount'],
    revelationType: j['revelationType'],
  );
}

class Ayah {
  final int number;
  final String filePath; // tam URL veya relative
  final int durationMs;
  final int sizeKB;
  Ayah({
    required this.number,
    required this.filePath,
    required this.durationMs,
    required this.sizeKB,
  });
  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
    number: j['number'],
    filePath: j['filePath'],
    durationMs: j['durationMs'] ?? 0,
    sizeKB: j['sizeKB'] ?? 0,
  );
}

// ------------------ SURE LİSTESİ ------------------
class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});
  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  final _searchCtrl = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  List<Surah> _all = [];
  List<Surah> _filtered = [];
  int _shown = 10; // başlangıçta 10
  final int _page = 10;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSurahs();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String normalize(String s) {
    s = s.toLowerCase();
    s = removeDiacritics(s);
    s = s.replaceAll('ı', 'i');
    return s;
  }

  // --- Mekkî / Medenî yardımcısı + bilgi sayfası ---
  String _typeLabel(String t) {
    final tt = t.toLowerCase();
    return tt.startsWith('mek')
        ? 'Mekkî (Hicret’ten önce)'
        : 'Medenî (Hicret’ten sonra)';
  }

  Color _typeColor(String t) {
    return t.toLowerCase().startsWith('mek') ? Colors.indigo : Colors.teal;
  }

  void _showTypeInfo() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Mekkî / Medenî Nedir?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                Text('• Mekkî: Hicret’ten önce nazil olan sûre/âyetler.'),
                Text('• Medenî: Hicret’ten sonra nazil olan sûre/âyetler.'),
                SizedBox(height: 8),
                Text('Not: Tasnif yerden çok zamana göredir.'),
                SizedBox(height: 8),
              ],
            ),
          ),
    );
  }
  // --------------------------------------------------

  Future<void> _fetchSurahs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await http.get(Uri.parse('$kBase/api/surah'));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final data = json.decode(r.body) as List;
      _all =
          data.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
      _applyFilter(resetCount: true);
    } catch (e) {
      setState(() => _error = 'Liste alınamadı: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() => _applyFilter(resetCount: true);

  void _applyFilter({bool resetCount = false}) {
    final q = normalize(_searchCtrl.text.trim());
    _filtered =
        q.isEmpty
            ? List.from(_all)
            : _all
                .where(
                  (s) => normalize(s.name).contains(q) || s.id.toString() == q,
                )
                .toList();

    if (resetCount) {
      _shown = min(_page, _filtered.length);
      if (_itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: 0);
      }
    }
    setState(() {});
  }

  void _loadMore() {
    final startIndex = _shown;
    setState(() {
      _shown = min(_shown + _page, _filtered.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached && startIndex < _shown) {
        _itemScrollController.scrollTo(
          index: startIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = min(_shown, _filtered.length);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sureler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Mekkî / Medenî nedir?',
            onPressed: _showTypeInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Ara (ör. Yasin, Bakara, 36)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                isDense: true,
              ),
            ),
          ),
          // Liste
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : _filtered.isEmpty
                    ? const Center(child: Text('Sonuç bulunamadı'))
                    : ScrollablePositionedList.builder(
                      itemCount: count,
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      itemBuilder: (_, i) {
                        final s = _filtered[i];
                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                child: Text(s.id.toString().padLeft(2, '0')),
                              ),
                              title: Text(s.name),
                              subtitle: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(_typeLabel(s.revelationType)),
                                    labelStyle: TextStyle(
                                      color: _typeColor(s.revelationType),
                                    ),
                                    backgroundColor: _typeColor(
                                      s.revelationType,
                                    ).withOpacity(.12),
                                    side: BorderSide(
                                      color: _typeColor(
                                        s.revelationType,
                                      ).withOpacity(.30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.blueGrey.withOpacity(0.6),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      '${s.ayahCount} ayet',
                                      // '123 ayet',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SurahDetailPage(
                                          surahId: s.id,
                                          surahName: s.name,
                                        ),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      },
                    ),
          ),
          // Devamını getir
          if (!_loading && _filtered.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child:
                    count < _filtered.length
                        ? FilledButton(
                          onPressed: _loadMore,
                          child: Text(
                            'Devamını getir (${_filtered.length - count})',
                          ),
                        )
                        : const Text(
                          'Hepsi gösterildi',
                          style: TextStyle(color: Colors.black54),
                        ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------ DETAY (AYET) EKRANI ------------------
class SurahDetailPage extends StatefulWidget {
  final int surahId;
  final String surahName;
  const SurahDetailPage({
    super.key,
    required this.surahId,
    required this.surahName,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  final _player = AudioPlayer();
  List<Ayah> _ayahs = [];
  bool _loading = true;
  String? _error;
  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    _loadSurah();
    // Çalan indeks değişince highlight edelim
    _player.currentIndexStream.listen((i) {
      setState(() => _currentIndex = i);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _urlOf(String path) => path.startsWith('http') ? path : '$kBase/$path';

  Future<void> _loadSurah() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await http.get(Uri.parse('$kBase/api/surah/${widget.surahId}'));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final data = json.decode(r.body) as Map<String, dynamic>;
      final list = (data['ayahs'] as List).cast<Map<String, dynamic>>();
      _ayahs = list.map((e) => Ayah.fromJson(e)).toList();

      // Playlist kur
      final sources = _ayahs
          .map((a) => AudioSource.uri(Uri.parse(_urlOf(a.filePath))))
          .toList(growable: false);
      await _player.setAudioSource(ConcatenatingAudioSource(children: sources));
    } catch (e) {
      _error = 'Ayetler alınamadı: $e';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _playAll() async {
    if (_ayahs.isEmpty) return;
    await _player.seek(Duration.zero, index: 0);
    await _player.play();
  }

  Future<void> _playAt(int index) async {
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.surahName)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : Column(
                children: [
                  // Header kart
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.library_music,
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.surahName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_ayahs.length} ayet',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: _playAll,
                            child: const Text('Tümünü Çal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Ayet listesi
                  Expanded(
                    child: ListView.separated(
                      itemCount: _ayahs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final a = _ayahs[i];
                        final playing = _currentIndex == i;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: playing ? Colors.green : null,
                            child: Text(
                              a.number.toString().padLeft(3, '0'),
                              style: TextStyle(
                                color: playing ? Colors.white : null,
                              ),
                            ),
                          ),
                          title: Text('Ayet ${a.number}'),
                          subtitle: null, // link gösterme
                          trailing: IconButton(
                            icon: Icon(
                              playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                            ),
                            onPressed: () async {
                              if (playing) {
                                await _player.pause();
                              } else {
                                await _playAt(i);
                              }
                            },
                          ),
                          onTap: () => _playAt(i),
                        );
                      },
                    ),
                  ),
                  // Oynatma kontrolleri
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            onPressed: () => _player.seekToPrevious(),
                            tooltip: 'Önceki',
                          ),
                          StreamBuilder<PlayerState>(
                            stream: _player.playerStateStream,
                            builder: (_, snap) {
                              final s = snap.data;
                              final playing = s?.playing ?? false;
                              if (playing) {
                                return FilledButton(
                                  onPressed: () => _player.pause(),
                                  child: const Icon(Icons.pause),
                                );
                              }
                              return FilledButton(
                                onPressed: () => _player.play(),
                                child: const Icon(Icons.play_arrow),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            onPressed: () => _player.seekToNext(),
                            tooltip: 'Sonraki',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
