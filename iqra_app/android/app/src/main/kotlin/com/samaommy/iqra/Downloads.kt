package com.samaommy.iqra

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import java.io.File

/**
 * Downloads an update with the system's download manager, so it carries on (and picks up where it stopped after a lost connection)
 * while the app is closed, with its own progress notification. The app only has to ask how it is going.
 */
object UpdateDownloads {
    private const val PREFS = "iqra_update"

    private fun dm(c: Context) = c.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager

    private fun query(c: Context, id: Long): Map<String, Any?>? {
        dm(c).query(DownloadManager.Query().setFilterById(id)).use { cur ->
            if (!cur.moveToFirst()) return null
            val status = cur.getInt(cur.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val got = cur.getLong(cur.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
            val total = cur.getLong(cur.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
            val reason = cur.getInt(cur.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
            val state = when (status) {
                DownloadManager.STATUS_PENDING -> "pending"
                DownloadManager.STATUS_RUNNING -> "running"
                DownloadManager.STATUS_PAUSED -> "paused"
                DownloadManager.STATUS_SUCCESSFUL -> "done"
                else -> "failed"
            }
            return mapOf("state" to state, "got" to got, "total" to total, "reason" to reason)
        }
    }

    private fun file(c: Context, name: String): File = File(c.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), name)

    /** Starts the download, or joins the one already under way (or finished) for the same file. */
    fun start(c: Context, url: String, name: String): Long {
        val prefs = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val oldId = prefs.getLong("id", -1L)
        val oldName = prefs.getString("name", null)
        if (oldId != -1L) {
            val st = query(c, oldId)
            val state = st?.get("state")
            if (oldName == name && (state == "running" || state == "pending" || state == "paused" || (state == "done" && file(c, name).exists()))) return oldId
            dm(c).remove(oldId)
        }
        file(c, name).delete()
        val req = DownloadManager.Request(Uri.parse(url))
            .setTitle("IQRA update")
            .setDescription(name)
            .setMimeType("application/vnd.android.package-archive")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
            .setDestinationInExternalFilesDir(c, Environment.DIRECTORY_DOWNLOADS, name)
        val id = dm(c).enqueue(req)
        prefs.edit().putLong("id", id).putString("name", name).apply()
        return id
    }

    /** How the current update download is going: state, bytes so far, total, and the file once it is done. */
    fun status(c: Context): Map<String, Any?> {
        val prefs = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val id = prefs.getLong("id", -1L)
        val name = prefs.getString("name", null)
        if (id == -1L || name == null) return mapOf("state" to "none")
        val st = query(c, id) ?: return mapOf("state" to "none")
        val out = HashMap<String, Any?>(st)
        out["name"] = name
        if (st["state"] == "done") {
            val f = file(c, name)
            if (!f.exists()) return mapOf("state" to "none")
            out["path"] = f.absolutePath
            out["size"] = f.length()
        }
        return out
    }

    fun cancel(c: Context) {
        val prefs = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val id = prefs.getLong("id", -1L)
        if (id != -1L) dm(c).remove(id)
        prefs.edit().remove("id").remove("name").apply()
    }
}

/** Tapping the download's notification opens the app (which then offers to install what was downloaded). */
class DownloadClickReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launch)
    }
}
