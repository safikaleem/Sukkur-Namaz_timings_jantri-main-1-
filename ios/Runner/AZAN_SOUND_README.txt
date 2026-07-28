AZAN / TAKBIR NOTIFICATION SOUND  (iOS)
========================================

iOS notification sounds must be a short audio file bundled in the app and
referenced BY FILE NAME (with extension) from the notification payload.

Steps:
1. Prepare a short takbir clip ("Allahu Akbar, Allahu Akbar"), under ~30s.
   Recommended format for notifications: CAF / AIFF / WAV (linear PCM).
   Name it exactly:   azan_takbir.aiff
   (If you prefer another extension, update _azanSoundIos in
    lib/services/notification_service.dart to match, e.g. 'azan_takbir.caf'.)

2. In Xcode, open ios/Runner.xcworkspace, drag azan_takbir.aiff into the
   "Runner" group and make sure:
      - "Copy items if needed" is checked
      - Target membership: Runner  (checkbox ticked)

   This bundles the file into the app so iOS can find it by name.

3. The code already passes  sound: 'azan_takbir.aiff'  for the Azan alert mode.

Note: iOS caps custom notification sounds at 30 seconds; longer files fall
back to the default sound. Keep it to the opening takbir only.
