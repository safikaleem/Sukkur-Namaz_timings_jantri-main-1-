package pk.sukkur.salah

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.util.Log

/**
 * AlarmManager alarms do not survive a reboot, so if the device restarts while
 * an auto-silent window is active, the "restore" alarm is lost and the phone
 * would stay silenced indefinitely. On boot we detect that case (an applied
 * ringer mode is still recorded) and restore the user's previous ringer mode.
 *
 * The full weekly schedule is re-registered by the Dart layer the next time the
 * app is resumed (scheduleWeeklyNotifications on AppLifecycleState.resumed);
 * this receiver's job is only to make sure the ringer is never left stuck.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }

        val prefs = context.getSharedPreferences("auto_silent_prefs", Context.MODE_PRIVATE)
        val appliedMode = prefs.getInt("applied_ringer_mode", -1)
        if (appliedMode == -1) return // no window was active — nothing to unstick

        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentMode = audioManager.ringerMode
        // Only revert if the phone is still in the mode we set (the user may have
        // changed it manually after the reboot).
        if (currentMode == appliedMode) {
            val prevMode = prefs.getInt("previous_ringer_mode", AudioManager.RINGER_MODE_NORMAL)
            try {
                audioManager.ringerMode = prevMode
                Log.d("BootReceiver", "Restored ringer mode to $prevMode after boot")
            } catch (e: Exception) {
                Log.e("BootReceiver", "Failed to restore ringer mode after boot: $e")
            }
        }
        prefs.edit().remove("applied_ringer_mode").apply()
    }
}
