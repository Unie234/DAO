package com.example.dao_culture_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val speechChannel = "dao_culture_app/speech"
    private val speechPermissionRequestCode = 6621
    private val speechTimeoutMillis = 9000L
    private val mainHandler = Handler(Looper.getMainLooper())
    private var speechRecognizer: SpeechRecognizer? = null
    private var pendingSpeechResult: MethodChannel.Result? = null
    private var isSpeechActive = false
    private var isSpeechReady = false
    private val speechTimeoutRunnable = Runnable {
        finishSpeech("")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, speechChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listenOnce" -> listenOnce(result)
                    "stopListening" -> stopListening(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun listenOnce(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            pendingSpeechResult = result
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), speechPermissionRequestCode)
            return
        }

        startSpeechRecognition(result)
    }

    private fun startSpeechRecognition(result: MethodChannel.Result) {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            result.error("speech_unavailable", "Thiết bị không hỗ trợ nhận dạng giọng nói.", null)
            return
        }

        pendingSpeechResult?.error("speech_cancelled", "Yêu cầu nhận dạng trước đã bị hủy.", null)
        releaseSpeechRecognizer(cancelActive = true)
        pendingSpeechResult = result
        mainHandler.removeCallbacks(speechTimeoutRunnable)
        mainHandler.postDelayed(speechTimeoutRunnable, speechTimeoutMillis)

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).also { recognizer ->
            recognizer.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    isSpeechReady = true
                    isSpeechActive = true
                }

                override fun onBeginningOfSpeech() {
                    isSpeechReady = true
                    isSpeechActive = true
                }

                override fun onRmsChanged(rmsdB: Float) = Unit
                override fun onBufferReceived(buffer: ByteArray?) = Unit
                override fun onEndOfSpeech() {
                    isSpeechActive = false
                }
                override fun onPartialResults(partialResults: Bundle?) = Unit
                override fun onEvent(eventType: Int, params: Bundle?) = Unit

                override fun onError(error: Int) {
                    finishSpeech("")
                }

                override fun onResults(results: Bundle?) {
                    val matches = results
                        ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    finishSpeech(matches?.firstOrNull().orEmpty())
                }
            })
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "vi-VN")
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "vi-VN")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 350L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 300L)
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Hãy nói câu hỏi của bạn")
        }

        isSpeechActive = false
        isSpeechReady = false
        speechRecognizer?.startListening(intent)
    }

    private fun stopListening(result: MethodChannel.Result) {
        val recognizer = speechRecognizer
        if (recognizer == null) {
            result.success(true)
            return
        }

        if (isSpeechReady) {
            try {
                recognizer.stopListening()
            } catch (_: Exception) {
                finishSpeech("")
            }
        } else {
            pendingSpeechResult?.success("")
            pendingSpeechResult = null
            releaseSpeechRecognizer(cancelActive = true)
        }
        result.success(true)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != speechPermissionRequestCode) return

        val result = pendingSpeechResult ?: return
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            pendingSpeechResult = null
            startSpeechRecognition(result)
        } else {
            pendingSpeechResult = null
            result.error("microphone_denied", "Bạn cần cấp quyền micro để sử dụng giọng nói.", null)
        }
    }

    private fun finishSpeech(text: String) {
        mainHandler.removeCallbacks(speechTimeoutRunnable)
        pendingSpeechResult?.success(text)
        pendingSpeechResult = null
        releaseSpeechRecognizer(cancelActive = false)
    }

    private fun releaseSpeechRecognizer(cancelActive: Boolean) {
        val recognizer = speechRecognizer ?: return
        try {
            if (cancelActive && isSpeechReady) {
                recognizer.cancel()
            }
        } catch (_: Exception) {
        }
        try {
            recognizer.destroy()
        } catch (_: Exception) {
        }
        isSpeechActive = false
        isSpeechReady = false
        speechRecognizer = null
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(speechTimeoutRunnable)
        pendingSpeechResult = null
        releaseSpeechRecognizer(cancelActive = true)
        super.onDestroy()
    }
}
