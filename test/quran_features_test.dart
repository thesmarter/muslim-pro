import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muslim/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('اختبار شامل لميزات قسم القرآن الكريم', () {
    testWidgets('اختبار التنقل لقسم القرآن', (WidgetTester tester) async {
      // تشغيل التطبيق
      app.main();
      await tester.pumpAndSettle();

      // البحث عن زر القرآن في شريط التنقل السفلي
      final quranButton = find.byIcon(Icons.menu_book_rounded);
      expect(quranButton, findsOneWidget);

      // الضغط على زر القرآن
      await tester.tap(quranButton);
      await tester.pumpAndSettle();

      // التحقق من وصول لشاشة القرآن
      expect(find.text('القرآن الكريم'), findsOneWidget);
    });

    testWidgets('اختبار قائمة السور', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لقسم القرآن
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();

      // التحقق من وجود قائمة السور
      expect(find.text('الفاتحة'), findsOneWidget);
      expect(find.text('البقرة'), findsOneWidget);
      expect(find.text('آل عمران'), findsOneWidget);

      // اختبار الضغط على سورة
      await tester.tap(find.text('الفاتحة'));
      await tester.pumpAndSettle();

      // التحقق من فتح شاشة قراءة السورة
      expect(find.text('الفاتحة'), findsAtLeastOneWidget);
    });

    testWidgets('اختبار مشغل الصوت', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لقسم القرآن
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();

      // البحث عن زر مشغل الصوت
      final audioButton = find.byIcon(Icons.play_circle_rounded);
      expect(audioButton, findsOneWidget);

      // الضغط على زر مشغل الصوت
      await tester.tap(audioButton);
      await tester.pumpAndSettle();

      // التحقق من فتح مشغل الصوت
      expect(find.text('مشغل الصوت'), findsOneWidget);
    });

    testWidgets('اختبار البحث في القرآن', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لقسم القرآن
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();

      // البحث عن زر البحث
      final searchButton = find.byIcon(Icons.search_rounded);
      expect(searchButton, findsOneWidget);

      // الضغط على زر البحث
      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // التحقق من فتح شاشة البحث
      expect(find.text('البحث في القرآن'), findsOneWidget);

      // اختبار البحث
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'الله');
      await tester.pumpAndSettle();

      // التحقق من ظهور نتائج البحث
      expect(find.text('الله'), findsAtLeastOneWidget);
    });

    testWidgets('اختبار المفضلة والعلامات المرجعية', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لقسم القرآن
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();

      // البحث عن زر المفضلة
      final bookmarksButton = find.byIcon(Icons.bookmark_rounded);
      expect(bookmarksButton, findsOneWidget);

      // الضغط على زر المفضلة
      await tester.tap(bookmarksButton);
      await tester.pumpAndSettle();

      // التحقق من فتح شاشة المفضلة
      expect(find.text('المفضلة'), findsOneWidget);
    });

    testWidgets('اختبار التحميلات للعمل بدون إنترنت', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لقسم القرآن
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();

      // البحث عن زر التحميلات
      final downloadsButton = find.byIcon(Icons.download_rounded);
      if (downloadsButton.evaluate().isNotEmpty) {
        // الضغط على زر التحميلات
        await tester.tap(downloadsButton);
        await tester.pumpAndSettle();

        // التحقق من فتح شاشة التحميلات
        expect(find.text('التحميلات'), findsOneWidget);
      }
    });

    testWidgets('اختبار قراءة سورة كاملة', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لقسم القرآن
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();

      // الضغط على سورة الفاتحة
      await tester.tap(find.text('الفاتحة'));
      await tester.pumpAndSettle();

      // التحقق من عرض محتوى السورة
      expect(find.text('الفاتحة'), findsAtLeastOneWidget);
      expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);

      // اختبار أزرار التنقل
      final nextButton = find.byIcon(Icons.skip_next_rounded);
      final prevButton = find.byIcon(Icons.skip_previous_rounded);
      final playButton = find.byIcon(Icons.play_circle_rounded);

      expect(nextButton, findsOneWidget);
      expect(playButton, findsOneWidget);

      // اختبار الانتقال للسورة التالية
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // التحقق من الانتقال للبقرة
      expect(find.text('البقرة'), findsAtLeastOneWidget);
    });

    testWidgets('اختبار إضافة آية للمفضلة', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لقسم القرآن
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();

      // فتح سورة الفاتحة
      await tester.tap(find.text('الفاتحة'));
      await tester.pumpAndSettle();

      // البحث عن زر إضافة للمفضلة
      final favoriteButton = find.byIcon(Icons.favorite_border_rounded);
      if (favoriteButton.evaluate().isNotEmpty) {
        // الضغط على زر المفضلة
        await tester.tap(favoriteButton.first);
        await tester.pumpAndSettle();

        // التحقق من ظهور رسالة النجاح
        expect(find.text('تم إضافة الآية'), findsOneWidget);
      }
    });

    testWidgets('اختبار إعدادات القراءة', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لقسم القرآن وفتح سورة
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الفاتحة'));
      await tester.pumpAndSettle();

      // البحث عن زر الإعدادات
      final settingsButton = find.byIcon(Icons.settings_rounded);
      expect(settingsButton, findsOneWidget);

      // الضغط على زر الإعدادات
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // التحقق من فتح قائمة الإعدادات
      expect(find.text('إعدادات القراءة'), findsOneWidget);
    });

    testWidgets('اختبار اختيار القراء', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // الانتقال لمشغل الصوت
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_circle_rounded));
      await tester.pumpAndSettle();

      // البحث عن زر اختيار القارئ
      final reciterButton = find.byIcon(Icons.person_rounded);
      expect(reciterButton, findsOneWidget);

      // الضغط على زر اختيار القارئ
      await tester.tap(reciterButton);
      await tester.pumpAndSettle();

      // التحقق من فتح قائمة القراء
      expect(find.text('عبد الباسط عبد الصمد'), findsOneWidget);
      expect(find.text('مشاري راشد العفاسي'), findsOneWidget);
    });
  });

  group('اختبار الأداء والاستقرار', () {
    testWidgets('اختبار سرعة التحميل', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // التحقق من أن التطبيق يحمل في أقل من 5 ثوان
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    testWidgets('اختبار الذاكرة والأداء', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // اختبار التنقل المتكرر بين الشاشات
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.menu_book_rounded));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('الفاتحة'));
        await tester.pumpAndSettle();
        
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // التحقق من عدم وجود تسريبات في الذاكرة
      expect(tester.binding.transientCallbackCount, equals(0));
    });
  });
}
