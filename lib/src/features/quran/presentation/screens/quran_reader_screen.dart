import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/quran/data/models/ayah_model.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';
import 'package:muslim/src/features/quran/data/repository/quran_repository.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_audio_cubit.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_audio_player_screen.dart';

class QuranReaderScreen extends StatefulWidget {
  final int surahNumber;
  final int? ayahNumber;
  final String? edition;

  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.ayahNumber,
    this.edition = 'ar.alafasy',
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final PageController _pageController = PageController();
  final QuranRepository _repository = sl<QuranRepository>();
  late int _currentSurahNumber;
  Surah? _currentSurah;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.surahNumber;
    _loadSurah();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSurah() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final surah = await _repository.getSurah(
        _currentSurahNumber,
        edition: widget.edition ?? 'ar.alafasy',
      );

      setState(() {
        _currentSurah = surah;
        _isLoading = false;
      });

      // Save as last read
      await _repository.saveLastRead(
          _currentSurahNumber, widget.ayahNumber ?? 1);

      // Scroll to specific ayah if provided
      if (widget.ayahNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah(widget.ayahNumber!);
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _scrollToAyah(int ayahNumber) {
    // Implementation for scrolling to specific ayah
    // This would require calculating the position based on ayah number
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuranReaderCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentSurah?.name ?? 'القرآن الكريم'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          actions: [
            // Bookmark button
            IconButton(
              onPressed: () => _toggleBookmark(),
              icon: Icon(
                Icons.bookmark_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'إضافة علامة مرجعية',
            ),
            // Settings button
            IconButton(
              onPressed: () => _showReaderSettings(),
              icon: Icon(
                Icons.settings_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'إعدادات القراءة',
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: Loading());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'خطأ في تحميل السورة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSurah,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_currentSurah == null) {
      return const Center(
        child: Text('لم يتم العثور على السورة'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          // Surah header
          _buildSurahHeader(),

          // Ayahs list
          Expanded(
            child: _buildAyahsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahHeader() {
    if (_currentSurah == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            _currentSurah!.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            _currentSurah!.englishName,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentSurah!.numberOfAyahs} آية • ${_currentSurah!.revelationType}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),

          // Bismillah (except for At-Tawbah)
          if (_currentSurah!.number != 9) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAyahsList() {
    if (_currentSurah?.ayahs.isEmpty ?? true) {
      return const Center(
        child: Text('لا توجد آيات متاحة'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _currentSurah!.ayahs.length,
      itemBuilder: (context, index) {
        final ayah = _currentSurah!.ayahs[index];
        return _buildAyahCard(ayah, index);
      },
    );
  }

  Widget _buildAyahCard(Ayah ayah, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAyahOptions(ayah),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Ayah number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Action buttons
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _toggleAyahFavorite(ayah),
                          icon: Icon(
                            Icons.favorite_border_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'إضافة للمفضلة',
                        ),
                        IconButton(
                          onPressed: () => _shareAyah(ayah),
                          icon: Icon(
                            Icons.share_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'مشاركة',
                        ),
                      ],
                    ),

                    // Ayah number badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${ayah.numberInSurah}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Ayah text
                Text(
                  ayah.text,
                  style: TextStyle(
                    fontSize: 20,
                    height: 2.0,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavButton(
                icon: Icons.skip_previous_rounded,
                label: 'السابقة',
                onPressed: _currentSurahNumber > 1 ? _goToPreviousSurah : null,
              ),
              _buildNavButton(
                icon: Icons.play_circle_rounded,
                label: 'تشغيل',
                onPressed: _playAudio,
              ),
              _buildNavButton(
                icon: Icons.skip_next_rounded,
                label: 'التالية',
                onPressed: _currentSurahNumber < 114 ? _goToNextSurah : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1)
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleBookmark() async {
    if (_currentSurah != null) {
      await _repository.saveBookmark(_currentSurahNumber, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ علامة مرجعية في ${_currentSurah!.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إعدادات القراءة',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded),
              title: const Text('حجم الخط'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAyahOptions(Ayah ayah) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('خيارات الآية ${ayah.numberInSurah}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.favorite_rounded),
              title: const Text('إضافة للمفضلة'),
              onTap: () {
                Navigator.pop(context);
                _toggleAyahFavorite(ayah);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_rounded),
              title: const Text('إضافة علامة مرجعية'),
              onTap: () {
                Navigator.pop(context);
                _addBookmarkAtAyah(ayah);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAyahFavorite(Ayah ayah) async {
    try {
      await _repository.saveFavoriteAyah(ayah);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم إضافة الآية ${ayah.numberInSurah} للمفضلة'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('خطأ في إضافة الآية للمفضلة'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _addBookmarkAtAyah(Ayah ayah) async {
    try {
      await _repository.saveBookmark(_currentSurahNumber, ayah.numberInSurah);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم حفظ علامة مرجعية في الآية ${ayah.numberInSurah}'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('خطأ في حفظ العلامة المرجعية'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _shareAyah(Ayah ayah) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم نسخ الآية للمشاركة')));
  }

  void _goToPreviousSurah() {
    if (_currentSurahNumber > 1) {
      setState(() {
        _currentSurahNumber--;
      });
      _loadSurah();
    }
  }

  void _goToNextSurah() {
    if (_currentSurahNumber < 114) {
      setState(() {
        _currentSurahNumber++;
      });
      _loadSurah();
    }
  }

  void _playAudio() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<QuranReaderCubit>()),
            BlocProvider(create: (context) => sl<QuranAudioCubit>()),
          ],
          child: const QuranAudioPlayerScreen(),
        ),
      ),
    );
  }
}
