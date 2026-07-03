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

    fun handleGetOcrResults(result: Result) {
        SdkManager.log("FinalizeHandler.handleGetOcrResults() called - ASYNC CALLBACK")
        SdkManager.log("  SDK initialized: ${SdkManager.isInitialized}")

        if (DEBUG_MODE) {
            SdkManager.log("DEBUG_MODE - returning mock OCR")
            result.success(mapOf(
                "status" to "SUCCESS",
                "errorCode" to null,
                "ocr" to mapOf(
                    "name" to "Demo User (DEBUG)",
                    "birthday" to "1990-01-01",
                    "sex" to "1",
                    "address" to "123 Demo Street",
                    "expireDate" to "2030-01-01",
                    "idNumber" to "DM123456789",
                    "issueDate" to "2020-01-01",
                    "nationality" to "Japan",
                    "residentStatus" to "Permanent Resident"
                )
            ))
            return
        }

        if (!SdkManager.isInitialized) {
            SdkManager.log("ERROR: SDK not initialized!")
            result.success(mapOf("status" to "ERROR", "errorCode" to "SE90002"))
            return
        }

        SdkManager.log("Calling LiquidSdk.getInstance().getOcrResults() with callback...")
        try {
            val ctx = SdkManager.getContext()
            if (ctx != null) {
                LiquidSdk.getInstance(ctx).getOcrResults { ocrResult ->
                    SdkManager.log("getOcrResults callback received: ${ocrResult?.javaClass?.simpleName ?: "null"}")
                    SdkManager.handler.post {
                        if (ocrResult != null && ocrResult.ocr != null) {
                            SdkManager.log("Processing OCR data...")
                            val ocr = ocrResult.ocr
                            val ocrMap = mutableMapOf<String, Any?>()
                            
                            ocr.name?.let { ocrMap["name"] = it }
                            ocr.birthday?.let { ocrMap["birthday"] = it }
                            ocr.sex?.let { ocrMap["sex"] = it }
                            ocr.address?.let { ocrMap["address"] = it }
                            ocr.addressPref?.let { ocrMap["addressPref"] = it }
                            ocr.addressCity?.let { ocrMap["addressCity"] = it }
                            ocr.addressOther?.let { ocrMap["addressOther"] = it }
                            ocr.zipCode?.let { ocrMap["zipCode"] = it }
                            ocr.expireDate?.let { ocrMap["expireDate"] = it }
                            ocr.idNumber?.let { ocrMap["idNumber"] = it }
                            ocr.issueDate?.let { ocrMap["issueDate"] = it }
                            ocr.nationality?.let { ocrMap["nationality"] = it }
                            ocr.residentStatus?.let { ocrMap["residentStatus"] = it }
                            ocr.stayPeriod?.let { ocrMap["stayPeriod"] = it }
                            ocr.stayExpireDate?.let { ocrMap["stayExpireDate"] = it }
                            ocr.issuingAuthority?.let { ocrMap["issuingAuthority"] = it }
                            ocr.addressChanged?.let { ocrMap["addressChanged"] = it }
                            ocr.nameChanged?.let { ocrMap["nameChanged"] = it }
                            ocr.remarksExist?.let { ocrMap["remarksExist"] = it }
                            ocr.employmentRestriction?.let { ocrMap["employmentRestriction"] = it }
                            ocr.permittedDate?.let { ocrMap["permittedDate"] = it }
                            ocr.kindOfPermission?.let { ocrMap["kindOfPermission"] = it }

                            result.success(mapOf(
                                "status" to ocrResult.resultStatus.name,
                                "errorCode" to ocrResult.errorCode,
                                "additionalDataTitle" to (ocrResult.additionalDataTitle ?: ""),
                                "additionalDataMessage" to (ocrResult.additionalDataMessage ?: ""),
                                "ocr" to ocrMap
                            ))
                        } else {
                            SdkManager.log("getOcrResults: ocr is null")
                            result.success(mapOf(
                                "status" to (ocrResult?.resultStatus?.name ?: "ERROR"),
                                "errorCode" to (ocrResult?.errorCode ?: "SE90003")
                            ))
                        }
                    }
                }
                SdkManager.log("getOcrResults request sent (waiting for callback)")
            } else {
                SdkManager.log("ERROR: Context is null")
                result.success(mapOf("status" to "ERROR", "errorCode" to "SE90002"))
            }
        } catch (e: Exception) {
            SdkManager.log("ERROR: ${e.message}")
            e.printStackTrace()
            result.success(mapOf("status" to "ERROR", "errorCode" to "SE90001", "message" to e.message))
        }
    }
}