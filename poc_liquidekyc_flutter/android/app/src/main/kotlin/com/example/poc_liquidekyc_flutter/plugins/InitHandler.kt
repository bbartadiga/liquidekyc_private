package com.example.poc_liquidekyc_flutter.plugins

import asia.liquidinc.ekyc.applicant.LiquidSdk
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

val DEBUG_MODE = false

object InitHandler {
    fun handleStartVerify(call: MethodCall, result: Result) {
        SdkManager.log("[STEP 8] InitHandler.handleStartVerify() called")
        SdkManager.log("  call.method: ${call.method}")

        if (DEBUG_MODE) {
            SdkManager.log("[STEP 9] DEBUG_MODE - returning mock success")
            result.success(mapOf(
                "success" to true,
                "resultStatus" to "SUCCESS",
                "additionalDataTitle" to "DEBUG",
                "additionalDataMessage" to "SDK initialized (DEBUG)"
            ))
            return
        }

        val url = call.argument<String>("url") ?: ""
        val applicantId = call.argument<String>("applicantId") ?: ""
        val token = call.argument<String>("token") ?: ""

        SdkManager.log("[STEP 9] Native Plugin received credentials:")
        SdkManager.log("  - url: $url")
        SdkManager.log("  - applicantId: $applicantId")
        SdkManager.log("  - token length: ${token.length}")

        if (url.isEmpty() || applicantId.isEmpty() || token.isEmpty()) {
            SdkManager.log("ERROR: Missing required credentials!")
            result.error("INVALID_CREDENTIALS", "url, applicantId, token required", null)
            return
        }

        SdkManager.log("[STEP 9] Saving credentials to SdkManager...")
        SdkManager.sdkUrl = url
        SdkManager.sdkApplicantId = applicantId
        SdkManager.sdkToken = token
        SdkManager.isInitialized = true

        SdkManager.log("[STEP 9] ===========================================")
        SdkManager.log("[STEP 9] Initializing Liquid SDK with credentials...")
        SdkManager.log("[STEP 9] Calling LiquidSdk.getInstance().startVerify()")
        SdkManager.log("[STEP 9]   url: $url")
        SdkManager.log("[STEP 9]   applicantId: $applicantId")
        SdkManager.log("[STEP 9]   token length: ${token.length}")
        SdkManager.log("[STEP 9] ===========================================")

        try {
            val ctx = SdkManager.getContext()
            if (ctx != null) {
                SdkManager.log("[STEP 9] Calling LiquidSdk.getInstance().startVerify(url, applicantId, token)")
                LiquidSdk.getInstance(ctx).startVerify(url, applicantId, token)
                SdkManager.log("[STEP 9] LiquidSdk.startVerify() called successfully - no callback for production mode")
            } else {
                SdkManager.log("[STEP 9] ERROR: context is null, cannot initialize SDK")
                result.success(mapOf(
                    "resultStatus" to "ERROR",
                    "errorCode" to "SE90002",
                    "additionalDataTitle" to "Context Null",
                    "additionalDataMessage" to "Cannot initialize SDK: context is null"
                ))
                return
            }
        } catch (e: Exception) {
            SdkManager.log("[STEP 9] ERROR initializing SDK: ${e.message}")
            SdkManager.log("[STEP 9] ERROR cause: ${e.cause?.message ?: "unknown"}")
            e.printStackTrace()
            result.success(mapOf(
                "resultStatus" to "ERROR",
                "errorCode" to "SE90001",
                "additionalDataTitle" to "SDK Init Error",
                "additionalDataMessage" to "Failed to initialize SDK: ${e.message}"
            ))
            return
        }

        SdkManager.log("[STEP 9] SDK initialization completed.")
        SdkManager.log("[STEP 9] Launchers will be registered by onAttachedToActivity lifecycle.")
        
        // DON'T re-register here - it will fail if activity is already RESUMED
        // Launchers are registered in onAttachedToActivity when lifecycle allows
        if (SdkManager.launchersRegistered) {
            SdkManager.log("[STEP 9] Launchers already registered - OK")
        } else {
            SdkManager.log("[STEP 9] Launchers will be registered when activity lifecycle allows")
        }

        result.success(mapOf(
            "success" to true,
            "resultStatus" to "SUCCESS",
            "additionalDataTitle" to "SDK Initialized",
            "additionalDataMessage" to "Liquid SDK initialized with credentials for $applicantId"
        ))
    }
    
    fun handleStartVerifyTrial(call: MethodCall, result: Result) {
        SdkManager.log("InitHandler.handleStartVerifyTrial() - TRIAL MODE")

        if (DEBUG_MODE) {
            result.success(mapOf(
                "success" to true,
                "resultStatus" to "SUCCESS"
            ))
            return
        }

        val url = call.argument<String>("url") ?: ""
        val apiKey = call.argument<String>("apiKey") ?: ""

        if (url.isEmpty() || apiKey.isEmpty()) {
            result.error("INVALID_CREDENTIALS", "url and apiKey required", null)
            return
        }

        SdkManager.log("[TRIAL] Initializing SDK with API Key...")
        SdkManager.log("[TRIAL] url: $url")
        SdkManager.log("[TRIAL] apiKey length: ${apiKey.length}")

        try {
            val ctx = SdkManager.getContext()
            if (ctx != null) {
                LiquidSdk.getInstance(ctx).startVerify(url, apiKey) { initResult ->
                    SdkManager.log("[TRIAL] LiquidSdk.init callback: ${initResult.result?.name}")
                }
                SdkManager.log("[TRIAL] LiquidSdk.startVerify() called successfully")
            }
        } catch (e: Exception) {
            SdkManager.log("[TRIAL] ERROR: ${e.message}")
        }

        SdkManager.sdkUrl = url
        SdkManager.sdkApiKey = apiKey
        SdkManager.isInitialized = true

        result.success(mapOf(
            "success" to true,
            "resultStatus" to "SUCCESS"
        ))
    }
}