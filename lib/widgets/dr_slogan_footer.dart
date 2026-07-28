import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class DrSloganFooter extends StatelessWidget {
  const DrSloganFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final isSindhi = settings.language == 'sindhi';
    
    final bool isWorld = settings.locationMode == LocationMode.world;
    final bool useEnglish = isWorld && settings.language == 'english';

    final String text = isWorld
      ? settings.translate(
        'These timings are according to the calculation method, therefore a 3-minute precaution should be added to prayer timings (prayers and Iftar should be observed 3 minutes after the given times, while fasting should end 3 minutes before Subah Sadiq time).',
        'یہ اوقات کیلکیولیشن میتھڈ کے مطابق ہیں، لہٰذا نماز کے اوقات میں تین منٹ کی احتیاط شامل کی جائے (دیے گئے اوقات سے تین منٹ بعد نمازیں اور افطار کیا جائے، جبکہ روزہ صبح صادق کے وقت سے تین منٹ پہلے بند کیا جائے)',
        'هي وقت حسابي طريقي مطابق آهن، ان ڪري نماز جي وقتن ۾ ٽن منٽن جي احتياط شامل ڪئي وڃي (ڏنل وقتن کان ٽي منٽ پوءِ نماز ۽ افطار ڪيو وڃي، جڏهن ته روزو صبح صادق جي وقت کان ٽي منٽ اڳ بند ڪيو وڃي)',
        'هذه الأوقات مبنية على طريقة الحساب، لذا يجب تضمين احتياط 3 دقائق في أوقات الصلاة (يجب أداء الصلاة والإفطار بعد 3 دقائق من الأوقات المحددة، بينما يجب الإمساك عن الطعام قبل 3 دقائق من وقت الصبح الصادق).'
      )
      : settings.translate(
        'ماہر فلکیات حضرت سید کاکاخیل صاحب کا فرمانا ہے کہ تخریجِ جدید کے بعد اب یہ جنتری پنوعاقل، ہالیجی شریف،کرم پور،شکارپور،امروٹ شریف، پیرگوٹھ،خیرپور، پریالو اور شادی شہیدتک کے لئے قابل عمل ہے۔ البتہ شکارپور، امروٹ شریف اور پیر گوٹھ والے افطار اور شام کی نمازوں میں ایک منٹ کی تاخیر کریں۔',
        'ماہر فلکیات حضرت سید کاکاخیل صاحب کا فرمانا ہے کہ تخریجِ جدید کے بعد اب یہ جنتری پنوعاقل، ہالیجی شریف،کرم پور،شکارپور،امروٹ شریف، پیرگوٹھ،خیرپور، پریالو اور شادی شہیدتک کے لئے قابل عمل ہے۔ البتہ شکارپور، امروٹ شریف اور پیر گوٹھ والے افطار اور شام کی نمازوں میں ایک منٹ کی تاخیر کریں۔',
        'ماهر فلڪيات حضرت سيد ڪاڪاخيل صاحب جو فرمائڻ آهي ته جديد تخريج کان پوءِ هاڻي هي جنتري پنوعاقل، هاليجي شريف، ڪرم پور، شڪارپور، امروٽ شريف، پير ڳوٺ، خيرپور، پريالو ۽ شادي شهيد تائين لاءِ قابل عمل آهي. البته شڪارپور، امروٽ شريف ۽ پير ڳوٺ وارا افطار ۽ شام جي نمازن ۾ هڪ منٽ جي تاخير ڪن.',
        'وفقًا لعالم الفلك الشيخ سيد كاكاخيل حفظه الله، بعد الحسابات الجديدة، أصبح هذا التقويم ساريًا على بانو عاقل، هاليجي شريف، كرمبور، شيكاربور، أمروت شريف، بير کوت، خيربور، بريالو وشادي شهيد. ومع ذلك، يجب على سكان شيكاربور، أمروت شريف، وبير کوت الإمساك عن الإفطار مع الغروب دقيقة واحدة من الوقت الجدولي.'
    );

    final String? font = useEnglish 
        ? null 
        : (settings.language == 'sindhi' 
            ? AppTheme.getSindhiFont(context) 
            : (settings.language == 'arabic' ? null : AppTheme.urduFont));

    // Responsively scale down font size on smaller devices to ensure it fits nicely.
    final double fontSize = screenWidth < 360
        ? 9.2
        : (screenWidth < 400 ? 9.8 : 10.5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 360 ? 8.0 : 12.0,
        vertical: 6.0,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF0F4FF),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFF4A6FA5).withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
      ),
      child: Text(
        text,
        textDirection: useEnglish ? TextDirection.ltr : TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 4,
        style: TextStyle(
          fontFamily: font,
          fontSize: fontSize,
          color: isDark ? Colors.white70 : Colors.black87,
          height: 1.40,
        ),
      ),
    );
  }
}
