package com.samaommy.iqra

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.FileProvider
import java.io.File

/** Sends a picture straight to one chat or social app (WhatsApp's status, Instagram's story…), and saves it to the gallery. */
object ShareTargets {
    private val known = listOf(
        "com.whatsapp", "com.whatsapp.w4b", "com.instagram.android", "org.telegram.messenger",
        "com.facebook.katana", "com.snapchat.android", "com.twitter.android",
    )

    fun installed(ctx: Context): List<String> = known.filter {
        try {
            ctx.packageManager.getPackageInfo(it, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    fun send(ctx: Context, path: String, pkg: String?, text: String?): Boolean {
        val uri = FileProvider.getUriForFile(ctx, "${ctx.packageName}.updates", File(path))
        val send = Intent(Intent.ACTION_SEND)
            .setType("image/png")
            .putExtra(Intent.EXTRA_STREAM, uri)
            .putExtra(Intent.EXTRA_TEXT, text ?: "")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val intent = if (pkg == null) {
            Intent.createChooser(send, null)
        } else {
            send.setPackage(pkg)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ctx.startActivity(intent)
        return true
    }

    /** Into Pictures/IQRA, where the gallery shows it. Needs Android 10 or later, otherwise returns false. */
    fun saveToGallery(ctx: Context, path: String, name: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/IQRA")
        }
        val uri = ctx.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
        ctx.contentResolver.openOutputStream(uri)?.use { out -> File(path).inputStream().use { it.copyTo(out) } } ?: return false
        return true
    }
}
