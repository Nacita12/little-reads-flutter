import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const pastelBg = Color(0xFFFFF8F5);
const pastelPink = Color(0xFFF3C9D8);
const pastelPurple = Color(0xFFE6DDF5);
const pastelText = Color(0xFF514454);
const pastelMuted = Color(0xFF8D7C8E);

void main() {
  runApp(const ArtikelReaderApp());
}

class ArtikelReaderApp extends StatelessWidget {
  const ArtikelReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Little Reads',
      theme: ThemeData(
        scaffoldBackgroundColor: pastelBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: pastelPink,
          surface: pastelBg,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: pastelBg,
          foregroundColor: pastelText,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class Article {
  final String id;
  final String title;
  final String description;
  final String url;
  final String source;
  final String publishedAt;
  final String? imageUrl;

  const Article({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: (json['id'] ?? json['url'] ?? json['title'] ?? '').toString(),
      title: (json['title'] ?? 'Judul tidak tersedia').toString(),
      description: (json['description'] ?? '').toString().trim().isEmpty
          ? 'Deskripsi berita tidak tersedia. Buka situs sumber untuk membaca selengkapnya.'
          : json['description'].toString(),
      url: (json['url'] ?? '').toString(),
      source: (json['host'] ?? json['sitename'] ?? 'Sumber berita').toString(),
      publishedAt: (json['published_at'] ?? '').toString(),
      imageUrl: json['image']?.toString(),
    );
  }
}

Future<List<Article>> fetchArticles(String query) async {
  final encodedQuery = Uri.encodeQueryComponent(
    query.trim().isEmpty ? 'teknologi' : query.trim(),
  );
  final uri = Uri.parse(
    'https://freenewsapi.ai/v1/search?q=$encodedQuery&size=20',
  );

  final response = await http.get(uri).timeout(const Duration(seconds: 25));

  if (response.statusCode != 200) {
    throw Exception('Server mengembalikan kode ${response.statusCode}');
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic> || decoded['results'] is! List) {
    throw Exception('Format data dari API tidak sesuai.');
  }

  final List<dynamic> data = decoded['results'] as List<dynamic>;
  return data
      .whereType<Map<String, dynamic>>()
      .map(Article.fromJson)
      .where((article) => article.title.isNotEmpty && article.url.isNotEmpty)
      .toList();
}

String formatDate(String value) {
  if (value.isEmpty) return 'Tanggal tidak tersedia';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final local = date.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

Future<void> openArticle(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    throw Exception('Tautan berita tidak valid.');
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) throw Exception('Tautan berita tidak dapat dibuka.');
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Article>> futureArticles;
  final TextEditingController searchController = TextEditingController();
  final Set<String> favoriteIds = {};
  int selectedTab = 0;
  String currentQuery = 'teknologi';

  @override
  void initState() {
    super.initState();
    futureArticles = fetchArticles(currentQuery);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void searchArticles([String? value]) {
    final query = (value ?? searchController.text).trim();
    FocusScope.of(context).unfocus();
    setState(() {
      currentQuery = query.isEmpty ? 'teknologi' : query;
      selectedTab = 0;
      futureArticles = fetchArticles(currentQuery);
    });
  }

  void toggleFavorite(Article article) {
    setState(() {
      if (!favoriteIds.add(article.id)) {
        favoriteIds.remove(article.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: pastelPink,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: pastelText,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LITTLE READS',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 2,
                                color: pastelMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Ruang bacamu 🌷',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: pastelText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [pastelPink, pastelPurple],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'A little time for yourself',
                          style: TextStyle(
                            color: pastelText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Temukan berita terbaru untuk menemani harimu.',
                          style: TextStyle(color: pastelText, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Topik: $currentQuery',
                          style: const TextStyle(
                            color: pastelText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: searchArticles,
                    decoration: InputDecoration(
                      hintText: 'Cari berita, misalnya teknologi...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Cari berita',
                        onPressed: searchArticles,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Article>>(
                future: futureArticles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: pastelPink),
                          SizedBox(height: 12),
                          Text(
                            'Lagi mencari berita...',
                            style: TextStyle(color: pastelMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: pastelMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Berita belum bisa dimuat',
                              style: TextStyle(
                                color: pastelText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: pastelMuted),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: () => searchArticles(currentQuery),
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allArticles = snapshot.data ?? [];
                  final visibleArticles = selectedTab == 0
                      ? allArticles
                      : allArticles
                      .where((article) => favoriteIds.contains(article.id))
                      .toList();

                  if (visibleArticles.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          selectedTab == 1
                              ? 'Belum ada berita favorit 🌷\nTekan ikon hati pada berita untuk menyimpannya.'
                              : 'Berita untuk topik ini belum ditemukan 🌷\nCoba kata kunci lain.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: pastelMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                    itemCount: visibleArticles.length,
                    itemBuilder: (context, index) {
                      final article = visibleArticles[index];
                      final isFavorite = favoriteIds.contains(article.id);
                      final colors = [
                        pastelPink,
                        pastelPurple,
                        const Color(0xFFDCECE4),
                        const Color(0xFFF7E8C8),
                      ];

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFF0E7ED)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ArticleDetailPage(
                                  article: article,
                                  isFavorite: isFavorite,
                                  onFavorite: () => toggleFavorite(article),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 66,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.newspaper_rounded,
                                    size: 30,
                                    color: pastelText,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.source.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1,
                                          color: pastelMuted,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        article.title,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: pastelText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        article.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: pastelMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        formatDate(article.publishedAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: pastelMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Favorit',
                                  onPressed: () => toggleFavorite(article),
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFavorite ? Colors.pink : pastelMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: pastelPurple,
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorit',
          ),
        ],
      ),
    );
  }
}

class ArticleDetailPage extends StatefulWidget {
  final Article article;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const ArticleDetailPage({
    super.key,
    required this.article,
    required this.isFavorite,
    required this.onFavorite,
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late bool isFavorite;
  bool isOpening = false;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
  }

  Future<void> handleOpenArticle() async {
    setState(() => isOpening = true);
    try {
      await openArticle(widget.article.url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka berita: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail berita'),
        actions: [
          IconButton(
            tooltip: 'Simpan favorit',
            onPressed: () {
              widget.onFavorite();
              setState(() => isFavorite = !isFavorite);
            },
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: Colors.pink,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [pastelPink, pastelPurple],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 75,
                color: pastelText,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              article.source,
              style: const TextStyle(
                color: pastelMuted,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatDate(article.publishedAt),
              style: const TextStyle(color: pastelMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 27,
                height: 1.3,
                fontWeight: FontWeight.bold,
                color: pastelText,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: pastelPink),
            const SizedBox(height: 15),
            Text(
              article.description,
              style: const TextStyle(
                fontSize: 17,
                height: 1.8,
                color: pastelText,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Untuk membaca berita selengkapnya, kunjungi situs sumber berita.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: pastelMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: pastelPink,
                  foregroundColor: pastelText,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: isOpening ? null : handleOpenArticle,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(
                  isOpening ? 'Membuka berita...' : 'Baca berita lengkap',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: pastelText,
                  side: const BorderSide(color: pastelPink),
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () {
                  widget.onFavorite();
                  setState(() => isFavorite = !isFavorite);
                },
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                label: Text(
                  isFavorite ? 'Hapus dari favorit' : 'Simpan ke favorit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
