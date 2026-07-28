package pk.sukkur.salah

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.util.Log

class AutoSilentReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val action = intent.action ?: return
            val type = intent.getStringExtra("type") // "start" or "restore"
            val silentMode = intent.getStringExtra("mode") ?: "vibrate" // "vibrate" or "silent"

            Log.d("AutoSilentReceiver", "onReceive action=$action type=$type mode=$silentMode")

            val prefs = context.getSharedPreferences("auto_silent_prefs", Context.MODE_PRIVATE)

            if (type == "start") {
                val currentMode = audioManager.ringerMode
                val lastApplied = prefs.getInt("applied_ringer_mode", -1)
                if (currentMode != lastApplied) {
                    prefs.edit().putInt("previous_ringer_mode", currentMode).apply()
                }

                val targetMode = if (silentMode == "silent")
                    AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_VIBRATE
                try {
                    audioManager.ringerMode = targetMode
                    prefs.edit().putInt("applied_ringer_mode", targetMode).apply()
                    Log.d("AutoSilentReceiver", "Successfully set ringer mode to $silentMode")
                } catch (e: SecurityException) {
                    Log.e("AutoSilentReceiver", "SecurityException setting ringer mode: DND access settings required for silent mode.")
                    try {
                        audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                        prefs.edit().putInt("applied_ringer_mode", AudioManager.RINGER_MODE_VIBRATE).apply()
                    } catch (ex: Exception) {
                        Log.e("AutoSilentReceiver", "Failed to fallback to vibrate mode: $ex")
                    }
                } catch (e: Exception) {
                    Log.e("AutoSilentReceiver", "Unexpected exception setting ringer mode: $e")
                }
            } else if (type == "restore") {
                val appliedMode = prefs.getInt("applied_ringer_mode", -1)
                val currentMode = audioManager.ringerMode
                if (appliedMode == -1 || currentMode == appliedMode) {
                    val prevMode = prefs.getInt("previous_ringer_mode", AudioManager.RINGER_MODE_NORMAL)
                    try {
                        audioManager.ringerMode = prevMode
                        Log.d("AutoSilentReceiver", "Successfully restored ringer mode to $prevMode")
                    } catch (e: Exception) {
                        Log.e("AutoSilentReceiver", "Failed to restore ringer mode: $e")
                    }
                } else {
                    Log.d("AutoSilentReceiver", "User changed ringer during window; leaving as-is")
                }
                prefs.edit().remove("applied_ringer_mode").apply()
            }
        } catch (e: Exception) {
            Log.e("AutoSilentReceiver", "FATAL CRASH inside AutoSilentReceiver: $e")
        }
    }
}
