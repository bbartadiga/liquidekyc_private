package com.example.poc_liquidekyc_flutter.plugins

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import asia.liquidinc.ekyc.applicant.core.function.ResultHandler
import asia.liquidinc.ekyc.applicant.core.function.ShowTermsOfUse
import asia.liquidinc.ekyc.applicant.core.function.VerifyIdDocument
import asia.liquidinc.ekyc.applicant.core.function.VerifyIdChip
import asia.liquidinc.ekyc.applicant.core.function.VerifyFace
import asia.liquidinc.ekyc.applicant.external.TermsOfUseSettings
import asia.liquidinc.ekyc.applicant.external.VerifyIdDocumentParameters
import asia.liquidinc.ekyc.applicant.external.VerifyIdChipParameters
import asia.liquidinc.ekyc.applicant.external.VerifyFaceParameters
import asia.liquidinc.ekyc.applicant.external.result.LiquidProcessingResult
import asia.liquidinc.ekyc.applicant.external.result.LiquidDocumentVerificationResult
import asia.liquidinc.ekyc.applicant.external.result.LiquidChipVerificationResult
import asia.liquidinc.ekyc.applicant.external.result.LiquidFaceVerificationResult
import io.flutter.plugin.common.MethodChannel.Result

object SdkConfig {
    const val TAG = "LiquidEkycPlugin"
    const val CHANNEL_NAME = "com.liquid.ekyc/channel"
}

object SdkManager {
    private var _context: Context? = null
    private var _currentActivity: ComponentActivity? = null
    
    var sdkUrl: String = ""
    var sdkApplicantId: String = ""
    var sdkToken: String = ""
    var sdkApiKey: String = ""
    var isInitialized: Boolean = false
    
    var launchersRegistered: Boolean = false
    var pendingResult: Result? = null
    var pendingLaunchType: String? = null
    var pendingLaunchParams: Any? = null
    
    val handler = Handler(Looper.getMainLooper())
    
    val showTermsOfUseLauncher = ShowTermsOfUse()
    val verifyIdDocumentLauncher = VerifyIdDocument()
    val verifyIdChipLauncher = VerifyIdChip()
    val verifyFaceLauncher = VerifyFace()
    
    fun init(ctx: Context) {
        _context = ctx
    }
    
    fun getContext(): Context? = _context
    
    fun setActivity(act: ComponentActivity) {
        if (_currentActivity != act) {
            _currentActivity = act
            launchersRegistered = false
            log("Activity changed - will need to re-register launchers")
        }
    }
    
    fun getCurrentActivity(): ComponentActivity? = _currentActivity
    
    fun clearActivity() {
        _currentActivity = null
        launchersRegistered = false
    }
    
    fun clearPending() {
        pendingResult = null
        pendingLaunchType = null
        pendingLaunchParams = null
    }
    
    fun log(msg: String) {
        Log.d(SdkConfig.TAG, msg)
    }
    
