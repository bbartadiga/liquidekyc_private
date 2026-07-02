package com.example.poc_liquidekyc_flutter.plugins

import asia.liquidinc.ekyc.applicant.external.LiquidDocumentType
import asia.liquidinc.ekyc.applicant.external.VerificationMethod
import asia.liquidinc.ekyc.applicant.external.VerifyIdDocumentParameters
import asia.liquidinc.ekyc.applicant.external.VerifyIdChipParameters
import asia.liquidinc.ekyc.applicant.external.VerifyFaceParameters
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

object VerificationHandler {
    fun handleVerifyIdDocument(call: MethodCall, result: Result) {
        SdkManager.log("[STEP 12] VerificationHandler.handleVerifyIdDocument() called")

        if (DEBUG_MODE) {
            SdkManager.log("[STEP 12] DEBUG_MODE - returning mock document success")
            result.success(mapOf(
                "resultStatus" to "SUCCESS",
                "autoVerificationResult" to mapOf("result" to "PASS")
            ))
            return
        }

        val documentTypeStr = call.argument<String>("documentType") ?: "RESIDENCE_CARD"
        val verificationMethodStr = call.argument<String>("verificationMethod") ?: "COMPLY_HE"
        val showReviewScreen = call.argument<Boolean>("showReviewScreen") ?: true

        SdkManager.log("  documentType: $documentTypeStr")
        SdkManager.log("  verificationMethod: $verificationMethodStr")
        SdkManager.log("  showReviewScreen: $showReviewScreen")

        val documentType = when (documentTypeStr.uppercase()) {
            "RESIDENCE_CARD" -> LiquidDocumentType.RESIDENCE_CARD
            "DRIVER_LICENSE" -> LiquidDocumentType.DRIVER_LICENSE
            else -> LiquidDocumentType.RESIDENCE_CARD
        }
        val verificationMethod = when (verificationMethodStr.uppercase()) {
            "COMPLY_HE" -> VerificationMethod.COMPLY_HE
            "COMPLY_HO" -> VerificationMethod.COMPLY_HO
            else -> VerificationMethod.COMPLY_HE
        }

        val params = VerifyIdDocumentParameters.Builder(documentType, verificationMethod)
            .setShowReviewScreen(showReviewScreen).build()

        if (!SdkManager.launchersRegistered) {
            SdkManager.log("Launchers not yet registered, queuing document launch...")
            SdkManager.pendingResult = result
            SdkManager.pendingLaunchType = "document"
            SdkManager.pendingLaunchParams = params
            return
        }

        SdkManager.pendingResult = result
        SdkManager.log("[STEP 12] Launching verifyIdDocument...")
        SdkManager.verifyIdDocumentLauncher.launch(params)
    }
    
    fun handleVerifyIdChip(call: MethodCall, result: Result) {
        SdkManager.log("[STEP 11] VerificationHandler.handleVerifyIdChip() called")

        if (DEBUG_MODE) {
            SdkManager.log("[STEP 11] DEBUG_MODE - returning mock chip success")
            result.success(mapOf(
                "resultStatus" to "SUCCESS",
                "autoVerificationResult" to mapOf("result" to "PASS")
            ))
            return
        }

        val documentTypeStr = call.argument<String>("documentType") ?: "RESIDENCE_CARD"
        val showReviewScreen = call.argument<Boolean>("showReviewScreen") ?: true

        SdkManager.log("  documentType: $documentTypeStr")
        SdkManager.log("  showReviewScreen: $showReviewScreen")

        val documentType = when (documentTypeStr.uppercase()) {
            "RESIDENCE_CARD" -> LiquidDocumentType.RESIDENCE_CARD
            "DRIVER_LICENSE" -> LiquidDocumentType.DRIVER_LICENSE
            else -> LiquidDocumentType.RESIDENCE_CARD
        }

        val params = VerifyIdChipParameters.Builder(documentType, VerificationMethod.COMPLY_HE)
            .setShowReviewScreen(showReviewScreen).build()

        if (!SdkManager.launchersRegistered) {
            SdkManager.log("Launchers not yet registered, queuing chip launch...")
            SdkManager.pendingResult = result
            SdkManager.pendingLaunchType = "chip"
            SdkManager.pendingLaunchParams = params
            return
        }

        SdkManager.pendingResult = result
        SdkManager.log("[STEP 11] Launching verifyIdChip...")
        SdkManager.verifyIdChipLauncher.launch(params)
    }
    
    fun handleVerifyFace(call: MethodCall, result: Result) {
        SdkManager.log("[STEP 13] VerificationHandler.handleVerifyFace() called")

        if (DEBUG_MODE) {
            SdkManager.log("[STEP 13] DEBUG_MODE - returning mock face success")
            result.success(mapOf(
                "resultStatus" to "SUCCESS",
                "livenessResult" to "PASS",
                "matchScore" to 850
            ))
            return
        }

        val showReviewScreen = call.argument<Boolean>("showReviewScreen") ?: true

        SdkManager.log("  showReviewScreen: $showReviewScreen")

        val params = VerifyFaceParameters.Builder()
            .setShowReviewScreen(showReviewScreen).build()

        if (!SdkManager.launchersRegistered) {
            SdkManager.log("Launchers not yet registered, queuing face launch...")
            SdkManager.pendingResult = result
            SdkManager.pendingLaunchType = "face"
            SdkManager.pendingLaunchParams = params
            return
        }

        SdkManager.pendingResult = result
        SdkManager.log("[STEP 13] Launching verifyFace...")
        SdkManager.verifyFaceLauncher.launch(params)
    }
}