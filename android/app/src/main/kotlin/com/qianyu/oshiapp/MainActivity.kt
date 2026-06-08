package com.qianyu.oshiapp

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.qianyu.oshiapp/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveToGallery") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    val success = saveImageToGallery(filePath)
                    result.success(success)
                } else {
                    result.error("INVALID_PATH", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, file.name)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "DCIM/OshiApp")
                }
                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                uri?.let {
                    contentResolver.openOutputStream(it)?.use { os ->
                        FileInputStream(file).copyTo(os)
                    }
                    true
                } ?: false
            } else {
                val destDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
                val oshiDir = File(destDir, "OshiApp")
                if (!oshiDir.exists()) oshiDir.mkdirs()
                val destFile = File(oshiDir, file.name)
                file.copyTo(destFile, overwrite = true)
                MediaScannerConnection.scanFile(this, arrayOf(destFile.absolutePath), null, null)
                true
            }
        } catch (e: Exception) {
            false
        }
    }
}
