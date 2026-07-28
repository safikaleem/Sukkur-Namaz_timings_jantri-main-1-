/// How a prayer-time notification alerts the user.
///
/// - [silent]  : shown in the tray, no sound, no vibration
/// - [vibrate] : vibration only
/// - [loud]    : default system notification sound + vibration
/// - [azan]    : plays the bundled Azan (takbir) sound + vibration
enum AlertMode { silent, vibrate, loud, azan }
