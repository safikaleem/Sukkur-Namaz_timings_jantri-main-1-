class AzanTrack {
  final String name;
  final String urduName;
  final String assetPath; // relative to assets/ folder
  final String androidSound; // raw folder filename without extension
  final String iosSound; // runner filename with extension
  const AzanTrack(
      {required this.name,
      required this.urduName,
      required this.assetPath,
      required this.androidSound,
      required this.iosSound});
}

const List<AzanTrack> azanTracks = [
  AzanTrack(
      name: 'Allah o Akbar Allah o Akbar',
      urduName: 'اللہ اکبر، اللہ اکبر',
      assetPath: 'azan_1.mp3',
      androidSound: 'azan_1',
      iosSound: 'azan_1.mp3'),
  AzanTrack(
      name: 'Makkah Azan',
      urduName: 'مکہ اذان',
      assetPath: 'makkah_azan.mp3',
      androidSound: 'makkah_azan',
      iosSound: 'makkah_azan.mp3'),
  AzanTrack(
      name: 'Allah o Akbar Allah o Akbar 2',
      urduName: 'اللہ اکبر، اللہ اکبر ۲',
      assetPath: 'azan_2.mp3',
      androidSound: 'azan_2',
      iosSound: 'azan_2.mp3'),
  AzanTrack(
      name: 'Hayya Alas Salah',
      urduName: 'حَيَّ عَلَى الصَّلَاةِ',
      assetPath: 'hayya_alas_salah.mp3',
      androidSound: 'hayya_alas_salah',
      iosSound: 'hayya_alas_salah.mp3'),
];
