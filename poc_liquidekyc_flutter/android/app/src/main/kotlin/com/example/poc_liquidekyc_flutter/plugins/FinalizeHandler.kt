package com.example.poc_liquidekyc_flutter.plugins

import asia.liquidinc.ekyc.applicant.LiquidSdk
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

object FinalizeHandler {
    fun handleActivate(result: Result) {
        SdkManager.log("===========================================")
        SdkManager.log("[FINAL] FinalizeHandler.handleActivate() called")
        SdkManager.log("  SDK initialized: ${SdkManager.isInitialized}")
        SdkManager.log("  SDK url: ${SdkManager.sdkUrl}")
        SdkManager.log("===========================================")

        if (DEBUG_MODE) {
            SdkManager.log("[FINAL] DEBUG_MODE - returning mock success")
            result.success(mapOf(
                "resultStatus" to "SUCCESS",
                "additionalDataTitle" to "DEBUG",
                "additionalDataMessage" to "Activation completed (DEBUG)"
            ))
            return
        }

        if (!SdkManager.isInitialized) {
            SdkManager.log("[FINAL] ERROR: SDK not initialized!")
            result.success(mapOf(
                "resultStatus" to "ERROR",
                "errorCode" to "SE90002",
                "additionalDataTitle" to "Not Initialized",
                "additionalDataMessage" to "startVerify() belum dipanggil"
            ))
            return
        }

        SdkManager.log("[FINAL] Calling LiquidSdk.getInstance().activate()...")
        try {
            val ctx = SdkManager.getContext()
            if (ctx != null) {
                LiquidSdk.getInstance(ctx).activate() { activateResult ->
                    SdkManager.log("[FINAL] Activate callback: ${activateResult.result?.name}, error: ${activateResult.errorCode}")
                    SdkManager.handler.post {
                        result.success(mapOf(
                            "resultStatus" to (activateResult.result?.name ?: "UNKNOWN"),
                            "errorCode" to activateResult.errorCode,
                            "additionalDataTitle" to (activateResult.additionalDataTitle ?: ""),
                            "additionalDataMessage" to (activateResult.additionalDataMessage ?: "")
                        ))
                    }
                }
                SdkManager.log("[FINAL] Activate request sent")
            } else {
                result.success(mapOf(
                    "resultStatus" to "ERROR",
                    "errorCode" to "SE90002",
                    "additionalDataTitle" to "Context Null",
                    "additionalDataMessage" to "Cannot activate: context is null"
                ))
            }
        } catch (e: Exception) {
            SdkManager.log("[FINAL] ERROR: ${e.message}")
            e.printStackTrace()
            result.success(mapOf(
                "resultStatus" to "ERROR",
                "errorCode" to "SE90001",
                "additionalDataTitle" to "Activation Error",
                "additionalDataMessage" to "Failed to activate: ${e.message}"
            ))
        }
    }
    
    fun handleCustomizeDesign(result: Result) {
        SdkManager.log("FinalizeHandler.handleCustomizeDesign()")
        result.success(mapOf("status" to "configured"))
    }
    
    fun handleChangeLanguage(result: Result) {
        SdkManager.log("FinalizeHandler.handleChangeLanguage()")
        result.success(mapOf("status" to "changed"))
    }
    
    fun getSdkVersion(): String {
        SdkManager.log("FinalizeHandler.getSdkVersion()")
        return "1.47.0"
    }
    
    fun isNfcAvailable(): Boolean {
        val ctx = SdkManager.getContext() ?: return false
        return ctx.packageManager.hasSystemFeature("android.hardware.nfc")
    }
}