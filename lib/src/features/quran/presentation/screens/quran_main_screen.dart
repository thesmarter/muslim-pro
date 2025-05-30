import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/quran/presentation/components/last_read_card.dart';
import 'package:muslim/src/features/quran/presentation/components/quran_app_bar.dart';
import 'package:muslim/src/features/quran/presentation/components/quran_search_bar.dart';
import 'package:muslim/src/features/quran/presentation/components/quick_access_section.dart';
import 'package:muslim/src/features/quran/presentation/components/surahs_list.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_audio_cubit.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';
import 'package:muslim/src/features/quran/presentation/screens/offline_downloads_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_audio_player_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_bookmarks_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_reader_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_search_screen.dart';

class QuranMainScreen extends StatefulWidget {
  const QuranMainScreen({super.key});

  @override
  State<QuranMainScreen> createState() => _QuranMainScreenState();
}

class _QuranMainScreenState extends State<QuranMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // تحميل البيانات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranReaderCubit>().loadSurahs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            QuranAppBar(
              title: S.of(context).quran,
              onSearchTap: () => _navigateToSearch(context),
              onAudioTap: () => _navigateToAudioPlayer(context),
            ),
          ];
        },
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: QuranSearchBar(
                controller: _searchController,
                onTap: () => _navigateToSearch(context),
              ),
            ),

            // Last Read Card
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: LastReadCard(),
            ),

            // Quick Access Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: QuickAccessSection(),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurfaceVariant,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: S.of(context).surahs),
                  Tab(text: S.of(context).juz),
                  Tab(text: S.of(context).page),
                  Tab(text: S.of(context).bookmarks),
                ],
              ),
            ),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Surahs Tab
                  BlocBuilder<QuranReaderCubit, QuranReaderState>(
                    builder: (context, state) {
                      if (state is QuranReaderLoading) {
                        return const Loading();
                      } else if (state is QuranReaderSurahsLoaded) {
                        return SurahsList(surahs: state.surahs);
                      } else if (state is QuranReaderError) {
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
                                S.of(context).error,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<QuranReaderCubit>().loadSurahs();
                                },
                                child: Text(S.of(context).retry),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),

                  // Juz Tab
                  _buildJuzTab(),

                  // Page Tab
                  _buildPageTab(),

                  // Bookmarks Tab
                  _buildBookmarksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAudioPlayer(context),
        icon: const Icon(Icons.play_arrow),
        label: Text(S.of(context).listen),
      ),
    );
  }

  Widget _buildJuzTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                juzNumber.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('${S.of(context).juz} $juzNumber'),
            subtitle: Text(_getJuzInfo(juzNumber)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.read<QuranReaderCubit>().loadJuz(juzNumber);
            },
          ),
        );
      },
    );
  }

  Widget _buildPageTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 604,
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                pageNumber.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('${S.of(context).page} $pageNumber'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.read<QuranReaderCubit>().loadPage(pageNumber);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookmarksTab() {
    return BlocBuilder<QuranReaderCubit, QuranReaderState>(
      builder: (context, state) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).bookmarks,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).noBookmarksYet,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _navigateToBookmarks(context),
                child: Text(S.of(context).viewBookmarks),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getJuzInfo(int juzNumber) {
    // This would typically come from a data source
    // For now, returning placeholder text
    return 'Contains multiple surahs';
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuranSearchScreen(),
      ),
    );
  }

  void _navigateToAudioPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<QuranReaderCubit>()),
            BlocProvider.value(value: context.read<QuranAudioCubit>()),
          ],
          child: const QuranAudioPlayerScreen(),
        ),
      ),
    );
  }

  void _navigateToBookmarks(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuranBookmarksScreen(),
      ),
    );
  }

  void _navigateToSurahReader(BuildContext context, int surahNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuranReaderScreen(surahNumber: surahNumber),
      ),
    );
  }

  void _navigateToOfflineDownloads(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OfflineDownloadsScreen(),
      ),
    );
  }
}
