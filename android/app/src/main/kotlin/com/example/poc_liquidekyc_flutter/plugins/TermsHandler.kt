package com.example.poc_liquidekyc_flutter.plugins

import asia.liquidinc.ekyc.applicant.external.TermsOfUseSettings
import io.flutter.plugin.common.MethodChannel.Result

object TermsHandler {
    fun handleShowTermsOfUse(result: Result) {
        SdkManager.log("===========================================")
        SdkManager.log("[STEP 10] TermsHandler.handleShowTermsOfUse() called")
        SdkManager.log("  - sdkUrl: ${SdkManager.sdkUrl} (empty: ${SdkManager.sdkUrl.isEmpty()})")
        SdkManager.log("  - applicantId: ${SdkManager.sdkApplicantId} (empty: ${SdkManager.sdkApplicantId.isEmpty()})")
        SdkManager.log("  - token length: ${SdkManager.sdkToken.length} (empty: ${SdkManager.sdkToken.isEmpty()})")
        SdkManager.log("  - isInitialized: ${SdkManager.isInitialized}")
        SdkManager.log("  - launchersRegistered: ${SdkManager.launchersRegistered}")
        SdkManager.log("===========================================")

        if (DEBUG_MODE) {
            SdkManager.log("[STEP 10] DEBUG_MODE - returning mock terms accepted")
            result.success(mapOf(
                "resultStatus" to "SUCCESS",
                "additionalDataTitle" to "DEBUG",
                "additionalDataMessage" to "Terms accepted (DEBUG)"
            ))
            return
        }

        if (!SdkManager.isInitialized || SdkManager.sdkToken.isEmpty()) {
            SdkManager.log("ERROR: SDK not initialized with credentials!")
            SdkManager.log("  - isInitialized: ${SdkManager.isInitialized}")
            SdkManager.log("  - sdkToken isEmpty: ${SdkManager.sdkToken.isEmpty()}")
            result.success(mapOf(
                "resultStatus" to "ERROR",
                "errorCode" to "SE90002",
                "additionalDataTitle" to "Not Initialized",
                "additionalDataMessage" to "startVerify() belum dipanggil. Panggil startVerify() terlebih dahulu sebelum showTermsOfUse()."
            ))
            return
        }

        if (!SdkManager.launchersRegistered) {
            SdkManager.log("Launchers not yet registered, attempting registration...")
            
            val activity = SdkManager.getCurrentActivity()
            if (activity != null && !SdkManager.launchersRegistered) {
                try {
                    SdkManager.registerLaunchers(activity)
                } catch (e: Exception) {
                    SdkManager.log("Retry registration failed: ${e.message}")
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        if (!SdkManager.launchersRegistered) {
                            val act = SdkManager.getCurrentActivity()
                            if (act != null) {
                                try {
                                    SdkManager.log("Deferred registration attempt...")
                                    SdkManager.registerLaunchers(act)
                                    SdkManager.log("Deferred registration succeeded!")
                                } catch (e2: Exception) {
                                    SdkManager.log("Deferred registration also failed: ${e2.message}")
                                }
                            }
                        }
                    }, 500)
                }
            }
            
            if (SdkManager.launchersRegistered) {
                SdkManager.log("Registration succeeded on retry!")
            } else {
                SdkManager.log("Registration failed - returning error for Flutter to handle")
                result.success(mapOf(
                    "resultStatus" to "ERROR",
                    "errorCode" to "SE90001",
                    "additionalDataTitle" to "Registration Pending",
                    "additionalDataMessage" to "SDK launcher registration is pending. Please retry in a moment."
                ))
                return
            }
        }

        try {
            SdkManager.pendingResult = result
            SdkManager.log("[STEP 10] Calling showTermsOfUseLauncher.launch()")
            SdkManager.log("  - SDK will use credentials: applicantId=${SdkManager.sdkApplicantId}")
            SdkManager.showTermsOfUseLauncher.launch(TermsOfUseSettings.Builder().build())
            SdkManager.log("[STEP 10] TermsOfUse launcher invoked - waiting for callback")
        } catch (e: Exception) {
            SdkManager.log("ERROR launching TermsOfUse: ${e.message}")
            SdkManager.log("ERROR cause: ${e.cause?.message ?: "unknown"}")
            SdkManager.log("ERROR stacktrace:")
            e.printStackTrace()
            result.success(mapOf(
                "resultStatus" to "ERROR",
                "errorCode" to "SE90001",
                "additionalDataTitle" to "Implementation Error",
                "additionalDataMessage" to "Gagal membuka Terms screen: ${e.message}"
            ))
        }
    }
}