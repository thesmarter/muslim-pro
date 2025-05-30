import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';
import 'package:muslim/src/features/quran/data/repository/offline_quran_repository.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';

class OfflineDownloadsScreen extends StatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  State<OfflineDownloadsScreen> createState() => _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends State<OfflineDownloadsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final OfflineQuranRepository _offlineRepository =
      sl<OfflineQuranRepository>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuranReaderCubit>()..loadSurahs(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التحميلات للعمل بدون إنترنت'),
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
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.download_rounded),
                text: 'متاح للتحميل',
              ),
              Tab(
                icon: Icon(Icons.download_done_rounded),
                text: 'محمل',
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _showDownloadAllDialog,
              icon: const Icon(Icons.download_for_offline_rounded),
              tooltip: 'تحميل الكل',
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAvailableTab(),
            _buildDownloadedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab() {
    return BlocBuilder<QuranReaderCubit, QuranReaderState>(
      builder: (context, state) {
        if (state is QuranReaderLoading) {
          return const Loading();
        }

        if (state is QuranReaderError) {
          return _buildErrorWidget(state.message);
        }

        if (state is QuranReaderSurahsLoaded) {
          return FutureBuilder<List<int>>(
            future: _offlineRepository.getDownloadedSurahs(),
            builder: (context, downloadedSnapshot) {
              if (downloadedSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Loading();
              }

              final downloadedSurahs = downloadedSnapshot.data ?? [];
              final availableSurahs = state.surahs
                  .where((surah) => !downloadedSurahs.contains(surah.number))
                  .toList();

              if (availableSurahs.isEmpty) {
                return _buildEmptyWidget(
                  Icons.download_done_rounded,
                  'تم تحميل جميع السور',
                  'جميع سور القرآن الكريم متاحة للعمل بدون إنترنت',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: availableSurahs.length,
                itemBuilder: (context, index) {
                  final surah = availableSurahs[index];
                  return _buildAvailableSurahCard(surah);
                },
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildDownloadedTab() {
    return FutureBuilder<List<int>>(
      future: _offlineRepository.getDownloadedSurahs(),
      builder: (context, downloadedSnapshot) {
        if (downloadedSnapshot.connectionState == ConnectionState.waiting) {
          return const Loading();
        }

        final downloadedSurahNumbers = downloadedSnapshot.data ?? [];

        if (downloadedSurahNumbers.isEmpty) {
          return _buildEmptyWidget(
            Icons.download_rounded,
            'لا توجد سور محملة',
            'قم بتحميل السور للعمل بدون إنترنت',
          );
        }

        return BlocBuilder<QuranReaderCubit, QuranReaderState>(
          builder: (context, state) {
            if (state is QuranReaderSurahsLoaded) {
              final downloadedSurahs = state.surahs
                  .where(
                      (surah) => downloadedSurahNumbers.contains(surah.number))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: downloadedSurahs.length,
                itemBuilder: (context, index) {
                  final surah = downloadedSurahs[index];
                  return _buildDownloadedSurahCard(surah);
                },
              );
            }

            return const Loading();
          },
        );
      },
    );
  }

  Widget _buildAvailableSurahCard(Surah surah) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _downloadSurah(surah),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
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
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Surah Number
                Container(
                  width: 48,
                  height: 48,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${surah.number}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Surah Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        surah.englishName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${surah.numberOfAyahs} آية',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Download Button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _downloadSurah(surah),
                    icon: Icon(
                      Icons.download_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    tooltip: 'تحميل',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadedSurahCard(Surah surah) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to surah reading
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Downloaded Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green, Colors.lightGreen],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download_done_rounded,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 16),

                // Surah Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        surah.englishName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.offline_pin_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'متاح بدون إنترنت',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete Button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _deleteSurah(surah),
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    tooltip: 'حذف',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('خطأ', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _downloadSurah(Surah surah) async {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('تحميل ${surah.name}...')));
  }

  void _deleteSurah(Surah surah) async {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('حذف ${surah.name}...')));
  }

  void _showDownloadAllDialog() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تحميل جميع السور...')));
  }
}
