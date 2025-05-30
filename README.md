# Smart Team
    muslim pro App

[![version](https://img.shields.io/badge/version-2.0.0-cyan.svg)](https://github.com//thesmarter/muslim-pro/tree/master)
[![Downloads](https://PlayBadges.pavi2410.me/badge/downloads?id=com.detatech.Azkar)](https://play.google.com/store/apps/details?id=com.detatech.Azkar)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# install
- after clone project https://github.com/thesmarter/muslim-pro.git
- open Terminal or Bash or CMD and Run ( flutter pub get . )

```mermaid
graph TD
    A[بداية التطبيق] --> B{هل يحتاج Onboarding؟}
    B -->|نعم - تثبيت جديد/تحديث| C[شاشة Onboarding]
    B -->|لا - مستخدم قديم| D[الشاشة الرئيسية]
    
    C --> C1[صفحة الترحيب]
    C --> C2[ميزات القرآن]
    C --> C3[مشغل الصوت]
    C --> C4[البحث المتقدم]
    C --> C5[التحسينات]
    
    C1 --> E[زر تخطي متاح دائماً]
    C2 --> E
    C3 --> E
    C4 --> E
    C5 --> F[زر البدء]
    
    E --> D
    F --> D
    
    D[MainAppScreen] --> G[شريط التنقل السفلي]
    
    G --> H1[الأذكار]
    G --> H2[القرآن]
    G --> H3[المفضلة]
    G --> H4[الاستماع]
    
    H1 --> I1[قائمة الأذكار]
    H2 --> I2[قسم القرآن]
    H3 --> I3[المحتوى المفضل]
    H4 --> I4[مشغل الصوت]
    
    style A fill:#2E7D32,stroke:#fff,color:#fff
    style D fill:#1565C0,stroke:#fff,color:#fff
    style G fill:#FF6F00,stroke:#fff,color:#fff
    style H1 fill:#4CAF50,stroke:#fff,color:#fff
    style H2 fill:#4CAF50,stroke:#fff,color:#fff
    style H3 fill:#4CAF50,stroke:#fff,color:#fff
    style H4 fill:#4CAF50,stroke:#fff,color:#fff
```