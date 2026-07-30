/// Strings the app passes to translate() that the original per-language
/// dictionaries in world_translations.dart never covered. Kept in a separate
/// file so the existing dictionaries stay untouched; both are merged into
/// `worldTranslations` at startup.
///
/// These were machine-translated and should be reviewed by native speakers
/// before release - the meaning is right, but phrasing may want polish.
library;

/// Prayer-name aliases used by the notification scheduler and older data
/// files. Each maps to a key the dictionaries already translate, so the alias
/// always agrees with the canonical entry.
const Map<String, String> prayerNameAliases = {
  'Fajr': 'Fajar',
  'Dhuhr': 'Zuhar',
  'Zuhr': 'Zuhar',
};

const Map<String, Map<String, String>> additionalTranslations = {
  'bengali': {
    'Select Sukkur Jantri (Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri) from the side bar for accurate timings': 'সঠিক সময়ের জন্য সাইড বার থেকে সুক্কুর জান্ত্রি (হযরত ডক্টর হাফিজুল্লাহ সাহেব কাদ্দাসাল্লাহু সিররাহু জান্ত্রি অনুসারে) নির্বাচন করুন',
    'Quran Translation Now Works Offline': 'কুরআনের অনুবাদ এখন অফলাইনে কাজ করে',
    'The complete English and Urdu translation by Hazrat Mufti Taqi Usmani Hafizahullah is now built into the app. All 114 Surahs open instantly without any internet connection.': 'হযরত মুফতি তাকি উসমানি হাফিযাহুল্লাহর সম্পূর্ণ ইংরেজি ও উর্দু অনুবাদ এখন অ্যাপের ভিতরেই রয়েছে। ১১৪টি সূরাই ইন্টারনেট ছাড়া সঙ্গে সঙ্গে খোলে।',
    'Translation Error Fixed': 'অনুবাদের ত্রুটি সংশোধন',
    'Fixed the incorrect "Please check your internet connection" message that appeared even when the connection was working fine.': 'ইন্টারনেট ঠিক থাকা সত্ত্বেও দেখানো ভুল বার্তা "অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন" সংশোধন করা হয়েছে।',
    '16 Lines Tajweed Quran Opens Faster': '১৬ লাইন তাজবিদ কুরআন দ্রুত খোলে',
    'Each Parah is now prepared only once, so it opens almost instantly every time after the first use instead of taking a few seconds.': 'প্রতিটি পারা এখন একবারই প্রস্তুত হয়, তাই প্রথমবারের পর প্রতিবার কয়েক সেকেন্ডের বদলে প্রায় সঙ্গে সঙ্গে খোলে।',
    'Accurate Timings for World Cities': 'বিশ্বের শহরগুলোর সঠিক সময়',
    'When you select any city from World Prayer Timings, the app now shows the six standard prayers - Fajar, Sunrise, Zuhar, Asr, Maghrib and Isha - from accurate astronomical calculation. Sukkur continues to show the complete Jantri with all ten timings.': 'বিশ্ব নামাজের সময় থেকে কোনো শহর নির্বাচন করলে অ্যাপ এখন ছয়টি মূল নামাজ - ফজর, সূর্যোদয়, যোহর, আসর, মাগরিব ও এশা - সঠিক জ্যোতির্বৈজ্ঞানিক হিসাবে দেখায়। সুক্কুরের জন্য দশটি সময়সহ সম্পূর্ণ জান্ত্রি আগের মতোই থাকবে।',
    'Asr Juristic Method Option': 'আসরের ফিকহি পদ্ধতির বিকল্প',
    'Choose Hanafi, Shafi, Maliki or Hanbali for Asr in World Prayer Timings. Your selection is now applied correctly to the calculated Asr time.': 'বিশ্ব নামাজের সময়ে আসরের জন্য হানাফি, শাফিঈ, মালিকি বা হাম্বলি বেছে নিন। আপনার নির্বাচন এখন গণনাকৃত আসরের সময়ে সঠিকভাবে প্রয়োগ হয়।',
    'City Name in Your Own Language': 'আপনার নিজের ভাষায় শহরের নাম',
    'A city selected from World Prayer Timings now appears in your chosen app language, and updates automatically when you change the language.': 'বিশ্ব নামাজের সময় থেকে নির্বাচিত শহর এখন আপনার নির্বাচিত ভাষায় দেখা যায় এবং ভাষা পরিবর্তন করলে স্বয়ংক্রিয়ভাবে বদলে যায়।',
    'Cleaner Header & Monthly Schedule': 'পরিচ্ছন্ন হেডার ও মাসিক সময়সূচী',
    'The top of the Times and Today screens now shows just the city name with a refreshed location pin, and the Monthly Schedule displays the city beside the month.': 'সময় ও আজকের স্ক্রিনের উপরে এখন শুধু শহরের নাম ও নতুন লোকেশন পিন দেখা যায়, আর মাসিক সময়সূচীতে মাসের পাশে শহরের নাম দেখানো হয়।',
    'Last selected': 'সর্বশেষ নির্বাচিত',
    'No city selected. Showing the Sukkur Jantri.': 'কোনো শহর নির্বাচন করা হয়নি। সুক্কুর জান্ত্রি দেখানো হচ্ছে।',
    'Currently showing the Sukkur Jantri.': 'বর্তমানে সুক্কুর জান্ত্রি দেখানো হচ্ছে।',
    'Use {city}': '{city} ব্যবহার করুন',
    'Reminder': 'রিমাইন্ডার',
    '{prayer} time has started': '{prayer} এর সময় শুরু হয়েছে',
    '(Forbidden time for prayer)': '(নামাজের নিষিদ্ধ সময়)',
    '(You can pray now)': '(এখন নামাজ পড়তে পারেন)',
    'Test Notification': 'পরীক্ষামূলক বিজ্ঞপ্তি',
    'If you see and hear this, your notifications are working perfectly!':
        'আপনি যদি এটি দেখতে ও শুনতে পান, তবে আপনার বিজ্ঞপ্তি ঠিকভাবে কাজ করছে!',
    'Select Sukkur timings from the side bar — Sukkur (Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu)':
        'সাইড বার থেকে সুক্কুরের সময় নির্বাচন করুন — সুক্কুর (জান্ত্রি হযরত ডক্টর হাফিজুল্লাহ সাহেব কাদ্দাসাল্লাহু সিররাহু)',
    'All prayers done for today': 'আজকের সব নামাজ সম্পন্ন',
    'Analog': 'অ্যানালগ',
    'Arba (1/4)': 'রুবা (১/৪)',
    'At {prayer} time': '{prayer}-এর সময়',
    'Ayahs': 'আয়াত',
    'Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri':
        'হযরত ডক্টর হাফিজুল্লাহ সাহেব কাদ্দাসাল্লাহু সিররাহু জান্ত্রি অনুসারে',
    'Beginning of the Para': 'পারার শুরু',
    'Clock Style': 'ঘড়ির ধরন',
    'Could Not Get Location': 'অবস্থান পাওয়া যায়নি',
    'Could not load the translation.': 'অনুবাদ লোড করা যায়নি।',
    'Could not load the translation. Please check your internet connection.':
        'অনুবাদ লোড করা যায়নি। অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।',
    'Could not open this Parah.': 'এই পারা খোলা যায়নি।',
    'Could not play audio': 'অডিও চালানো যায়নি',
    'Detecting your location…': 'আপনার অবস্থান শনাক্ত করা হচ্ছে…',
    'Digital': 'ডিজিটাল',
    'Dismiss': 'বাতিল করুন',
    'Display Theme': 'ডিসপ্লে থিম',
    'Error sharing/saving image:': 'ছবি শেয়ার/সংরক্ষণে ত্রুটি:',
    'First quarter': 'প্রথম চতুর্থাংশ',
    'Half': 'অর্ধেক',
    'Heading': 'আপনার দিক',
    'Label (optional)': 'লেবেল (ঐচ্ছিক)',
    'Loading translation...': 'অনুবাদ লোড হচ্ছে...',
    'Location Permission Needed': 'অবস্থানের অনুমতি প্রয়োজন',
    'Location Services Off': 'লোকেশন সার্ভিস বন্ধ',
    'Madani': 'মাদানী',
    'Makki': 'মাক্কী',
    'Mint': 'মিন্ট',
    'Minus': 'বিয়োগ',
    'Minutes': 'মিনিট',
    'Needed to accurately calculate prayer times and find the Qibla direction.':
        'নামাজের সঠিক সময় গণনা এবং কিবলার দিক নির্ণয়ের জন্য প্রয়োজন।',
    'Needed to bypass battery savers so alerts ring exactly on time.':
        'ব্যাটারি সেভার এড়িয়ে ঠিক সময়ে সতর্কতা বাজানোর জন্য প্রয়োজন।',
    'Needed to send you Adhan and prayer time alerts on time.':
        'আজান ও নামাজের সময়ের সতর্কতা সময়মতো পাঠানোর জন্য প্রয়োজন।',
    'Nisf (1/2)': 'নিসফ (১/২)',
    'No Parah found': 'কোনো পারা পাওয়া যায়নি',
    'No Surahs found': 'কোনো সূরা পাওয়া যায়নি',
    'No data available': 'কোনো তথ্য নেই',
    'No favorites yet.\nTap ♡ on any Surah or Parah.':
        'এখনও কোনো পছন্দ নেই।\nযেকোনো সূরা বা পারায় ♡ চাপুন।',
    'No reminders yet': 'এখনও কোনো রিমাইন্ডার নেই',
    'None': 'কোনোটিই নয়',
    'Notification now shows a single icon on the right side for Urdu and Sindhi (RTL), matching the natural reading direction.':
        'উর্দু ও সিন্ধি (ডান-থেকে-বাম) ভাষায় বিজ্ঞপ্তিতে এখন ডান পাশে একটি আইকন দেখায়, যা স্বাভাবিক পড়ার দিকের সাথে মেলে।',
    'Notifications are turned off for this app. Prayer alerts will not appear until you enable them in system settings.':
        'এই অ্যাপের জন্য বিজ্ঞপ্তি বন্ধ আছে। সিস্টেম সেটিংসে চালু না করা পর্যন্ত নামাজের সতর্কতা দেখা যাবে না।',
    'PRAYER TIMINGS CUSTOMIZATION': 'নামাজের সময় কাস্টমাইজেশন',
    'Parahs': 'পারা',
    'Permission Permanently Denied': 'অনুমতি স্থায়ীভাবে অস্বীকৃত',
    'Permission Required': 'অনুমতি প্রয়োজন',
    'Please enable GPS / Location Services on your device.':
        'অনুগ্রহ করে আপনার ডিভাইসে জিপিএস / লোকেশন সার্ভিস চালু করুন।',
    'Please go to app settings and enable location permission.':
        'অনুগ্রহ করে অ্যাপ সেটিংসে গিয়ে অবস্থানের অনুমতি চালু করুন।',
    'Prayers done': 'নামাজ সম্পন্ন',
    'Qibla from North': 'উত্তর থেকে কিবলার দিক',
    'Ramzan Timetable': 'রমজানের সময়সূচী',
    'Required Permissions': 'প্রয়োজনীয় অনুমতি',
    'Round': 'গোলাকার',
    'Save / Share': 'সংরক্ষণ / শেয়ার',
    'Search Page No (1-549)...': 'পৃষ্ঠা নম্বর খুঁজুন (১-৫৪৯)...',
    'Select Quarter': 'চতুর্থাংশ নির্বাচন করুন',
    'Share Sukkur Salah with your friends and family':
        'আপনার বন্ধু ও পরিবারের সাথে সুক্কুর সালাহ শেয়ার করুন',
    'Slasa (3/4)': 'সালাসা (৩/৪)',
    'Something went wrong. Please try again.':
        'কিছু একটা ভুল হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
    'Worldwide Prayer Timings': 'বিশ্বজুড়ে নামাজের সময়',
    // ── What's New, version 1.1.3 ──
    "What's New": 'নতুন কী আছে',
    'Monthly Jantri Now Fully Translated': 'মাসিক জান্ত্রি এখন সম্পূর্ণ অনূদিত',
    'The Monthly Schedule column headings - Date, Intiha e Sehar, Fajar, Zuhar and the rest - now appear in your chosen language instead of English, for both the Sukkur Jantri and world city timings.':
        'মাসিক সময়সূচীর কলামের শিরোনাম - তারিখ, সেহরীর শেষ সময়, ফজর, যোহর এবং বাকিগুলি - এখন ইংরেজির বদলে আপনার নির্বাচিত ভাষায় দেখা যায়, সুক্কুর জান্ত্রি ও বিশ্বের শহর উভয়ের জন্যই।',
    'Sharper Quran Pages': 'কুরআনের পৃষ্ঠা আরও ঝকঝকে',
    "Mushaf pages are now rendered at your screen's own resolution with proper filtering, so the text looks noticeably crisper on high resolution displays.":
        'মুসহাফের পৃষ্ঠাগুলি এখন আপনার স্ক্রিনের নিজস্ব রেজোলিউশনে তৈরি হয়, ফলে উচ্চ রেজোলিউশনের পর্দায় লেখা লক্ষণীয়ভাবে পরিষ্কার দেখায়।',
    'Redesigned Home Screen Widgets': 'হোম স্ক্রিন উইজেটের নতুন রূপ',
    'The home screen widgets have a slimmer, cleaner look, and the circle clock widget now shows AM/PM alongside the time.':
        'হোম স্ক্রিনের উইজেটগুলি এখন আরও পাতলা ও পরিচ্ছন্ন, এবং বৃত্তাকার ঘড়ি উইজেটে সময়ের সঙ্গে AM/PM দেখানো হয়।',
    'Sukkur Always Uses the Jantri': 'সুক্কুর সবসময় জান্ত্রি অনুসরণ করে',
    'Sukkur now always shows the authentic Jantri timings and never falls back to calculated ones. After choosing a city you are also taken straight to the Times screen.':
        'সুক্কুর এখন সবসময় প্রকৃত জান্ত্রির সময় দেখায়, কখনও গণনাকৃত সময়ে ফিরে যায় না। শহর নির্বাচনের পর আপনি সরাসরি সময়ের পর্দায় পৌঁছে যান।',
    'Your Last City Is Remembered': 'আপনার শেষ শহর মনে রাখা হয়',
    'Switching back to World Prayer Timings returns you to the city you were last using, instead of asking you to choose it again.':
        'বিশ্বের নামাজে ফিরে গেলে আপনি সেই শহরটিই পান যেটি সর্বশেষ ব্যবহার করছিলেন, আবার বেছে নেওয়ার প্রয়োজন হয় না।',
    'Clearer Analogue Clock': 'অ্যানালগ ঘড়ি আরও স্পষ্ট',
    'The analogue clock hands are slimmer and easier to read across every clock style.':
        'অ্যানালগ ঘড়ির কাঁটা এখন সরু এবং প্রতিটি ঘড়ির স্টাইলে পড়া সহজ।',
    'Neater Screen Layout': 'পরিচ্ছন্ন পর্দার বিন্যাস',
    'The advisory note at the bottom of the Today and Monthly screens now sits flush against the navigation bar, with no leftover gap.':
        'আজ ও মাসিক পর্দার নিচের নির্দেশনাটি এখন নেভিগেশন বারের সঙ্গে লেগে থাকে, মাঝে কোনো ফাঁক থাকে না।',
    'Sukkur Salah': 'সুক্কুর সালাহ',
    'Sukkur Salah – Namaz timings for Sukkur. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah':
        'সুক্কুর সালাহ – সুক্কুরের নামাজের সময়। এখনই ডাউনলোড করুন:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
    'Sukkur, Sindh, Pakistan': 'সুক্কুর, সিন্ধু, পাকিস্তান',
    'Surahs': 'সূরা',
    'Tap + to add a custom reminder before or after any prayer.':
        'যেকোনো নামাজের আগে বা পরে রিমাইন্ডার যোগ করতে + চাপুন।',
    'Third quarter': 'তৃতীয় চতুর্থাংশ',
    'To get the most out of Sukkur Salah, we need a few permissions.':
        'সুক্কুর সালাহ পুরোপুরি ব্যবহার করতে আমাদের কয়েকটি অনুমতি প্রয়োজন।',
    'To set the phone to Silent mode automatically, this app needs "Do Not Disturb" (Notification Policy Access) permission. Please grant it in the next settings screen.':
        'ফোন স্বয়ংক্রিয়ভাবে সাইলেন্ট করতে এই অ্যাপের "ডু নট ডিস্টার্ব" (বিজ্ঞপ্তি নীতি অ্যাক্সেস) অনুমতি প্রয়োজন। পরবর্তী সেটিংস স্ক্রিনে এটি দিন।',
    'Translation: Hazrat Mufti Taqi Usmani Hafizahullah':
        'অনুবাদ: হযরত মুফতি তাকি উসমানি হাফিজাহুল্লাহ',
    'Use Vibrate Instead': 'পরিবর্তে কম্পন ব্যবহার করুন',
    'Vibration': 'কম্পন',
    'View Details': 'বিস্তারিত দেখুন',
    'Your current location is needed to calculate the accurate Qibla direction.':
        'সঠিক কিবলার দিক নির্ণয়ে আপনার বর্তমান অবস্থান প্রয়োজন।',
    'e.g. Prepare for Fajr': 'যেমন ফজরের জন্য প্রস্তুতি',
    'of': 'এর মধ্যে',
    '{minutes} minutes after {prayer}': '{prayer}-এর {minutes} মিনিট পরে',
    '{minutes} minutes before {prayer}': '{prayer}-এর {minutes} মিনিট আগে',
    'جنتری': 'জান্ত্রি',
    'حضرت ڈاکٹر حفیظ اللہ صاحب': 'হযরত ডক্টর হাফিজুল্লাহ সাহেব',
    'قَدَّسَ اللہ سِرَّہُ': 'কাদ্দাসাল্লাহু সিররাহু',
    '✓  Facing Qibla': '✓  আপনি কিবলামুখী',
  },
  'indonesian': {
    'Select Sukkur Jantri (Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri) from the side bar for accurate timings': 'Untuk waktu yang akurat, pilih Jantri Sukkur (berdasarkan Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu) dari bilah samping',
    'Quran Translation Now Works Offline': 'Terjemahan Al-Quran Kini Berfungsi Offline',
    'The complete English and Urdu translation by Hazrat Mufti Taqi Usmani Hafizahullah is now built into the app. All 114 Surahs open instantly without any internet connection.': 'Terjemahan lengkap bahasa Inggris dan Urdu oleh Hazrat Mufti Taqi Usmani Hafizahullah kini tertanam di dalam aplikasi. Seluruh 114 surah terbuka seketika tanpa koneksi internet.',
    'Translation Error Fixed': 'Kesalahan Terjemahan Diperbaiki',
    'Fixed the incorrect "Please check your internet connection" message that appeared even when the connection was working fine.': 'Memperbaiki pesan keliru "Silakan periksa koneksi internet Anda" yang muncul padahal koneksi berfungsi dengan baik.',
    '16 Lines Tajweed Quran Opens Faster': 'Quran Tajwid 16 Baris Terbuka Lebih Cepat',
    'Each Parah is now prepared only once, so it opens almost instantly every time after the first use instead of taking a few seconds.': 'Setiap juz kini disiapkan sekali saja, sehingga setelah penggunaan pertama ia terbuka hampir seketika alih-alih beberapa detik.',
    'Accurate Timings for World Cities': 'Waktu Akurat untuk Kota Dunia',
    'When you select any city from World Prayer Timings, the app now shows the six standard prayers - Fajar, Sunrise, Zuhar, Asr, Maghrib and Isha - from accurate astronomical calculation. Sukkur continues to show the complete Jantri with all ten timings.': 'Saat Anda memilih kota mana pun dari Waktu Salat Dunia, aplikasi kini menampilkan enam salat standar - Subuh, Terbit, Zuhur, Asar, Magrib, dan Isya - dari perhitungan astronomi yang akurat. Sukkur tetap menampilkan Jantri lengkap dengan sepuluh waktu.',
    'Asr Juristic Method Option': 'Opsi Mazhab untuk Asar',
    'Choose Hanafi, Shafi, Maliki or Hanbali for Asr in World Prayer Timings. Your selection is now applied correctly to the calculated Asr time.': 'Pilih Hanafi, Syafii, Maliki, atau Hambali untuk Asar di Waktu Salat Dunia. Pilihan Anda kini diterapkan dengan benar pada waktu Asar yang dihitung.',
    'City Name in Your Own Language': 'Nama Kota dalam Bahasa Anda',
    'A city selected from World Prayer Timings now appears in your chosen app language, and updates automatically when you change the language.': 'Kota yang dipilih dari Waktu Salat Dunia kini tampil dalam bahasa aplikasi yang Anda pilih dan berubah otomatis saat Anda mengganti bahasa.',
    'Cleaner Header & Monthly Schedule': 'Header dan Jadwal Bulanan Lebih Rapi',
    'The top of the Times and Today screens now shows just the city name with a refreshed location pin, and the Monthly Schedule displays the city beside the month.': 'Bagian atas layar Waktu dan Hari Ini kini hanya menampilkan nama kota dengan pin lokasi baru, dan Jadwal Bulanan menampilkan kota di samping bulan.',
    'Last selected': 'Terakhir dipilih',
    'No city selected. Showing the Sukkur Jantri.': 'Tidak ada kota dipilih. Menampilkan Jantri Sukkur.',
    'Currently showing the Sukkur Jantri.': 'Saat ini menampilkan Jantri Sukkur.',
    'Use {city}': 'Gunakan {city}',
    'Reminder': 'Pengingat',
    '{prayer} time has started': 'Waktu {prayer} telah masuk',
    '(Forbidden time for prayer)': '(Waktu terlarang untuk salat)',
    '(You can pray now)': '(Anda boleh salat sekarang)',
    'Test Notification': 'Notifikasi Uji Coba',
    'If you see and hear this, your notifications are working perfectly!':
        'Jika Anda melihat dan mendengar ini, notifikasi Anda berfungsi dengan sempurna!',
    'Select Sukkur timings from the side bar — Sukkur (Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu)':
        'Pilih jadwal Sukkur dari bilah samping — Sukkur (Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu)',
    'All prayers done for today': 'Semua salat hari ini telah selesai',
    'Analog': 'Analog',
    'Arba (1/4)': "Rubu' (1/4)",
    'At {prayer} time': 'Saat waktu {prayer}',
    'Ayahs': 'Ayat',
    'Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri':
        'Berdasarkan Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu',
    'Beginning of the Para': 'Awal Juz',
    'Clock Style': 'Gaya Jam',
    'Could Not Get Location': 'Tidak Dapat Memperoleh Lokasi',
    'Could not load the translation.': 'Tidak dapat memuat terjemahan.',
    'Could not load the translation. Please check your internet connection.':
        'Tidak dapat memuat terjemahan. Silakan periksa koneksi internet Anda.',
    'Could not open this Parah.': 'Tidak dapat membuka Juz ini.',
    'Could not play audio': 'Tidak dapat memutar audio',
    'Detecting your location…': 'Mendeteksi lokasi Anda…',
    'Digital': 'Digital',
    'Dismiss': 'Tutup',
    'Display Theme': 'Tema Tampilan',
    'Error sharing/saving image:': 'Gagal membagikan/menyimpan gambar:',
    'First quarter': 'Seperempat pertama',
    'Half': 'Setengah',
    'Heading': 'Arah Anda',
    'Label (optional)': 'Label (opsional)',
    'Loading translation...': 'Memuat terjemahan...',
    'Location Permission Needed': 'Izin Lokasi Diperlukan',
    'Location Services Off': 'Layanan Lokasi Mati',
    'Madani': 'Madaniyah',
    'Makki': 'Makkiyah',
    'Mint': 'Mint',
    'Minus': 'Kurang',
    'Minutes': 'Menit',
    'Needed to accurately calculate prayer times and find the Qibla direction.':
        'Diperlukan untuk menghitung waktu salat secara akurat dan menentukan arah kiblat.',
    'Needed to bypass battery savers so alerts ring exactly on time.':
        'Diperlukan untuk melewati penghemat baterai agar notifikasi berbunyi tepat waktu.',
    'Needed to send you Adhan and prayer time alerts on time.':
        'Diperlukan untuk mengirim azan dan pengingat waktu salat tepat waktu.',
    'Nisf (1/2)': 'Nisf (1/2)',
    'No Parah found': 'Juz tidak ditemukan',
    'No Surahs found': 'Surah tidak ditemukan',
    'No data available': 'Tidak ada data',
    'No favorites yet.\nTap ♡ on any Surah or Parah.':
        'Belum ada favorit.\nKetuk ♡ pada Surah atau Juz mana pun.',
    'No reminders yet': 'Belum ada pengingat',
    'None': 'Tidak ada',
    'Notification now shows a single icon on the right side for Urdu and Sindhi (RTL), matching the natural reading direction.':
        'Notifikasi kini menampilkan satu ikon di sisi kanan untuk bahasa Urdu dan Sindhi (RTL), sesuai arah baca alaminya.',
    'Notifications are turned off for this app. Prayer alerts will not appear until you enable them in system settings.':
        'Notifikasi untuk aplikasi ini dimatikan. Pengingat salat tidak akan muncul sampai Anda mengaktifkannya di pengaturan sistem.',
    'PRAYER TIMINGS CUSTOMIZATION': 'PENYESUAIAN WAKTU SALAT',
    'Parahs': 'Juz',
    'Permission Permanently Denied': 'Izin Ditolak Permanen',
    'Permission Required': 'Izin Diperlukan',
    'Please enable GPS / Location Services on your device.':
        'Silakan aktifkan GPS / Layanan Lokasi di perangkat Anda.',
    'Please go to app settings and enable location permission.':
        'Silakan buka pengaturan aplikasi dan aktifkan izin lokasi.',
    'Prayers done': 'Salat selesai',
    'Qibla from North': 'Kiblat dari Utara',
    'Ramzan Timetable': 'Jadwal Ramadan',
    'Required Permissions': 'Izin yang Diperlukan',
    'Round': 'Bulat',
    'Save / Share': 'Simpan / Bagikan',
    'Search Page No (1-549)...': 'Cari No Halaman (1-549)...',
    'Select Quarter': 'Pilih Seperempat',
    'Share Sukkur Salah with your friends and family':
        'Bagikan Sukkur Salah kepada teman dan keluarga Anda',
    'Slasa (3/4)': 'Tsulutsah (3/4)',
    'Something went wrong. Please try again.':
        'Terjadi kesalahan. Silakan coba lagi.',
    'Worldwide Prayer Timings': 'Jadwal Salat Seluruh Dunia',
    // ── What's New, version 1.1.3 ──
    "What's New": 'Apa yang Baru',
    'Monthly Jantri Now Fully Translated': 'Jantri Bulanan Kini Diterjemahkan Sepenuhnya',
    'The Monthly Schedule column headings - Date, Intiha e Sehar, Fajar, Zuhar and the rest - now appear in your chosen language instead of English, for both the Sukkur Jantri and world city timings.':
        'Judul kolom Jadwal Bulanan - Tanggal, Akhir Sahur, Subuh, Zuhur dan lainnya - kini tampil dalam bahasa pilihan Anda, bukan bahasa Inggris, baik untuk Jantri Sukkur maupun kota dunia.',
    'Sharper Quran Pages': 'Halaman Al-Quran Lebih Tajam',
    "Mushaf pages are now rendered at your screen's own resolution with proper filtering, so the text looks noticeably crisper on high resolution displays.":
        'Halaman mushaf kini ditampilkan pada resolusi asli layar Anda dengan penyaringan yang tepat, sehingga teks terlihat jauh lebih jernih pada layar beresolusi tinggi.',
    'Redesigned Home Screen Widgets': 'Widget Layar Utama Didesain Ulang',
    'The home screen widgets have a slimmer, cleaner look, and the circle clock widget now shows AM/PM alongside the time.':
        'Widget layar utama kini tampil lebih ramping dan bersih, dan widget jam lingkaran menampilkan AM/PM di samping waktu.',
    'Sukkur Always Uses the Jantri': 'Sukkur Selalu Memakai Jantri',
    'Sukkur now always shows the authentic Jantri timings and never falls back to calculated ones. After choosing a city you are also taken straight to the Times screen.':
        'Sukkur kini selalu menampilkan waktu Jantri yang asli dan tidak pernah beralih ke waktu hasil perhitungan. Setelah memilih kota, Anda juga langsung dibawa ke layar Waktu.',
    'Your Last City Is Remembered': 'Kota Terakhir Anda Diingat',
    'Switching back to World Prayer Timings returns you to the city you were last using, instead of asking you to choose it again.':
        'Kembali ke Sholat Dunia akan membawa Anda ke kota yang terakhir Anda gunakan, tanpa perlu memilihnya lagi.',
    'Clearer Analogue Clock': 'Jam Analog Lebih Jelas',
    'The analogue clock hands are slimmer and easier to read across every clock style.':
        'Jarum jam analog kini lebih ramping dan mudah dibaca pada semua gaya jam.',
    'Neater Screen Layout': 'Tata Letak Layar Lebih Rapi',
    'The advisory note at the bottom of the Today and Monthly screens now sits flush against the navigation bar, with no leftover gap.':
        'Catatan panduan di bagian bawah layar Hari Ini dan Bulanan kini menempel rapat pada bilah navigasi, tanpa celah tersisa.',
    'Sukkur Salah': 'Sukkur Salah',
    'Sukkur Salah – Namaz timings for Sukkur. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah':
        'Sukkur Salah – Jadwal salat untuk Sukkur. Unduh sekarang:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
    'Sukkur, Sindh, Pakistan': 'Sukkur, Sindh, Pakistan',
    'Surahs': 'Surah',
    'Tap + to add a custom reminder before or after any prayer.':
        'Ketuk + untuk menambahkan pengingat sebelum atau sesudah salat mana pun.',
    'Third quarter': 'Tiga perempat',
    'To get the most out of Sukkur Salah, we need a few permissions.':
        'Untuk memaksimalkan Sukkur Salah, kami memerlukan beberapa izin.',
    'To set the phone to Silent mode automatically, this app needs "Do Not Disturb" (Notification Policy Access) permission. Please grant it in the next settings screen.':
        'Untuk menyenyapkan ponsel secara otomatis, aplikasi ini memerlukan izin "Jangan Ganggu" (Akses Kebijakan Notifikasi). Berikan izin tersebut di layar pengaturan berikutnya.',
    'Translation: Hazrat Mufti Taqi Usmani Hafizahullah':
        'Terjemahan: Hazrat Mufti Taqi Usmani Hafizahullah',
    'Use Vibrate Instead': 'Gunakan Getaran Saja',
    'Vibration': 'Getaran',
    'View Details': 'Lihat Detail',
    'Your current location is needed to calculate the accurate Qibla direction.':
        'Lokasi Anda saat ini diperlukan untuk menghitung arah kiblat yang akurat.',
    'e.g. Prepare for Fajr': 'mis. Bersiap untuk Subuh',
    'of': 'dari',
    '{minutes} minutes after {prayer}': '{minutes} menit setelah {prayer}',
    '{minutes} minutes before {prayer}': '{minutes} menit sebelum {prayer}',
    'جنتری': 'Jantri',
    'حضرت ڈاکٹر حفیظ اللہ صاحب': 'Hazrat Dr Hafeezullah Sahib',
    'قَدَّسَ اللہ سِرَّہُ': 'Qaddasallahu sirrahu',
    '✓  Facing Qibla': '✓  Menghadap Kiblat',
  },
  'turkish': {
    'Select Sukkur Jantri (Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri) from the side bar for accurate timings': 'Doğru vakitler için yan menüden Sukkur Jantri\'yi (Hazret Dr Hafeezullah Sahib Kaddesallahu Sirrahu Jantri esas alınmıştır) seçin',
    'Quran Translation Now Works Offline': 'Kuran Meali Artık Çevrimdışı Çalışıyor',
    'The complete English and Urdu translation by Hazrat Mufti Taqi Usmani Hafizahullah is now built into the app. All 114 Surahs open instantly without any internet connection.': 'Hazret Müftü Taki Osmani Hafizahullah tarafından hazırlanan tam İngilizce ve Urduca meal artık uygulamanın içinde yer alıyor. 114 surenin tamamı internet bağlantısı olmadan anında açılır.',
    'Translation Error Fixed': 'Meal Hatası Düzeltildi',
    'Fixed the incorrect "Please check your internet connection" message that appeared even when the connection was working fine.': 'Bağlantı sorunsuz çalışırken bile görünen hatalı "Lütfen internet bağlantınızı kontrol edin" mesajı düzeltildi.',
    '16 Lines Tajweed Quran Opens Faster': '16 Satır Tecvidli Kuran Daha Hızlı Açılıyor',
    'Each Parah is now prepared only once, so it opens almost instantly every time after the first use instead of taking a few seconds.': 'Her cüz artık yalnızca bir kez hazırlanıyor; böylece ilk kullanımdan sonra birkaç saniye yerine neredeyse anında açılıyor.',
    'Accurate Timings for World Cities': 'Dünya Şehirleri için Doğru Vakitler',
    'When you select any city from World Prayer Timings, the app now shows the six standard prayers - Fajar, Sunrise, Zuhar, Asr, Maghrib and Isha - from accurate astronomical calculation. Sukkur continues to show the complete Jantri with all ten timings.': 'Dünya Namaz Vakitleri bölümünden bir şehir seçtiğinizde uygulama artık altı temel vakti - Sabah, Güneş, Öğle, İkindi, Akşam ve Yatsı - doğru astronomik hesapla gösterir. Sukkur için on vaktin tamamını içeren Jantri aynen korunur.',
    'Asr Juristic Method Option': 'İkindi için Mezhep Seçeneği',
    'Choose Hanafi, Shafi, Maliki or Hanbali for Asr in World Prayer Timings. Your selection is now applied correctly to the calculated Asr time.': 'Dünya Namaz Vakitleri bölümünde ikindi için Hanefi, Şafii, Maliki veya Hanbeli seçin. Seçiminiz artık hesaplanan ikindi vaktine doğru şekilde uygulanır.',
    'City Name in Your Own Language': 'Şehir Adı Kendi Dilinizde',
    'A city selected from World Prayer Timings now appears in your chosen app language, and updates automatically when you change the language.': 'Dünya Namaz Vakitleri bölümünden seçilen şehir artık seçtiğiniz uygulama dilinde görünür ve dili değiştirdiğinizde otomatik olarak güncellenir.',
    'Cleaner Header & Monthly Schedule': 'Daha Sade Başlık ve Aylık Takvim',
    'The top of the Times and Today screens now shows just the city name with a refreshed location pin, and the Monthly Schedule displays the city beside the month.': 'Vakitler ve Bugün ekranlarının üst kısmında artık yalnızca şehir adı ve yenilenen konum işareti görünür; Aylık Takvim ise ayın yanında şehri gösterir.',
    'Last selected': 'Son seçilen',
    'No city selected. Showing the Sukkur Jantri.': 'Şehir seçilmedi. Sukkur Jantri gösteriliyor.',
    'Currently showing the Sukkur Jantri.': 'Şu anda Sukkur Jantri gösteriliyor.',
    'Use {city}': '{city} şehrini kullan',
    'Reminder': 'Hatırlatıcı',
    '{prayer} time has started': '{prayer} vakti girdi',
    '(Forbidden time for prayer)': '(Namaz kılmanın yasak olduğu vakit)',
    '(You can pray now)': '(Artık namaz kılabilirsiniz)',
    'Test Notification': 'Test Bildirimi',
    'If you see and hear this, your notifications are working perfectly!':
        'Bunu görüyor ve duyuyorsanız, bildirimleriniz sorunsuz çalışıyor demektir!',
    'Select Sukkur timings from the side bar — Sukkur (Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu)':
        'Sukkur vakitlerini yan menüden seçin — Sukkur (Jantri Hazret Dr Hafizullah Sahib Kaddesallahu sırrahu)',
    'All prayers done for today': 'Bugünün tüm namazları kılındı',
    'Analog': 'Analog',
    'Arba (1/4)': 'Rubu (1/4)',
    'At {prayer} time': '{prayer} vaktinde',
    'Ayahs': 'Ayetler',
    'Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri':
        'Hazret Dr Hafizullah Sahib Kaddesallahu sırrahu Jantri’ye göre',
    'Beginning of the Para': 'Cüzün başlangıcı',
    'Clock Style': 'Saat Stili',
    'Could Not Get Location': 'Konum Alınamadı',
    'Could not load the translation.': 'Çeviri yüklenemedi.',
    'Could not load the translation. Please check your internet connection.':
        'Çeviri yüklenemedi. Lütfen internet bağlantınızı kontrol edin.',
    'Could not open this Parah.': 'Bu cüz açılamadı.',
    'Could not play audio': 'Ses çalınamadı',
    'Detecting your location…': 'Konumunuz belirleniyor…',
    'Digital': 'Dijital',
    'Dismiss': 'Kapat',
    'Display Theme': 'Görünüm Teması',
    'Error sharing/saving image:': 'Görsel paylaşılırken/kaydedilirken hata:',
    'First quarter': 'İlk çeyrek',
    'Half': 'Yarım',
    'Heading': 'Yönünüz',
    'Label (optional)': 'Etiket (isteğe bağlı)',
    'Loading translation...': 'Çeviri yükleniyor...',
    'Location Permission Needed': 'Konum İzni Gerekli',
    'Location Services Off': 'Konum Servisleri Kapalı',
    'Madani': 'Medenî',
    'Makki': 'Mekkî',
    'Mint': 'Nane',
    'Minus': 'Eksi',
    'Minutes': 'Dakika',
    'Needed to accurately calculate prayer times and find the Qibla direction.':
        'Namaz vakitlerini doğru hesaplamak ve kıble yönünü bulmak için gereklidir.',
    'Needed to bypass battery savers so alerts ring exactly on time.':
        'Uyarıların tam zamanında çalması için pil tasarrufunu aşmak amacıyla gereklidir.',
    'Needed to send you Adhan and prayer time alerts on time.':
        'Ezan ve namaz vakti uyarılarını zamanında göndermek için gereklidir.',
    'Nisf (1/2)': 'Nısıf (1/2)',
    'No Parah found': 'Cüz bulunamadı',
    'No Surahs found': 'Sure bulunamadı',
    'No data available': 'Veri yok',
    'No favorites yet.\nTap ♡ on any Surah or Parah.':
        'Henüz favori yok.\nHerhangi bir sure veya cüzde ♡ simgesine dokunun.',
    'No reminders yet': 'Henüz hatırlatıcı yok',
    'None': 'Hiçbiri',
    'Notification now shows a single icon on the right side for Urdu and Sindhi (RTL), matching the natural reading direction.':
        'Bildirim artık Urduca ve Sindhi (sağdan sola) için doğal okuma yönüne uygun olarak sağ tarafta tek bir simge gösteriyor.',
    'Notifications are turned off for this app. Prayer alerts will not appear until you enable them in system settings.':
        'Bu uygulama için bildirimler kapalı. Sistem ayarlarından açmadıkça namaz uyarıları görünmeyecek.',
    'PRAYER TIMINGS CUSTOMIZATION': 'NAMAZ VAKİTLERİ ÖZELLEŞTİRMESİ',
    'Parahs': 'Cüzler',
    'Permission Permanently Denied': 'İzin Kalıcı Olarak Reddedildi',
    'Permission Required': 'İzin Gerekli',
    'Please enable GPS / Location Services on your device.':
        'Lütfen cihazınızda GPS / Konum Servislerini etkinleştirin.',
    'Please go to app settings and enable location permission.':
        'Lütfen uygulama ayarlarına gidip konum iznini etkinleştirin.',
    'Prayers done': 'Kılınan namazlar',
    'Qibla from North': 'Kuzeyden kıble',
    'Ramzan Timetable': 'Ramazan İmsakiyesi',
    'Required Permissions': 'Gerekli İzinler',
    'Round': 'Yuvarlak',
    'Save / Share': 'Kaydet / Paylaş',
    'Search Page No (1-549)...': 'Sayfa No Ara (1-549)...',
    'Select Quarter': 'Çeyrek Seçin',
    'Share Sukkur Salah with your friends and family':
        'Sukkur Salah’ı arkadaşlarınız ve ailenizle paylaşın',
    'Slasa (3/4)': 'Selase (3/4)',
    'Something went wrong. Please try again.':
        'Bir şeyler ters gitti. Lütfen tekrar deneyin.',
    'Worldwide Prayer Timings': 'Dünya Geneli Namaz Vakitleri',
    // ── What's New, version 1.1.3 ──
    "What's New": 'Yenilikler',
    'Monthly Jantri Now Fully Translated': 'Aylık Jantri Artık Tamamen Çevrildi',
    'The Monthly Schedule column headings - Date, Intiha e Sehar, Fajar, Zuhar and the rest - now appear in your chosen language instead of English, for both the Sukkur Jantri and world city timings.':
        'Aylık Takvim sütun başlıkları - Tarih, Sahur Sonu, Sabah, Öğle ve diğerleri - artık İngilizce yerine seçtiğiniz dilde görünüyor; hem Sukkur Jantri hem de dünya şehirleri için.',
    'Sharper Quran Pages': "Daha Net Kur'an Sayfaları",
    "Mushaf pages are now rendered at your screen's own resolution with proper filtering, so the text looks noticeably crisper on high resolution displays.":
        'Mushaf sayfaları artık ekranınızın kendi çözünürlüğünde işleniyor, böylece yüksek çözünürlüklü ekranlarda metin belirgin şekilde daha net görünüyor.',
    'Redesigned Home Screen Widgets': 'Yeniden Tasarlanan Ana Ekran Araçları',
    'The home screen widgets have a slimmer, cleaner look, and the circle clock widget now shows AM/PM alongside the time.':
        'Ana ekran araçları daha ince ve sade bir görünüme kavuştu, dairesel saat aracı artık saatin yanında ÖÖ/ÖS gösteriyor.',
    'Sukkur Always Uses the Jantri': 'Sukkur Her Zaman Jantri Kullanır',
    'Sukkur now always shows the authentic Jantri timings and never falls back to calculated ones. After choosing a city you are also taken straight to the Times screen.':
        'Sukkur artık her zaman özgün Jantri vakitlerini gösteriyor ve asla hesaplanmış vakitlere geçmiyor. Bir şehir seçtikten sonra doğrudan Vakitler ekranına yönlendirilirsiniz.',
    'Your Last City Is Remembered': 'Son Şehriniz Hatırlanır',
    'Switching back to World Prayer Timings returns you to the city you were last using, instead of asking you to choose it again.':
        "Dünya Namaz Vakitleri'ne döndüğünüzde en son kullandığınız şehir karşınıza gelir, yeniden seçmeniz gerekmez.",
    'Clearer Analogue Clock': 'Daha Net Analog Saat',
    'The analogue clock hands are slimmer and easier to read across every clock style.':
        'Analog saat akrep ve yelkovanları daha ince ve tüm saat stillerinde daha okunaklı.',
    'Neater Screen Layout': 'Daha Düzenli Ekran Yerleşimi',
    'The advisory note at the bottom of the Today and Monthly screens now sits flush against the navigation bar, with no leftover gap.':
        'Bugün ve Aylık ekranlarının altındaki uyarı notu artık gezinme çubuğuna bitişik duruyor, arada boşluk kalmıyor.',
    'Sukkur Salah': 'Sukkur Salah',
    'Sukkur Salah – Namaz timings for Sukkur. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah':
        'Sukkur Salah – Sukkur için namaz vakitleri. Hemen indirin:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
    'Sukkur, Sindh, Pakistan': 'Sukkur, Sindh, Pakistan',
    'Surahs': 'Sureler',
    'Tap + to add a custom reminder before or after any prayer.':
        'Herhangi bir namazdan önce veya sonra hatırlatıcı eklemek için + simgesine dokunun.',
    'Third quarter': 'Üçüncü çeyrek',
    'To get the most out of Sukkur Salah, we need a few permissions.':
        'Sukkur Salah’tan en iyi şekilde yararlanmak için birkaç izne ihtiyacımız var.',
    'To set the phone to Silent mode automatically, this app needs "Do Not Disturb" (Notification Policy Access) permission. Please grant it in the next settings screen.':
        'Telefonu otomatik olarak sessize almak için bu uygulamanın "Rahatsız Etmeyin" (Bildirim İlkesi Erişimi) iznine ihtiyacı var. Lütfen bir sonraki ayarlar ekranında bu izni verin.',
    'Translation: Hazrat Mufti Taqi Usmani Hafizahullah':
        'Çeviri: Hazret Müftü Taki Osmani Hafizahullah',
    'Use Vibrate Instead': 'Bunun Yerine Titreşimi Kullan',
    'Vibration': 'Titreşim',
    'View Details': 'Ayrıntıları Görüntüle',
    'Your current location is needed to calculate the accurate Qibla direction.':
        'Doğru kıble yönünü hesaplamak için mevcut konumunuz gereklidir.',
    'e.g. Prepare for Fajr': 'ör. Sabah namazına hazırlan',
    'of': '/',
    '{minutes} minutes after {prayer}': '{prayer} vaktinden {minutes} dakika sonra',
    '{minutes} minutes before {prayer}': '{prayer} vaktinden {minutes} dakika önce',
    'جنتری': 'Jantri',
    'حضرت ڈاکٹر حفیظ اللہ صاحب': 'Hazret Dr Hafizullah Sahib',
    'قَدَّسَ اللہ سِرَّہُ': 'Kaddesallahu sırrahu',
    '✓  Facing Qibla': '✓  Kıbleye dönüksünüz',
  },
  'french': {
    'Select Sukkur Jantri (Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri) from the side bar for accurate timings': 'Pour des horaires précis, sélectionnez le Jantri de Sukkur (basé sur le Jantri de Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu) dans le menu latéral',
    'Quran Translation Now Works Offline': 'La traduction du Coran fonctionne désormais hors ligne',
    'The complete English and Urdu translation by Hazrat Mufti Taqi Usmani Hafizahullah is now built into the app. All 114 Surahs open instantly without any internet connection.': 'La traduction complète en anglais et en ourdou de Hazrat Mufti Taqi Usmani Hafizahullah est désormais intégrée à l\'application. Les 114 sourates s\'ouvrent instantanément sans connexion Internet.',
    'Translation Error Fixed': 'Erreur de traduction corrigée',
    'Fixed the incorrect "Please check your internet connection" message that appeared even when the connection was working fine.': 'Correction du message erroné "Veuillez vérifier votre connexion Internet" qui apparaissait alors que la connexion fonctionnait correctement.',
    '16 Lines Tajweed Quran Opens Faster': 'Le Coran Tajwid 16 lignes s\'ouvre plus vite',
    'Each Parah is now prepared only once, so it opens almost instantly every time after the first use instead of taking a few seconds.': 'Chaque juz n\'est désormais préparé qu\'une seule fois : après la première utilisation, il s\'ouvre presque instantanément au lieu de quelques secondes.',
    'Accurate Timings for World Cities': 'Horaires précis pour les villes du monde',
    'When you select any city from World Prayer Timings, the app now shows the six standard prayers - Fajar, Sunrise, Zuhar, Asr, Maghrib and Isha - from accurate astronomical calculation. Sukkur continues to show the complete Jantri with all ten timings.': 'Lorsque vous sélectionnez une ville dans les Horaires de prière mondiaux, l\'application affiche désormais les six prières standard - Fajr, lever du soleil, Zuhr, Asr, Maghrib et Icha - à partir d\'un calcul astronomique précis. Sukkur conserve le Jantri complet avec ses dix horaires.',
    'Asr Juristic Method Option': 'Option de méthode juridique pour l\'Asr',
    'Choose Hanafi, Shafi, Maliki or Hanbali for Asr in World Prayer Timings. Your selection is now applied correctly to the calculated Asr time.': 'Choisissez hanafite, chaféite, malikite ou hanbalite pour l\'Asr dans les Horaires de prière mondiaux. Votre choix est désormais correctement appliqué à l\'heure calculée de l\'Asr.',
    'City Name in Your Own Language': 'Nom de la ville dans votre langue',
    'A city selected from World Prayer Timings now appears in your chosen app language, and updates automatically when you change the language.': 'Une ville sélectionnée dans les Horaires de prière mondiaux s\'affiche désormais dans la langue choisie et se met à jour automatiquement lorsque vous changez de langue.',
    'Cleaner Header & Monthly Schedule': 'En-tête et calendrier mensuel épurés',
    'The top of the Times and Today screens now shows just the city name with a refreshed location pin, and the Monthly Schedule displays the city beside the month.': 'Le haut des écrans Horaires et Aujourd\'hui n\'affiche plus que le nom de la ville avec un nouveau repère de localisation, et le calendrier mensuel affiche la ville à côté du mois.',
    'Last selected': 'Dernier lieu sélectionné',
    'No city selected. Showing the Sukkur Jantri.': 'Aucune ville sélectionnée. Affichage du Jantri de Sukkur.',
    'Currently showing the Sukkur Jantri.': 'Affichage actuel du Jantri de Sukkur.',
    'Use {city}': 'Utiliser {city}',
    'Reminder': 'Rappel',
    '{prayer} time has started': "L'heure de {prayer} a commencé",
    '(Forbidden time for prayer)': '(Heure interdite pour la prière)',
    '(You can pray now)': '(Vous pouvez prier maintenant)',
    'Test Notification': 'Notification de test',
    'If you see and hear this, your notifications are working perfectly!':
        'Si vous voyez et entendez ceci, vos notifications fonctionnent parfaitement !',
    'Select Sukkur timings from the side bar — Sukkur (Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu)':
        'Sélectionnez les horaires de Sukkur dans le menu latéral — Sukkur (Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu)',
    'All prayers done for today': 'Toutes les prières du jour sont accomplies',
    'Analog': 'Analogique',
    'Arba (1/4)': "Roub' (1/4)",
    'At {prayer} time': "À l'heure de {prayer}",
    'Ayahs': 'Versets',
    'Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri':
        "D'après le Jantri de Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu",
    'Beginning of the Para': 'Début du Juz',
    'Clock Style': "Style d'horloge",
    'Could Not Get Location': "Impossible d'obtenir la position",
    'Could not load the translation.': 'Impossible de charger la traduction.',
    'Could not load the translation. Please check your internet connection.':
        'Impossible de charger la traduction. Veuillez vérifier votre connexion Internet.',
    'Could not open this Parah.': "Impossible d'ouvrir ce Juz.",
    'Could not play audio': "Impossible de lire l'audio",
    'Detecting your location…': 'Détection de votre position…',
    'Digital': 'Numérique',
    'Dismiss': 'Ignorer',
    'Display Theme': "Thème d'affichage",
    'Error sharing/saving image:':
        "Erreur lors du partage/de l'enregistrement de l'image :",
    'First quarter': 'Premier quart',
    'Half': 'Moitié',
    'Heading': 'Votre cap',
    'Label (optional)': 'Libellé (facultatif)',
    'Loading translation...': 'Chargement de la traduction...',
    'Location Permission Needed': 'Autorisation de localisation requise',
    'Location Services Off': 'Services de localisation désactivés',
    'Madani': 'Médinoise',
    'Makki': 'Mecquoise',
    'Mint': 'Menthe',
    'Minus': 'Moins',
    'Minutes': 'Minutes',
    'Needed to accurately calculate prayer times and find the Qibla direction.':
        'Nécessaire pour calculer précisément les heures de prière et trouver la direction de la Qibla.',
    'Needed to bypass battery savers so alerts ring exactly on time.':
        "Nécessaire pour contourner les économiseurs de batterie afin que les alertes sonnent à l'heure exacte.",
    'Needed to send you Adhan and prayer time alerts on time.':
        "Nécessaire pour vous envoyer l'Adhan et les alertes de prière à l'heure.",
    'Nisf (1/2)': 'Nisf (1/2)',
    'No Parah found': 'Aucun Juz trouvé',
    'No Surahs found': 'Aucune sourate trouvée',
    'No data available': 'Aucune donnée disponible',
    'No favorites yet.\nTap ♡ on any Surah or Parah.':
        'Aucun favori pour le moment.\nAppuyez sur ♡ sur une sourate ou un Juz.',
    'No reminders yet': 'Aucun rappel pour le moment',
    'None': 'Aucun',
    'Notification now shows a single icon on the right side for Urdu and Sindhi (RTL), matching the natural reading direction.':
        "La notification affiche désormais une seule icône à droite pour l'ourdou et le sindhi (RTL), conformément au sens de lecture naturel.",
    'Notifications are turned off for this app. Prayer alerts will not appear until you enable them in system settings.':
        "Les notifications sont désactivées pour cette application. Les alertes de prière n'apparaîtront pas tant que vous ne les aurez pas activées dans les paramètres système.",
    'PRAYER TIMINGS CUSTOMIZATION': 'PERSONNALISATION DES HEURES DE PRIÈRE',
    'Parahs': 'Juz',
    'Permission Permanently Denied': 'Autorisation refusée définitivement',
    'Permission Required': 'Autorisation requise',
    'Please enable GPS / Location Services on your device.':
        'Veuillez activer le GPS / les services de localisation sur votre appareil.',
    'Please go to app settings and enable location permission.':
        "Veuillez ouvrir les paramètres de l'application et activer l'autorisation de localisation.",
    'Prayers done': 'Prières accomplies',
    'Qibla from North': 'Qibla depuis le nord',
    'Ramzan Timetable': 'Horaires du Ramadan',
    'Required Permissions': 'Autorisations requises',
    'Round': 'Rond',
    'Save / Share': 'Enregistrer / Partager',
    'Search Page No (1-549)...': 'Rechercher le n° de page (1-549)...',
    'Select Quarter': 'Sélectionner le quart',
    'Share Sukkur Salah with your friends and family':
        'Partagez Sukkur Salah avec vos amis et votre famille',
    'Slasa (3/4)': 'Thoulth (3/4)',
    'Something went wrong. Please try again.':
        "Une erreur s'est produite. Veuillez réessayer.",
    'Worldwide Prayer Timings': 'Horaires de prière du monde entier',
    // ── What's New, version 1.1.3 ──
    "What's New": 'Nouveautés',
    'Monthly Jantri Now Fully Translated': 'Jantri mensuel entièrement traduit',
    'The Monthly Schedule column headings - Date, Intiha e Sehar, Fajar, Zuhar and the rest - now appear in your chosen language instead of English, for both the Sukkur Jantri and world city timings.':
        "Les en-têtes de colonnes du calendrier mensuel - Date, Fin du Sahour, Fajr, Dhuhr et les autres - apparaissent désormais dans la langue que vous avez choisie plutôt qu'en anglais, aussi bien pour le Jantri de Sukkur que pour les villes du monde.",
    'Sharper Quran Pages': 'Pages du Coran plus nettes',
    "Mushaf pages are now rendered at your screen's own resolution with proper filtering, so the text looks noticeably crisper on high resolution displays.":
        'Les pages du mushaf sont désormais rendues à la résolution native de votre écran, si bien que le texte paraît nettement plus net sur les écrans haute résolution.',
    'Redesigned Home Screen Widgets': "Widgets d'écran d'accueil repensés",
    'The home screen widgets have a slimmer, cleaner look, and the circle clock widget now shows AM/PM alongside the time.':
        "Les widgets de l'écran d'accueil ont un aspect plus fin et plus épuré, et le widget horloge circulaire affiche désormais AM/PM à côté de l'heure.",
    'Sukkur Always Uses the Jantri': 'Sukkur utilise toujours le Jantri',
    'Sukkur now always shows the authentic Jantri timings and never falls back to calculated ones. After choosing a city you are also taken straight to the Times screen.':
        "Sukkur affiche désormais toujours les horaires authentiques du Jantri et ne bascule jamais vers les horaires calculés. Après avoir choisi une ville, vous arrivez directement sur l'écran des horaires.",
    'Your Last City Is Remembered': 'Votre dernière ville est mémorisée',
    'Switching back to World Prayer Timings returns you to the city you were last using, instead of asking you to choose it again.':
        'Revenir aux Prières Mondiales vous ramène à la ville que vous utilisiez en dernier, sans avoir à la sélectionner de nouveau.',
    'Clearer Analogue Clock': 'Horloge analogique plus lisible',
    'The analogue clock hands are slimmer and easier to read across every clock style.':
        "Les aiguilles de l'horloge analogique sont plus fines et plus lisibles dans tous les styles d'horloge.",
    'Neater Screen Layout': 'Mise en page plus soignée',
    'The advisory note at the bottom of the Today and Monthly screens now sits flush against the navigation bar, with no leftover gap.':
        "La note d'information en bas des écrans Aujourd'hui et Mensuel est désormais collée à la barre de navigation, sans espace résiduel.",
    'Sukkur Salah': 'Sukkur Salah',
    'Sukkur Salah – Namaz timings for Sukkur. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah':
        'Sukkur Salah – Horaires de prière pour Sukkur. Téléchargez maintenant :\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
    'Sukkur, Sindh, Pakistan': 'Sukkur, Sindh, Pakistan',
    'Surahs': 'Sourates',
    'Tap + to add a custom reminder before or after any prayer.':
        'Appuyez sur + pour ajouter un rappel avant ou après une prière.',
    'Third quarter': 'Troisième quart',
    'To get the most out of Sukkur Salah, we need a few permissions.':
        'Pour profiter pleinement de Sukkur Salah, nous avons besoin de quelques autorisations.',
    'To set the phone to Silent mode automatically, this app needs "Do Not Disturb" (Notification Policy Access) permission. Please grant it in the next settings screen.':
        "Pour mettre le téléphone en mode silencieux automatiquement, cette application a besoin de l'autorisation « Ne pas déranger » (accès à la politique de notification). Veuillez l'accorder dans l'écran de paramètres suivant.",
    'Translation: Hazrat Mufti Taqi Usmani Hafizahullah':
        'Traduction : Hazrat Mufti Taqi Usmani Hafizahullah',
    'Use Vibrate Instead': 'Utiliser le vibreur à la place',
    'Vibration': 'Vibration',
    'View Details': 'Voir les détails',
    'Your current location is needed to calculate the accurate Qibla direction.':
        'Votre position actuelle est nécessaire pour calculer précisément la direction de la Qibla.',
    'e.g. Prepare for Fajr': 'ex. Se préparer pour le Fajr',
    'of': 'sur',
    '{minutes} minutes after {prayer}': '{minutes} minutes après {prayer}',
    '{minutes} minutes before {prayer}': '{minutes} minutes avant {prayer}',
    'جنتری': 'Jantri',
    'حضرت ڈاکٹر حفیظ اللہ صاحب': 'Hazrat Dr Hafeezullah Sahib',
    'قَدَّسَ اللہ سِرَّہُ': 'Qaddasallahu sirrahu',
    '✓  Facing Qibla': '✓  Vous êtes face à la Qibla',
  },
  'hindi': {
    'Select Sukkur Jantri (Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri) from the side bar for accurate timings': 'सटीक समय के लिए साइड बार से सुक्कुर जंत्री (हज़रत डॉ हफ़ीज़ुल्लाह साहिब क़द्दसल्लाहु सिर्रहु जंत्री पर आधारित) चुनें',
    'Quran Translation Now Works Offline': 'क़ुरआन का अनुवाद अब ऑफ़लाइन उपलब्ध',
    'The complete English and Urdu translation by Hazrat Mufti Taqi Usmani Hafizahullah is now built into the app. All 114 Surahs open instantly without any internet connection.': 'हज़रत मुफ़्ती तक़ी उस्मानी हफ़िज़हुल्लाह का पूरा अंग्रेज़ी और उर्दू अनुवाद अब ऐप में शामिल है। सभी 114 सूरतें बिना इंटरनेट के तुरंत खुलती हैं।',
    'Translation Error Fixed': 'अनुवाद की त्रुटि ठीक की गई',
    'Fixed the incorrect "Please check your internet connection" message that appeared even when the connection was working fine.': 'इंटरनेट ठीक होने पर भी दिखने वाला ग़लत संदेश "कृपया अपना इंटरनेट कनेक्शन जाँचें" ठीक कर दिया गया है।',
    '16 Lines Tajweed Quran Opens Faster': '16 लाइन तजवीद क़ुरआन तेज़ी से खुलता है',
    'Each Parah is now prepared only once, so it opens almost instantly every time after the first use instead of taking a few seconds.': 'हर पारा अब केवल एक बार तैयार होता है, इसलिए पहली बार के बाद यह कुछ सेकंड के बजाय लगभग तुरंत खुल जाता है।',
    'Accurate Timings for World Cities': 'विश्व के शहरों के सटीक समय',
    'When you select any city from World Prayer Timings, the app now shows the six standard prayers - Fajar, Sunrise, Zuhar, Asr, Maghrib and Isha - from accurate astronomical calculation. Sukkur continues to show the complete Jantri with all ten timings.': 'वर्ल्ड प्रेयर टाइमिंग्स से कोई शहर चुनने पर ऐप अब छह मुख्य नमाज़ें - फ़ज्र, सूर्योदय, ज़ुहर, अस्र, मग़रिब और इशा - सटीक खगोलीय गणना से दिखाता है। सुक्कुर के लिए सभी दस समयों वाली पूरी जंत्री पहले की तरह रहेगी।',
    'Asr Juristic Method Option': 'अस्र के लिए फ़िक़ही तरीक़े का विकल्प',
    'Choose Hanafi, Shafi, Maliki or Hanbali for Asr in World Prayer Timings. Your selection is now applied correctly to the calculated Asr time.': 'वर्ल्ड प्रेयर टाइमिंग्स में अस्र के लिए हनफ़ी, शाफ़ई, मालिकी या हंबली चुनें। आपका चयन अब गणना किए गए अस्र समय पर सही ढंग से लागू होता है।',
    'City Name in Your Own Language': 'शहर का नाम आपकी अपनी भाषा में',
    'A city selected from World Prayer Timings now appears in your chosen app language, and updates automatically when you change the language.': 'वर्ल्ड प्रेयर टाइमिंग्स से चुना गया शहर अब आपकी चुनी हुई भाषा में दिखता है और भाषा बदलने पर अपने आप बदल जाता है।',
    'Cleaner Header & Monthly Schedule': 'बेहतर हेडर और मासिक समय-सारणी',
    'The top of the Times and Today screens now shows just the city name with a refreshed location pin, and the Monthly Schedule displays the city beside the month.': 'समय और आज की स्क्रीन के ऊपर अब केवल शहर का नाम और नया लोकेशन पिन दिखता है, और मासिक समय-सारणी में महीने के साथ शहर भी दिखाया जाता है।',
    'Last selected': 'अंतिम चयनित',
    'No city selected. Showing the Sukkur Jantri.': 'कोई शहर चयनित नहीं। सुक्कुर जंतरी दिखाई जा रही है।',
    'Currently showing the Sukkur Jantri.': 'इस समय सुक्कुर जंतरी दिखाई जा रही है।',
    'Use {city}': '{city} का उपयोग करें',
    'Reminder': 'अनुस्मारक',
    '{prayer} time has started': '{prayer} का समय शुरू हो गया है',
    '(Forbidden time for prayer)': '(नमाज़ का मना समय)',
    '(You can pray now)': '(अब नमाज़ पढ़ सकते हैं)',
    'Test Notification': 'परीक्षण सूचना',
    'If you see and hear this, your notifications are working perfectly!':
        'अगर आप इसे देख और सुन रहे हैं, तो आपकी सूचनाएँ बिल्कुल ठीक काम कर रही हैं!',
    'Select Sukkur timings from the side bar — Sukkur (Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu)':
        'साइड बार से सुक्कुर का समय चुनें — सुक्कुर (जंत्री हज़रत डॉ. हफ़ीज़ुल्लाह साहब क़द्दसल्लाहु सिर्रहु)',
    'All prayers done for today': 'आज की सभी नमाज़ें पूरी हुईं',
    'Analog': 'एनालॉग',
    'Arba (1/4)': 'रुबा (1/4)',
    'At {prayer} time': '{prayer} के समय',
    'Ayahs': 'आयतें',
    'Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri':
        'हज़रत डॉ. हफ़ीज़ुल्लाह साहब क़द्दसल्लाहु सिर्रहु की जंत्री के अनुसार',
    'Beginning of the Para': 'पारे की शुरुआत',
    'Clock Style': 'घड़ी की शैली',
    'Could Not Get Location': 'स्थान प्राप्त नहीं हो सका',
    'Could not load the translation.': 'अनुवाद लोड नहीं हो सका।',
    'Could not load the translation. Please check your internet connection.':
        'अनुवाद लोड नहीं हो सका। कृपया अपना इंटरनेट कनेक्शन जाँचें।',
    'Could not open this Parah.': 'यह पारा नहीं खुल सका।',
    'Could not play audio': 'ऑडियो नहीं चल सका',
    'Detecting your location…': 'आपका स्थान पता लगाया जा रहा है…',
    'Digital': 'डिजिटल',
    'Dismiss': 'खारिज करें',
    'Display Theme': 'डिस्प्ले थीम',
    'Error sharing/saving image:': 'छवि साझा/सहेजने में त्रुटि:',
    'First quarter': 'पहला चौथाई',
    'Half': 'आधा',
    'Heading': 'आपका रुख़',
    'Label (optional)': 'लेबल (वैकल्पिक)',
    'Loading translation...': 'अनुवाद लोड हो रहा है...',
    'Location Permission Needed': 'स्थान की अनुमति आवश्यक',
    'Location Services Off': 'लोकेशन सेवाएँ बंद हैं',
    'Madani': 'मदनी',
    'Makki': 'मक्की',
    'Mint': 'मिंट',
    'Minus': 'घटाएँ',
    'Minutes': 'मिनट',
    'Needed to accurately calculate prayer times and find the Qibla direction.':
        'नमाज़ के सही समय की गणना और क़िबला की दिशा जानने के लिए आवश्यक है।',
    'Needed to bypass battery savers so alerts ring exactly on time.':
        'बैटरी सेवर को दरकिनार कर अलर्ट ठीक समय पर बजाने के लिए आवश्यक है।',
    'Needed to send you Adhan and prayer time alerts on time.':
        'अज़ान और नमाज़ के समय के अलर्ट समय पर भेजने के लिए आवश्यक है।',
    'Nisf (1/2)': 'निस्फ़ (1/2)',
    'No Parah found': 'कोई पारा नहीं मिला',
    'No Surahs found': 'कोई सूरह नहीं मिली',
    'No data available': 'कोई डेटा उपलब्ध नहीं',
    'No favorites yet.\nTap ♡ on any Surah or Parah.':
        'अभी कोई पसंदीदा नहीं।\nकिसी भी सूरह या पारे पर ♡ दबाएँ।',
    'No reminders yet': 'अभी कोई अनुस्मारक नहीं',
    'None': 'कोई नहीं',
    'Notification now shows a single icon on the right side for Urdu and Sindhi (RTL), matching the natural reading direction.':
        'अब सूचना उर्दू और सिंधी (दाएँ से बाएँ) के लिए दाईं ओर एक ही आइकन दिखाती है, जो स्वाभाविक पढ़ने की दिशा से मेल खाती है।',
    'Notifications are turned off for this app. Prayer alerts will not appear until you enable them in system settings.':
        'इस ऐप के लिए सूचनाएँ बंद हैं। जब तक आप उन्हें सिस्टम सेटिंग्स में चालू नहीं करते, नमाज़ के अलर्ट नहीं दिखेंगे।',
    'PRAYER TIMINGS CUSTOMIZATION': 'नमाज़ के समय का अनुकूलन',
    'Parahs': 'पारे',
    'Permission Permanently Denied': 'अनुमति स्थायी रूप से अस्वीकृत',
    'Permission Required': 'अनुमति आवश्यक',
    'Please enable GPS / Location Services on your device.':
        'कृपया अपने डिवाइस पर जीपीएस / लोकेशन सेवाएँ चालू करें।',
    'Please go to app settings and enable location permission.':
        'कृपया ऐप सेटिंग्स में जाकर स्थान की अनुमति चालू करें।',
    'Prayers done': 'नमाज़ें पूरी',
    'Qibla from North': 'उत्तर से क़िबला की दिशा',
    'Ramzan Timetable': 'रमज़ान समय-सारणी',
    'Required Permissions': 'आवश्यक अनुमतियाँ',
    'Round': 'गोल',
    'Save / Share': 'सहेजें / साझा करें',
    'Search Page No (1-549)...': 'पृष्ठ संख्या खोजें (1-549)...',
    'Select Quarter': 'चौथाई चुनें',
    'Share Sukkur Salah with your friends and family':
        'सुक्कुर सलाह को अपने दोस्तों और परिवार के साथ साझा करें',
    'Slasa (3/4)': 'सलासा (3/4)',
    'Something went wrong. Please try again.':
        'कुछ गड़बड़ हो गई। कृपया फिर से प्रयास करें।',
    'Worldwide Prayer Timings': 'दुनिया भर की नमाज़ का समय',
    // ── What's New, version 1.1.3 ──
    "What's New": 'नया क्या है',
    'Monthly Jantri Now Fully Translated': 'मासिक जंत्री अब पूरी तरह अनूदित',
    'The Monthly Schedule column headings - Date, Intiha e Sehar, Fajar, Zuhar and the rest - now appear in your chosen language instead of English, for both the Sukkur Jantri and world city timings.':
        'मासिक सूची के कॉलम शीर्षक - दिनांक, सहरी का अंत, फ़ज्र, ज़ोहर और बाकी सभी - अब अंग्रेज़ी के बजाय आपकी चुनी हुई भाषा में दिखते हैं, सुक्कुर जंत्री और दुनिया भर के शहरों दोनों के लिए।',
    'Sharper Quran Pages': 'क़ुरआन के पन्ने अधिक स्पष्ट',
    "Mushaf pages are now rendered at your screen's own resolution with proper filtering, so the text looks noticeably crisper on high resolution displays.":
        'मुसहफ़ के पन्ने अब आपकी स्क्रीन के मूल रिज़ॉल्यूशन पर तैयार होते हैं, इसलिए उच्च रिज़ॉल्यूशन वाली स्क्रीन पर लिखावट काफ़ी साफ़ दिखती है।',
    'Redesigned Home Screen Widgets': 'होम स्क्रीन विजेट का नया रूप',
    'The home screen widgets have a slimmer, cleaner look, and the circle clock widget now shows AM/PM alongside the time.':
        'होम स्क्रीन के विजेट अब पतले और साफ़ हैं, और गोल घड़ी विजेट में समय के साथ AM/PM भी दिखता है।',
    'Sukkur Always Uses the Jantri': 'सुक्कुर हमेशा जंत्री के अनुसार',
    'Sukkur now always shows the authentic Jantri timings and never falls back to calculated ones. After choosing a city you are also taken straight to the Times screen.':
        'सुक्कुर अब हमेशा असली जंत्री के समय दिखाता है और कभी गणना किए गए समय पर नहीं जाता। शहर चुनने के बाद आप सीधे समय स्क्रीन पर पहुँच जाते हैं।',
    'Your Last City Is Remembered': 'आपका पिछला शहर याद रहता है',
    'Switching back to World Prayer Timings returns you to the city you were last using, instead of asking you to choose it again.':
        'विश्व प्रार्थना पर लौटने पर आपको वही शहर मिलता है जो आपने आख़िरी बार इस्तेमाल किया था, दोबारा चुनने की ज़रूरत नहीं।',
    'Clearer Analogue Clock': 'एनालॉग घड़ी अधिक स्पष्ट',
    'The analogue clock hands are slimmer and easier to read across every clock style.':
        'एनालॉग घड़ी की सुइयाँ अब पतली और हर घड़ी शैली में पढ़ने में आसान हैं।',
    'Neater Screen Layout': 'साफ़-सुथरा स्क्रीन लेआउट',
    'The advisory note at the bottom of the Today and Monthly screens now sits flush against the navigation bar, with no leftover gap.':
        'आज और मासिक स्क्रीन के नीचे दी गई सूचना अब नेविगेशन बार से बिल्कुल सटी हुई है, बीच में कोई ख़ाली जगह नहीं।',
    'Sukkur Salah': 'सुक्कुर सलाह',
    'Sukkur Salah – Namaz timings for Sukkur. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah':
        'सुक्कुर सलाह – सुक्कुर के लिए नमाज़ का समय। अभी डाउनलोड करें:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
    'Sukkur, Sindh, Pakistan': 'सुक्कुर, सिंध, पाकिस्तान',
    'Surahs': 'सूरतें',
    'Tap + to add a custom reminder before or after any prayer.':
        'किसी भी नमाज़ से पहले या बाद अनुस्मारक जोड़ने के लिए + दबाएँ।',
    'Third quarter': 'तीसरा चौथाई',
    'To get the most out of Sukkur Salah, we need a few permissions.':
        'सुक्कुर सलाह का पूरा लाभ लेने के लिए हमें कुछ अनुमतियाँ चाहिए।',
    'To set the phone to Silent mode automatically, this app needs "Do Not Disturb" (Notification Policy Access) permission. Please grant it in the next settings screen.':
        'फ़ोन को स्वतः साइलेंट करने के लिए इस ऐप को "डू नॉट डिस्टर्ब" (सूचना नीति एक्सेस) अनुमति चाहिए। कृपया अगली सेटिंग्स स्क्रीन पर यह अनुमति दें।',
    'Translation: Hazrat Mufti Taqi Usmani Hafizahullah':
        'अनुवाद: हज़रत मुफ़्ती तक़ी उस्मानी हफ़िज़हुल्लाह',
    'Use Vibrate Instead': 'इसके बजाय कंपन का उपयोग करें',
    'Vibration': 'कंपन',
    'View Details': 'विवरण देखें',
    'Your current location is needed to calculate the accurate Qibla direction.':
        'सटीक क़िबला दिशा की गणना के लिए आपका वर्तमान स्थान आवश्यक है।',
    'e.g. Prepare for Fajr': 'जैसे फ़ज्र की तैयारी करें',
    'of': 'में से',
    '{minutes} minutes after {prayer}': '{prayer} के {minutes} मिनट बाद',
    '{minutes} minutes before {prayer}': '{prayer} से {minutes} मिनट पहले',
    'جنتری': 'जंत्री',
    'حضرت ڈاکٹر حفیظ اللہ صاحب': 'हज़रत डॉ. हफ़ीज़ुल्लाह साहब',
    'قَدَّسَ اللہ سِرَّہُ': 'क़द्दसल्लाहु सिर्रहु',
    '✓  Facing Qibla': '✓  आप क़िबला की ओर हैं',
  },
  'persian': {
    'Select Sukkur Jantri (Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri) from the side bar for accurate timings': 'برای اوقات دقیق، جنتری سکر (بر پایه جنتری حضرت دکتر حفیظ‌الله صاحب قدس‌الله سره) را از نوار کناری انتخاب کنید',
    'Quran Translation Now Works Offline': 'ترجمه قرآن اکنون به‌صورت آفلاین کار می‌کند',
    'The complete English and Urdu translation by Hazrat Mufti Taqi Usmani Hafizahullah is now built into the app. All 114 Surahs open instantly without any internet connection.': 'ترجمه کامل انگلیسی و اردوی حضرت مفتی تقی عثمانی حفظه‌الله اکنون درون برنامه قرار دارد. هر ۱۱۴ سوره بدون اتصال به اینترنت بی‌درنگ باز می‌شود.',
    'Translation Error Fixed': 'خطای ترجمه برطرف شد',
    'Fixed the incorrect "Please check your internet connection" message that appeared even when the connection was working fine.': 'پیام نادرست «لطفاً اتصال اینترنت خود را بررسی کنید» که با وجود اتصال سالم نمایش داده می‌شد برطرف شد.',
    '16 Lines Tajweed Quran Opens Faster': 'قرآن تجویدی ۱۶ سطری سریع‌تر باز می‌شود',
    'Each Parah is now prepared only once, so it opens almost instantly every time after the first use instead of taking a few seconds.': 'هر جزء اکنون تنها یک بار آماده می‌شود، بنابراین پس از نخستین استفاده به‌جای چند ثانیه تقریباً بی‌درنگ باز می‌شود.',
    'Accurate Timings for World Cities': 'اوقات دقیق برای شهرهای جهان',
    'When you select any city from World Prayer Timings, the app now shows the six standard prayers - Fajar, Sunrise, Zuhar, Asr, Maghrib and Isha - from accurate astronomical calculation. Sukkur continues to show the complete Jantri with all ten timings.': 'هنگامی که شهری را از اوقات نماز جهانی انتخاب می‌کنید، برنامه اکنون شش نماز اصلی - فجر، طلوع آفتاب، ظهر، عصر، مغرب و عشا - را بر پایه محاسبه دقیق نجومی نشان می‌دهد. برای سکر جنتری کامل با هر ده وقت مانند گذشته باقی می‌ماند.',
    'Asr Juristic Method Option': 'گزینه مذهب فقهی برای عصر',
    'Choose Hanafi, Shafi, Maliki or Hanbali for Asr in World Prayer Timings. Your selection is now applied correctly to the calculated Asr time.': 'در اوقات نماز جهانی برای عصر حنفی، شافعی، مالکی یا حنبلی را انتخاب کنید. انتخاب شما اکنون به‌درستی بر زمان محاسبه‌شده عصر اعمال می‌شود.',
    'City Name in Your Own Language': 'نام شهر به زبان خودتان',
    'A city selected from World Prayer Timings now appears in your chosen app language, and updates automatically when you change the language.': 'شهری که از اوقات نماز جهانی انتخاب می‌شود اکنون به زبان انتخابی شما نمایش داده می‌شود و با تغییر زبان به‌طور خودکار به‌روز می‌گردد.',
    'Cleaner Header & Monthly Schedule': 'سربرگ و برنامه ماهانه مرتب‌تر',
    'The top of the Times and Today screens now shows just the city name with a refreshed location pin, and the Monthly Schedule displays the city beside the month.': 'بالای صفحه‌های اوقات و امروز اکنون تنها نام شهر همراه با نشانگر مکان تازه نمایش داده می‌شود و برنامه ماهانه شهر را در کنار ماه نشان می‌دهد.',
    'Last selected': 'آخرین مکان انتخابی',
    'No city selected. Showing the Sukkur Jantri.': 'شهری انتخاب نشده است. جنتری سکر نمایش داده می‌شود.',
    'Currently showing the Sukkur Jantri.': 'در حال حاضر جنتری سکر نمایش داده می‌شود.',
    'Use {city}': 'استفاده از {city}',
    'Reminder': 'یادآور',
    '{prayer} time has started': 'وقت {prayer} فرا رسید',
    '(Forbidden time for prayer)': '(وقت ممنوع برای نماز)',
    '(You can pray now)': '(اکنون می‌توانید نماز بخوانید)',
    'Test Notification': 'اعلان آزمایشی',
    'If you see and hear this, your notifications are working perfectly!':
        'اگر این را می‌بینید و می‌شنوید، اعلان‌های شما به‌درستی کار می‌کنند!',
    'Select Sukkur timings from the side bar — Sukkur (Jantri Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu)':
        'اوقات سکر را از نوار کناری انتخاب کنید — سکر (جنتری حضرت دکتر حفیظ‌الله صاحب قَدَّسَ اللهُ سِرَّهُ)',
    'All prayers done for today': 'همه نمازهای امروز خوانده شد',
    'Analog': 'عقربه‌ای',
    'Arba (1/4)': 'ربع (۱/۴)',
    'At {prayer} time': 'در وقت {prayer}',
    'Ayahs': 'آیات',
    'Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri':
        'بر اساس جنتری حضرت دکتر حفیظ‌الله صاحب قدس‌الله سره',
    'Beginning of the Para': 'آغاز جزء',
    'Clock Style': 'سبک ساعت',
    'Could Not Get Location': 'موقعیت به دست نیامد',
    'Could not load the translation.': 'ترجمه بارگذاری نشد.',
    'Could not load the translation. Please check your internet connection.':
        'ترجمه بارگذاری نشد. لطفاً اتصال اینترنت خود را بررسی کنید.',
    'Could not open this Parah.': 'این جزء باز نشد.',
    'Could not play audio': 'صدا پخش نشد',
    'Detecting your location…': 'در حال یافتن موقعیت شما…',
    'Digital': 'دیجیتال',
    'Dismiss': 'رد کردن',
    'Display Theme': 'پوسته نمایش',
    'Error sharing/saving image:': 'خطا در اشتراک‌گذاری/ذخیره تصویر:',
    'First quarter': 'ربع اول',
    'Half': 'نصف',
    'Heading': 'جهت شما',
    'Label (optional)': 'برچسب (اختیاری)',
    'Loading translation...': 'در حال بارگذاری ترجمه...',
    'Location Permission Needed': 'اجازه دسترسی به موقعیت لازم است',
    'Location Services Off': 'خدمات موقعیت‌یابی خاموش است',
    'Madani': 'مدنی',
    'Makki': 'مکی',
    'Mint': 'نعنایی',
    'Minus': 'منها',
    'Minutes': 'دقیقه',
    'Needed to accurately calculate prayer times and find the Qibla direction.':
        'برای محاسبه دقیق اوقات نماز و یافتن جهت قبله لازم است.',
    'Needed to bypass battery savers so alerts ring exactly on time.':
        'برای عبور از بهینه‌سازهای باتری تا هشدارها دقیقاً سر وقت به صدا درآیند لازم است.',
    'Needed to send you Adhan and prayer time alerts on time.':
        'برای ارسال به‌موقع اذان و هشدارهای اوقات نماز لازم است.',
    'Nisf (1/2)': 'نصف (۱/۲)',
    'No Parah found': 'جزئی یافت نشد',
    'No Surahs found': 'سوره‌ای یافت نشد',
    'No data available': 'داده‌ای موجود نیست',
    'No favorites yet.\nTap ♡ on any Surah or Parah.':
        'هنوز موردی به علاقه‌مندی‌ها اضافه نشده است.\nروی ♡ هر سوره یا جزء بزنید.',
    'No reminders yet': 'هنوز یادآوری وجود ندارد',
    'None': 'هیچ‌کدام',
    'Notification now shows a single icon on the right side for Urdu and Sindhi (RTL), matching the natural reading direction.':
        'اعلان اکنون برای اردو و سندی (راست‌به‌چپ) یک نماد در سمت راست نشان می‌دهد که با جهت طبیعی خواندن هماهنگ است.',
    'Notifications are turned off for this app. Prayer alerts will not appear until you enable them in system settings.':
        'اعلان‌های این برنامه خاموش است. تا زمانی که آن‌ها را در تنظیمات سیستم فعال نکنید، هشدارهای نماز نمایش داده نمی‌شوند.',
    'PRAYER TIMINGS CUSTOMIZATION': 'شخصی‌سازی اوقات نماز',
    'Parahs': 'اجزاء',
    'Permission Permanently Denied': 'اجازه به‌طور دائم رد شد',
    'Permission Required': 'اجازه لازم است',
    'Please enable GPS / Location Services on your device.':
        'لطفاً GPS / خدمات موقعیت‌یابی را در دستگاه خود فعال کنید.',
    'Please go to app settings and enable location permission.':
        'لطفاً به تنظیمات برنامه بروید و اجازه دسترسی به موقعیت را فعال کنید.',
    'Prayers done': 'نمازهای خوانده‌شده',
    'Qibla from North': 'قبله از شمال',
    'Ramzan Timetable': 'جدول اوقات رمضان',
    'Required Permissions': 'اجازه‌های لازم',
    'Round': 'گرد',
    'Save / Share': 'ذخیره / اشتراک‌گذاری',
    'Search Page No (1-549)...': 'جستجوی شماره صفحه (۱-۵۴۹)...',
    'Select Quarter': 'انتخاب ربع',
    'Share Sukkur Salah with your friends and family':
        'سکر صلاۃ را با دوستان و خانواده خود به اشتراک بگذارید',
    'Slasa (3/4)': 'ثلاثه (۳/۴)',
    'Something went wrong. Please try again.':
        'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.',
    'Worldwide Prayer Timings': 'اوقات نماز سراسر جهان',
    // ── What's New, version 1.1.3 ──
    "What's New": 'تازه‌ها',
    'Monthly Jantri Now Fully Translated': 'جنتری ماهانه اکنون کاملاً ترجمه شده',
    'The Monthly Schedule column headings - Date, Intiha e Sehar, Fajar, Zuhar and the rest - now appear in your chosen language instead of English, for both the Sukkur Jantri and world city timings.':
        'عنوان ستون‌های برنامه ماهانه - تاریخ، پایان سحر، فجر، ظهر و بقیه - اکنون به جای انگلیسی به زبان انتخابی شما نمایش داده می‌شود، هم برای جنتری سکر و هم برای شهرهای جهان.',
    'Sharper Quran Pages': 'صفحات قرآن شفاف‌تر',
    "Mushaf pages are now rendered at your screen's own resolution with proper filtering, so the text looks noticeably crisper on high resolution displays.":
        'صفحات مصحف اکنون با وضوح واقعی صفحه‌نمایش شما پردازش می‌شوند، بنابراین متن روی نمایشگرهای با وضوح بالا به‌مراتب شفاف‌تر دیده می‌شود.',
    'Redesigned Home Screen Widgets': 'طراحی تازه ابزارک‌های صفحه اصلی',
    'The home screen widgets have a slimmer, cleaner look, and the circle clock widget now shows AM/PM alongside the time.':
        'ابزارک‌های صفحه اصلی ظاهری باریک‌تر و تمیزتر دارند و ابزارک ساعت دایره‌ای اکنون ق.ظ/ب.ظ را کنار زمان نشان می‌دهد.',
    'Sukkur Always Uses the Jantri': 'سکر همیشه از جنتری استفاده می‌کند',
    'Sukkur now always shows the authentic Jantri timings and never falls back to calculated ones. After choosing a city you are also taken straight to the Times screen.':
        'سکر اکنون همیشه اوقات اصیل جنتری را نشان می‌دهد و هرگز به اوقات محاسبه‌شده بازنمی‌گردد. پس از انتخاب شهر نیز مستقیماً به صفحه اوقات می‌روید.',
    'Your Last City Is Remembered': 'آخرین شهر شما به خاطر سپرده می‌شود',
    'Switching back to World Prayer Timings returns you to the city you were last using, instead of asking you to choose it again.':
        'با بازگشت به اوقات شرعی جهان، همان شهری که آخرین بار استفاده می‌کردید نمایش داده می‌شود و نیازی به انتخاب دوباره نیست.',
    'Clearer Analogue Clock': 'ساعت عقربه‌ای خواناتر',
    'The analogue clock hands are slimmer and easier to read across every clock style.':
        'عقربه‌های ساعت عقربه‌ای باریک‌تر و در همه سبک‌های ساعت خواناتر شده‌اند.',
    'Neater Screen Layout': 'چیدمان مرتب‌تر صفحه',
    'The advisory note at the bottom of the Today and Monthly screens now sits flush against the navigation bar, with no leftover gap.':
        'یادداشت راهنما در پایین صفحه‌های امروز و ماهانه اکنون کاملاً به نوار پیمایش چسبیده است و فاصله‌ای باقی نمانده.',
    'Sukkur Salah': 'سکر صلاۃ',
    'Sukkur Salah – Namaz timings for Sukkur. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah':
        'سکر صلاۃ – اوقات نماز برای سکر. هم‌اکنون دانلود کنید:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
    'Sukkur, Sindh, Pakistan': 'سکر، سند، پاکستان',
    'Surahs': 'سوره‌ها',
    'Tap + to add a custom reminder before or after any prayer.':
        'برای افزودن یادآوری پیش یا پس از هر نماز، روی + بزنید.',
    'Third quarter': 'سه‌ربع',
    'To get the most out of Sukkur Salah, we need a few permissions.':
        'برای بهره‌مندی کامل از سکر صلاۃ، به چند اجازه نیاز داریم.',
    'To set the phone to Silent mode automatically, this app needs "Do Not Disturb" (Notification Policy Access) permission. Please grant it in the next settings screen.':
        'برای بی‌صدا کردن خودکار گوشی، این برنامه به اجازه «مزاحم نشوید» (دسترسی به سیاست اعلان) نیاز دارد. لطفاً آن را در صفحه تنظیمات بعدی بدهید.',
    'Translation: Hazrat Mufti Taqi Usmani Hafizahullah':
        'ترجمه: حضرت مفتی تقی عثمانی حفظه‌الله',
    'Use Vibrate Instead': 'در عوض از لرزش استفاده کنید',
    'Vibration': 'لرزش',
    'View Details': 'مشاهده جزئیات',
    'Your current location is needed to calculate the accurate Qibla direction.':
        'برای محاسبه دقیق جهت قبله، موقعیت فعلی شما لازم است.',
    'e.g. Prepare for Fajr': 'مثلاً آماده شدن برای نماز صبح',
    'of': 'از',
    '{minutes} minutes after {prayer}': '{minutes} دقیقه پس از {prayer}',
    '{minutes} minutes before {prayer}': '{minutes} دقیقه پیش از {prayer}',
    'جنتری': 'جنتری',
    'حضرت ڈاکٹر حفیظ اللہ صاحب': 'حضرت دکتر حفیظ‌الله صاحب',
    'قَدَّسَ اللہ سِرَّہُ': 'قَدَّسَ اللهُ سِرَّهُ',
    '✓  Facing Qibla': '✓  رو به قبله هستید',
  },
};
