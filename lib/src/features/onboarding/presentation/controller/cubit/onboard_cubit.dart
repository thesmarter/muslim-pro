import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/functions/open_url.dart';
import 'package:muslim/src/core/shared/widgets/empty.dart';
import 'package:muslim/src/core/utils/volume_button_manager.dart';
import 'package:muslim/src/core/values/constant.dart';
import 'package:muslim/src/features/settings/data/repository/app_settings_repo.dart';

part 'onboard_state.dart';

class OnboardCubit extends Cubit<OnboardState> {
  final AppSettingsRepo appSettingsRepo;
  final VolumeButtonManager volumeButtonManager;
  PageController pageController = PageController();
  OnboardCubit(this.appSettingsRepo, this.volumeButtonManager)
      : super(OnboardLoadingState()) {
    _init();
  }

  void _init() {
    volumeButtonManager.toggleActivation(activate: true);
    volumeButtonManager.listen(
      onVolumeDownPressed: () {
        pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      },
      onVolumeUpPressed: () {
        pageController.previousPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      },
    );

    pageController.addListener(
      () {
        final int index = pageController.page!.round();
        onPageChanged(index);
      },
    );
  }

  ///TODO: Change every release
  List<Empty> get pageData {
    return [
      const Empty(
        title: "🕌 المسلم برو - إصدار جديد",
        isImage: false,
        icon: Icons.auto_awesome,
        description: """
السلام عليكم ورحمة الله وبركاته

مرحباً بك في الإصدار الجديد من تطبيق المسلم برو
تم إضافة ميزات جديدة ومثيرة لتحسين تجربتك الروحانية

اسحب لليسار لاستكشاف الميزات الجديدة
""",
      ),
      const Empty(
        title: "📖 قسم القرآن الكريم الجديد",
        isImage: false,
        icon: Icons.menu_book,
        description: """
🎉 تم إضافة قسم كامل للقرآن الكريم يشمل:

📚 قراءة جميع سور القرآن الكريم
🔍 البحث في آيات القرآن
🎧 الاستماع للتلاوات مع أشهر القراء
📑 تصفح القرآن بالصفحات والأجزاء
⭐ حفظ الآيات المفضلة
🔖 وضع علامات مرجعية للآيات
📍 متابعة آخر موضع قراءة

يمكنك الوصول إليه من القائمة الجانبية
""",
      ),
      const Empty(
        title: "🎵 مشغل الصوتيات المتطور",
        isImage: false,
        icon: Icons.headphones,
        description: """
🎧 مشغل صوتيات متطور للقرآن الكريم:

🎙️ أكثر من 20 قارئ مشهور
⏯️ تحكم كامل في التشغيل والإيقاف
🔄 إعادة التشغيل والتكرار
📱 التحكم من شاشة القفل
🔊 جودة صوت عالية
⏰ مؤقت إيقاف التشغيل
📋 قوائم تشغيل مخصصة

استمتع بتلاوة عذبة في أي وقت
""",
      ),
      const Empty(
        title: "🔍 البحث المتقدم في القرآن",
        isImage: false,
        icon: Icons.search,
        description: """
� محرك بحث قوي ومتطور:

📝 البحث في نص الآيات
🏷️ البحث بأسماء السور
� عرض نتائج البحث مع التمييز
� الانتقال المباشر للآية
💾 حفظ عمليات البحث المفضلة
⚡ بحث سريع ودقيق
🎯 فلترة النتائج حسب السور

اعثر على أي آية في ثوانٍ معدودة
""",
      ),
      const Empty(
        title: "⚙️ تحسينات عامة",
        isImage: false,
        icon: Icons.tune,
        description: """
� تحسينات شاملة على التطبيق:

📱 تحديث جميع المكتبات لأحدث إصدار
🔒 حل المشاكل الأمنية
⚡ تحسين الأداء والسرعة
🎨 تحسين التصميم والواجهة
🔧 إصلاح الأخطاء والمشاكل
🌐 دعم أفضل للغات المختلفة
💾 تحسين استهلاك الذاكرة
🔄 تحديثات تلقائية للمحتوى

تجربة أكثر سلاسة واستقراراً
""",
      ),
      Empty(
        title: "المزيد من تطبيقاتنا",
        isImage: false,
        icon: MdiIcons.web,
        description: """
يمكنك دائما الإطلاع على المزيد من تطبيقاتنا
ومشاركة الرابط مع أصدقائك 
تم إضافة زر جديد للقائمة الجانبية في الواجهة
""",
        buttonText: S.current.moreApps,
        onButtonCLick: () {
          openURL(kOrgWebsite);
        },
      ),
    ];
  }

  Future start() async {
    emit(
      OnboardLoadedState(
        showSkipBtn: false, // إزالة زر التخطي من الأسفل لأنه موجود في الأعلى
        currentPageIndex: 0,
        pages: pageData,
      ),
    );
  }

  Future onPageChanged(int index) async {
    final state = this.state;
    if (state is! OnboardLoadedState) return;
    emit(state.copyWith(currentPageIndex: index));
  }

  Future done() async {
    await appSettingsRepo.changCurrentVersion(value: kAppVersion);
    volumeButtonManager.dispose();
    emit(OnboardDoneState());
  }

  @override
  Future<void> close() {
    pageController.dispose();
    volumeButtonManager.dispose();
    return super.close();
  }
}
