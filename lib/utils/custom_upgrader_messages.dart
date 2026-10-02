import 'package:upgrader/upgrader.dart';
import '../providers/settings_provider.dart';

/// Customized, beautifully localized upgrader messages for all 10 supported languages.
class CustomUpgraderMessages extends UpgraderMessages {
  final SettingsProvider settings;

  CustomUpgraderMessages(this.settings);

  String _l10n(Map<String, String> map) {
    return map[settings.language] ?? map['english'] ?? '';
  }

  @override
  String? message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.title:
        return _l10n({
          'english': 'Time to Update!',
          'urdu': 'ایپ اپ ڈیٹ کرنے کا وقت!',
          'sindhi': 'ايپ اپڊيٽ ڪرڻ جو وقت!',
          'arabic': 'حان وقت التحديث!',
          'bengali': 'অ্যাপ আপডেট করার সময় হয়েছে!',
          'indonesian': 'Saatnya Memperbarui!',
          'turkish': 'Güncelleme Zamanı!',
          'french': 'Mise à jour disponible !',
          'hindi': 'ऐप अपडेट करने का समय!',
          'persian': 'زمان به‌روزرسانی است!',
        });
      case UpgraderMessage.body:
        return _l10n({
          'english': 'A new version of Sukkur Salah is available! Version {{currentAppStoreVersion}} is now available – you have {{currentInstalledVersion}}.',
          'urdu': 'سکھر صلاۃ کا نیا ورژن دستیاب ہے! (ورژن {{currentAppStoreVersion}} دستیاب ہے - آپ کے پاس {{currentInstalledVersion}} ہے)۔',
          'sindhi': 'سکر صلاۃ جو نئون ورجن دستياب آهي! (ورجن {{currentAppStoreVersion}} دستياب آهي - توهان وٽ {{currentInstalledVersion}} آهي)۔',
          'arabic': 'يتوفر إصدار جديد من سكر صلاة! (الإصدار {{currentAppStoreVersion}} متوفر – لديك {{currentInstalledVersion}}).',
          'bengali': 'সুক্কুর সালাহ-এর একটি নতুন সংস্করণ উপলব্ধ! (সংস্করণ {{currentAppStoreVersion}} উপলব্ধ – আপনার রয়েছে {{currentInstalledVersion}})।',
          'indonesian': 'Versi baru Sukkur Salah telah tersedia! (Versi {{currentAppStoreVersion}} tersedia – Anda memiliki {{currentInstalledVersion}}).',
          'turkish': 'Sukkur Salah\'ın yeni bir sürümü mevcut! (Sürüm {{currentAppStoreVersion}} mevcut – sizdeki {{currentInstalledVersion}}).',
          'french': 'Une nouvelle version de Sukkur Salah est disponible ! (Version {{currentAppStoreVersion}} disponible – vous avez {{currentInstalledVersion}}).',
          'hindi': 'सुक्कुर सलाह का नया संस्करण उपलब्ध है! (संस्करण {{currentAppStoreVersion}} उपलब्ध है - आपके पास {{currentInstalledVersion}} है)।',
          'persian': 'نسخه جدیدی از سکر صلاة در دسترس است! (نسخه {{currentAppStoreVersion}} در دسترس است – شما {{currentInstalledVersion}} دارید).',
        });
      case UpgraderMessage.prompt:
        return _l10n({
          'english': 'Would you like to update it now?',
          'urdu': 'کیا آپ اسے ابھی اپ ڈیٹ کرنا چاہتے ہیں؟',
          'sindhi': 'ڇا توهان ان کي هاڻي اپڊيٽ ڪرڻ چاهيو ٿا؟',
          'arabic': 'هل ترغب في تحديثه الآن؟',
          'bengali': 'আপনি কি এখন এটি আপডেট করতে চান?',
          'indonesian': 'Apakah Anda ingin memperbaruinya sekarang?',
          'turkish': 'Şimdi güncellemek ister misiniz?',
          'french': 'Voulez-vous le mettre à jour maintenant ?',
          'hindi': 'क्या आप इसे अभी अपडेट करना चाहते हैं?',
          'persian': 'آیا می‌خواهید اکنون آن را به‌روزرسانی کنید؟',
        });
      case UpgraderMessage.releaseNotes:
        return _l10n({
          'english': 'Release Notes',
          'urdu': 'ریلیز نوٹس',
          'sindhi': 'رليز نوٽس',
          'arabic': 'ملاحظات الإصدار',
          'bengali': 'রিলিজ নোটস',
          'indonesian': 'Catatan Rilis',
          'turkish': 'Yayın Notları',
          'french': 'Notes de version',
          'hindi': 'रिलीज़ नोट्स',
          'persian': 'یادداشت‌های انتشار',
        });
      case UpgraderMessage.buttonTitleUpdate:
        return _l10n({
          'english': 'UPDATE NOW',
          'urdu': 'ابھی اپ ڈیٹ کریں',
          'sindhi': 'هاڻي اپڊيٽ ڪريو',
          'arabic': 'التحديث الآن',
          'bengali': 'এখনই আপডেট করুন',
          'indonesian': 'PERBARUI SEKARANG',
          'turkish': 'ŞİMDİ GÜNCELLE',
          'french': 'METTRE À JOUR',
          'hindi': 'अभी अपडेट करें',
          'persian': 'به‌روزرسانی هم‌اکنون',
        });
      case UpgraderMessage.buttonTitleLater:
        return _l10n({
          'english': 'LATER',
          'urdu': 'بعد میں',
          'sindhi': 'پوءِ',
          'arabic': 'لاحقاً',
          'bengali': 'পরে করবো',
          'indonesian': 'NANTI',
          'turkish': 'SONRA',
          'french': 'PLUS TARD',
          'hindi': 'बाद में',
          'persian': 'بعداً',
        });
      default:
        return super.message(messageKey);
    }
  }
}
