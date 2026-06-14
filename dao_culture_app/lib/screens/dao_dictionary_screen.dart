import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class DaoDictionaryScreen extends StatefulWidget {
  const DaoDictionaryScreen({super.key});

  @override
  State<DaoDictionaryScreen> createState() => _DaoDictionaryScreenState();
}

class _DaoDictionaryScreenState extends State<DaoDictionaryScreen> {
  static const Color _ink = Color(0xFF12356A);
  static const Color _red = Color(0xFF1976D2);
  static const Color _paper = Color(0xFFFFFCF8);
  static const Color _gold = Color(0xFFE9A11D);

  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> _recentWords = [
    "Cảm ơn",
    "Tạm biệt",
    "Gia đình",
    "Con người",
  ];

  Map<String, String>? _result;
  Set<String> _favoriteKeys = {};
  String _lastQuery = "";
  bool _isLoading = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildIntroBanner(),
            const SizedBox(height: 18),
            _buildSearchField(),
            const SizedBox(height: 18),
            _buildResultCard(),
            const SizedBox(height: 24),
            _buildRecentHeader(),
            const SizedBox(height: 12),
            _buildRecentWords(),
            const SizedBox(height: 22),
            _buildTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      height: 128,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5F4FF), Color(0xFFF7FBFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -16,
            child: Image.asset(
              "assets/culture_dictionary_lookup.png",
              width: 170,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.menu_book_rounded,
                size: 96,
                color: _red.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 24,
            right: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Từ điển Dao - Việt",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Tra cứu 150 từ thông dụng\ntrong đời sống hằng ngày",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF667286),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE6AA)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFFE9A11D),
            size: 32,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mẹo nhỏ",
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Bạn có thể tìm kiếm bằng tiếng Việt hoặc tiếng Dao để tra cứu nhanh hơn nhé!",
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 24,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: _ink),
              ),
            ),
            const Expanded(
              child: Text(
                "Tra cứu từ vựng Dao",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 48, height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _search,
      decoration: InputDecoration(
        hintText: "Nhập từ tiếng Việt hoặc Dao...",
        hintStyle: const TextStyle(
          color: Color(0xFF9A9DA3),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFFD43D3D),
          size: 30,
        ),
        suffixIcon: _searchController.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFD9ECFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFD9ECFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _red, width: 1.4),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildResultCard() {
    final result = _result;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey("${result?['vietnamese']}-${result?['dao']}-$_isLoading"),
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF6FF), Color(0xFFF7FCFF)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9ECFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _isLoading
            ? const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator(color: _red)),
              )
            : result == null
            ? _buildEmptyResult()
            : _buildWordResult(result),
      ),
    );
  }

  Widget _buildWordResult(Map<String, String> result) {
    final vietnamese = result['vietnamese'] ?? _lastQuery;
    final dao = result['dao'] ?? "";
    final audioFile = result['audio_file'] ?? "";

    return Stack(
      children: [
        Positioned(
          right: -8,
          bottom: -18,
          child: Icon(
            Icons.people_alt_rounded,
            size: 118,
            color: _red.withValues(alpha: 0.16),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vietnamese,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleFavorite(result),
                  icon: Icon(
                    _isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _gold,
                    size: 34,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow("Từ Dao:", dao),
            const SizedBox(height: 10),
            _buildInfoRow("Nghĩa:", vietnamese),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => _playAudio(audioFile),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Nghe phát âm",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyResult() {
    return const SizedBox(
      height: 150,
      child: Center(
        child: Text(
          "Không tìm thấy từ này.\nBạn thử nhập từ khác nhé.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF777A80),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final icon = label.contains("Dao")
        ? Icons.auto_awesome_rounded
        : label.contains("Nghĩa")
        ? Icons.menu_book_rounded
        : Icons.font_download_rounded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _red, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? "Chưa có dữ liệu" : value,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Từ đã tra gần đây",
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(_recentWords.clear),
          child: const Text(
            "Xóa",
            style: TextStyle(
              color: Color(0xFF777A80),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentWords() {
    if (_recentWords.isEmpty) {
      return const Text(
        "Chưa có từ đã tra.",
        style: TextStyle(
          color: Color(0xFF8A8D93),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _recentWords.map((word) {
        return GestureDetector(
          onTap: () {
            _searchController.text = word;
            _search(word);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9ECFF)),
            ),
            child: Text(
              word,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _search(String rawKeyword) async {
    final keyword = rawKeyword.trim();
    if (keyword.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _lastQuery = keyword;
      _isLoading = true;
    });

    final result = await ApiService.searchWord(keyword);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _result = result;
      _isFavorite = result == null
          ? false
          : _favoriteKeys.contains(_favoriteKey(result));
      if (!_recentWords.contains(keyword)) {
        _recentWords.insert(0, keyword);
      }
      if (_recentWords.length > 8) {
        _recentWords.removeRange(8, _recentWords.length);
      }
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final localKeys = prefs.getStringList(await _favoriteStorageKey()) ?? [];
    final serverFavorites = userId.isEmpty
        ? <Map<String, String>>[]
        : await ApiService.getDictionaryFavorites(userId);
    final keys = serverFavorites.isEmpty
        ? localKeys
        : serverFavorites.map(_favoriteKey).toList();

    if (serverFavorites.isNotEmpty) {
      await prefs.setStringList(await _favoriteStorageKey(), keys);
    }

    if (!mounted) return;
    setState(() {
      _favoriteKeys = keys.toSet();
      final result = _result;
      _isFavorite =
          result != null && _favoriteKeys.contains(_favoriteKey(result));
    });
  }

  Future<void> _toggleFavorite(Map<String, String> result) async {
    final key = _favoriteKey(result);
    final nextFavorites = {..._favoriteKeys};
    final willFavorite = !nextFavorites.contains(key);
    if (willFavorite) {
      nextFavorites.add(key);
    } else {
      nextFavorites.remove(key);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      await _favoriteStorageKey(),
      nextFavorites.toList(),
    );

    final userId = prefs.getString('user_id') ?? '';
    if (userId.isNotEmpty) {
      final saved = await ApiService.toggleDictionaryFavorite(
        userId: userId,
        word: result,
        favorite: willFavorite,
      );

      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chưa lưu được lên database, đã lưu tạm trên máy."),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _favoriteKeys = nextFavorites;
      _isFavorite = nextFavorites.contains(key);
    });
  }

  String _favoriteKey(Map<String, String> result) {
    final vietnamese = (result['vietnamese'] ?? '').trim().toLowerCase();
    final dao = (result['dao'] ?? '').trim().toLowerCase();
    return '$vietnamese|$dao';
  }

  Future<String> _favoriteStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';
    return 'dao_dictionary_favorites_$userId';
  }

  Future<void> _playAudio(String audioFile) async {
    if (audioFile.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Từ này chưa có âm thanh mẫu.")),
      );
      return;
    }

    try {
      final audioUrl = ApiService.vocabularyAudioUrl(audioFile);
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không phát được âm thanh mẫu.")),
      );
    }
  }
}
