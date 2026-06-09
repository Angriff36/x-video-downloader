package com.angriff.x_video_downloader

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.angriff.x_video_downloader/media_scanner"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    path?.let {
                        val file = File(it)
                        val uri = Uri.fromFile(file)
                        val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri)
                        sendBroadcast(intent)
                        result.success(null)
                    } ?: result.error("NULL_PATH", "File path is null", null)
                }
                "publishToDownloads" -> {
                    val path = call.argument<String>("path")
                    val displayName = call.argument<String>("displayName")
                    val mimeType = call.argument<String>("mimeType") ?: "video/mp4"
                    if (path == null || displayName == null) {
                        result.error("INVALID_ARGS", "path and displayName are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val source = File(path)
                        if (!source.exists()) {
                            result.error("NOT_FOUND", "Source file does not exist", null)
                            return@setMethodCallHandler
                        }

                        val values = ContentValues().apply {
                            put(MediaStore.Downloads.DISPLAY_NAME, displayName)
                            put(MediaStore.Downloads.MIME_TYPE, mimeType)
                            put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/x_video_downloads")
                            put(MediaStore.Downloads.IS_PENDING, 1)
                        }
                        val resolver = applicationContext.contentResolver
                        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                        if (uri == null) {
                            result.error("INSERT_FAILED", "Could not create Downloads entry", null)
                            return@setMethodCallHandler
                        }

                        resolver.openOutputStream(uri)?.use { output ->
                            FileInputStream(source).use { input ->
                                input.copyTo(output)
                            }
                        } ?: run {
                            result.error("OPEN_FAILED", "Could not open Downloads entry", null)
                            return@setMethodCallHandler
                        }

                        values.clear()
                        values.put(MediaStore.Downloads.IS_PENDING, 0)
                        resolver.update(uri, values, null, null)
                        result.success(uri.toString())
                    } catch (e: Exception) {
                        result.error("PUBLISH_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