    fun registerLaunchers(act: ComponentActivity) {
        if (launchersRegistered) {
            log("Launchers already registered, skipping...")
            return
        }
        
        log("===========================================")
        log("registerLaunchers() called")
        log("  currentActivity: ${_currentActivity != null}")
        log("  url: $sdkUrl (empty: ${sdkUrl.isEmpty()})")
        log("  applicantId: $sdkApplicantId (empty: ${sdkApplicantId.isEmpty()})")
        log("  token length: ${sdkToken.length} (empty: ${sdkToken.isEmpty()})")
        log("  isInitialized: $isInitialized")
        log("===========================================")
        
        _currentActivity = act
        
        try {
            log("  Registering showTermsOfUseLauncher...")
            showTermsOfUseLauncher.register(act, ResultHandler<LiquidProcessingResult> { data ->
                log("ShowTermsOfUse callback: ${data.result?.name}, error: ${data.errorCode}")
                handler.post {
                    pendingResult?.let { result ->
                        result.success(mapOf(
                            "resultStatus" to (data.result?.name ?: "UNKNOWN"),
                            "errorCode" to data.errorCode,
                            "additionalDataTitle" to (data.additionalDataTitle ?: ""),
                            "additionalDataMessage" to (data.additionalDataMessage ?: "")
                        ))
                        pendingResult = null
                    }
                }
            })
            log("  showTermsOfUseLauncher registered successfully")

            log("  Registering verifyIdDocumentLauncher...")
            verifyIdDocumentLauncher.register(act, ResultHandler<LiquidDocumentVerificationResult> { data ->
                log("VerifyIdDocument callback: ${data.resultStatus?.name}")
                handler.post {
                    pendingResult?.let { result ->
                        result.success(mapOf(
                            "resultStatus" to (data.resultStatus?.name ?: "UNKNOWN"),
                            "errorCode" to data.errorCode,
                            "additionalDataTitle" to (data.additionalDataTitle ?: ""),
                            "additionalDataMessage" to (data.additionalDataMessage ?: "")
                        ))
                        pendingResult = null
                    }
                }
            })

            log("  Registering verifyIdChipLauncher...")
            verifyIdChipLauncher.register(act, ResultHandler<LiquidChipVerificationResult> { data ->
                log("VerifyIdChip callback: ${data.resultStatus?.name}")
                handler.post {
                    pendingResult?.let { result ->
                        result.success(mapOf(
                            "resultStatus" to (data.resultStatus?.name ?: "UNKNOWN"),
                            "errorCode" to data.errorCode,
                            "additionalDataTitle" to (data.additionalDataTitle ?: ""),
                            "additionalDataMessage" to (data.additionalDataMessage ?: "")
                        ))
                        pendingResult = null
                    }
                }
            })
            log("  verifyIdChipLauncher registered")

            log("  Registering verifyFaceLauncher...")
            verifyFaceLauncher.register(act, ResultHandler<LiquidFaceVerificationResult> { data ->
                log("VerifyFace callback: ${data.resultStatus?.name}")
                handler.post {
                    pendingResult?.let { result ->
                        result.success(mapOf(
                            "resultStatus" to (data.resultStatus?.name ?: "UNKNOWN"),
                            "errorCode" to data.errorCode,
                            "additionalDataTitle" to (data.additionalDataTitle ?: ""),
                            "additionalDataMessage" to (data.additionalDataMessage ?: "")
                        ))
                        pendingResult = null
                    }
                }
            })
            log("  verifyFaceLauncher registered")

            launchersRegistered = true
            log("===========================================")
            log("ALL SDK launchers registered successfully!")
            log("  launchersRegistered: $launchersRegistered")
            log("===========================================")
            
            retryPendingLaunch()
            
        } catch (e: Exception) {
            log("ERROR registering launchers: ${e.message}")
            e.printStackTrace()
        }
    }
    
    fun retryPendingLaunch() {
        if (pendingResult == null || pendingLaunchType == null) {
            return
        }
        
        log("Retrying pending launch: $pendingLaunchType")
        
        when (pendingLaunchType) {
            "terms" -> {
                pendingLaunchType = null
                showTermsOfUseLauncher.launch(TermsOfUseSettings.Builder().build())
            }
            "document" -> {
                val params = pendingLaunchParams as? VerifyIdDocumentParameters
                pendingLaunchType = null
                pendingLaunchParams = null
                if (params != null) {
                    verifyIdDocumentLauncher.launch(params)
                }
            }
            "chip" -> {
                val params = pendingLaunchParams as? VerifyIdChipParameters
                pendingLaunchType = null
                pendingLaunchParams = null
                if (params != null) {
                    verifyIdChipLauncher.launch(params)
                }
            }
            "face" -> {
                val params = pendingLaunchParams as? VerifyFaceParameters
                pendingLaunchType = null
                pendingLaunchParams = null
                if (params != null) {
                    verifyFaceLauncher.launch(params)
                }
            }
        }
    }
    
    fun unregisterLaunchers() {
        try {
            showTermsOfUseLauncher.unregister()
            verifyIdDocumentLauncher.unregister()
            verifyIdChipLauncher.unregister()
            verifyFaceLauncher.unregister()
            launchersRegistered = false
            log("All launchers unregistered")
        } catch (e: Exception) {
            log("Error unregistering launchers: ${e.message}")
        }
    }
}