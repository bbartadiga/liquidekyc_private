package id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc

import asia.liquidinc.ekyc.applicant.external.LiquidDocumentType
import asia.liquidinc.ekyc.applicant.external.VerificationMethod
import asia.liquidinc.ekyc.applicant.external.VerifyIdDocumentParameters
import asia.liquidinc.ekyc.applicant.external.VerifyIdChipParameters
import asia.liquidinc.ekyc.applicant.external.VerifyFaceParameters
import asia.liquidinc.ekyc.applicant.external.result.LiquidChipVerificationResult
import asia.liquidinc.ekyc.applicant.external.result.auto.AutoVerificationFaceResultType
import asia.liquidinc.ekyc.applicant.external.result.chip.LiquidResidenceCardType
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

object VerificationHandler {
    /**
     * Map nilai documentType dari Dart ke enum Liquid SDK.
     *
     * PENTING: jangan pernah fallback diam-diam ke RESIDENCE_CARD.
     * Default fallback itu menyebabkan My Number Card dibaca sebagai Residence Card
     * (SDK jadi request /id_doc_photos/residence_card_ic & nampilin flow PIN,
     *  bukan flow input 個人番号 12 digit + 生年月日).
     */
    private fun toLiquidDocumentType(value: String): LiquidDocumentType? = when (value.uppercase()) {
        "RESIDENCE_CARD" -> LiquidDocumentType.RESIDENCE_CARD
        "SPECIAL_PERMANENT_RESIDENT_CERTIFICATE" -> LiquidDocumentType.SPECIAL_PERMANENT_RESIDENT_CERTIFICATE
        "DRIVER_LICENSE" -> LiquidDocumentType.DRIVER_LICENSE
        "MY_NUMBER_CARD" -> LiquidDocumentType.MY_NUMBER_CARD
        "MY_NUMBER_CARD_WITH_MY_NUMBER" -> LiquidDocumentType.MY_NUMBER_CARD_WITH_MY_NUMBER
        "MY_NUMBER_CARD_INTEGRATED_DRIVER_LICENSE" -> LiquidDocumentType.MY_NUMBER_CARD_INTEGRATED_DRIVER_LICENSE
        "RESIDENCE_DOCUMENT_GEN2" -> LiquidDocumentType.RESIDENCE_DOCUMENT_GEN2
        "SPECIFIED_RESIDENCE_CARD" -> LiquidDocumentType.SPECIFIED_RESIDENCE_CARD
        "SPECIFIED_SPECIAL_PERMANENT_RESIDENT_CERTIFICATE" -> LiquidDocumentType.SPECIFIED_SPECIAL_PERMANENT_RESIDENT_CERTIFICATE
        "PASSPORT" -> LiquidDocumentType.PASSPORT
        "PASSPORT_ALL_PERIODS" -> LiquidDocumentType.PASSPORT_ALL_PERIODS
        "NON_JAPANESE_PASSPORT" -> LiquidDocumentType.NON_JAPANESE_PASSPORT
        "DRIVING_HISTORY_CARD" -> LiquidDocumentType.DRIVING_HISTORY_CARD
        else -> null
    }

    private fun toVerificationMethod(value: String): VerificationMethod = when (value.uppercase()) {
        "COMPLY_HE" -> VerificationMethod.COMPLY_HE
        "COMPLY_HO" -> VerificationMethod.COMPLY_HO
        "COMPLY_TO" -> VerificationMethod.COMPLY_TO
        "COMPLY_CHI" -> VerificationMethod.COMPLY_CHI
        "READ" -> VerificationMethod.READ
        "READ_FACE" -> VerificationMethod.READ_FACE
        "READ_OFFLINE" -> VerificationMethod.READ_OFFLINE
        "FRONT" -> VerificationMethod.FRONT
        "FRONT_FACE" -> VerificationMethod.FRONT_FACE
        "FRONT_BACK" -> VerificationMethod.FRONT_BACK
        "FRONT_BACK_FACE" -> VerificationMethod.FRONT_BACK_FACE
        else -> VerificationMethod.COMPLY_HE
    }

    /**
     * Dokumen yang dibaca aktual dari chip, dibandingkan dengan yang diminta app.
     * RESIDENCE_DOCUMENT_GEN2 bersifat payung: SDK menerima 4 jenis kartu di bawahnya.
     */
    fun isActualDocumentTypeCompatible(requested: LiquidDocumentType, actual: LiquidDocumentType): Boolean {
        if (requested == actual) return true
        if (requested == LiquidDocumentType.RESIDENCE_DOCUMENT_GEN2) {
            return actual == LiquidDocumentType.RESIDENCE_CARD ||
                actual == LiquidDocumentType.SPECIAL_PERMANENT_RESIDENT_CERTIFICATE ||
                actual == LiquidDocumentType.RESIDENCE_DOCUMENT_GEN2
        }
        return false
    }

    /**
     * Mapping LiquidChipData -> Map untuk channel ke Dart.
     *(card_type memakai kode numeric yang sama dengan Connector API:
     *  1=在留カード 2=特別永住者証明書 5=第2世代在留 6=第2世代特別永住 7=特定在留 8=特定特別永住)
     */
    fun buildChipDataMap(result: LiquidChipVerificationResult): Map<String, Any?>? {
        val chip = result.liquidChipData ?: return null
        val map = mutableMapOf<String, Any?>()

        chip.name?.let { map["name"] = it }
        chip.nameKana?.let { map["nameKana"] = it }
        chip.birthday?.let { map["birthday"] = it }
        chip.sex?.let { map["sex"] = it.name }
        chip.address?.let { map["address"] = it }
        chip.addressPref?.let { map["addressPref"] = it }
        chip.addressCity?.let { map["addressCity"] = it }
        chip.addressOther?.let { map["addressOther"] = it }
        chip.zipCode?.let { map["zipCode"] = it }
        chip.idNumber?.let { map["idNumber"] = it }
        chip.issueDate?.let { map["issueDate"] = it }
        chip.expireDate?.let { map["expireDate"] = it }
        chip.myNumber?.let { map["myNumber"] = it }
        chip.liquidDocumentType?.let { map["liquidDocumentType"] = it.name }
        chip.liquidResidenceCardType?.let {
            map["residenceCardType"] = residenceCardTypeCode(it)
            map["residenceCardTypeEnum"] = it.name
        }
        chip.liquidResidenceCardInfoType?.let { map["residenceCardInfoType"] = it.name }
        chip.driversLicenseTypes?.let { map["driversLicenseTypes"] = it }
        chip.driversLicenseConditions?.let { map["driversLicenseConditions"] = it }
        chip.driversLicenseAcquisitionDates?.let { map["driversLicenseAcquisitionDates"] = it }
        chip.residenceCardComprehensivePermission?.let { map["residenceCardComprehensivePermission"] = it }
        chip.residenceCardIndividualPermission?.let { map["residenceCardIndividualPermission"] = it }
        if (chip.idFacePhoto != null) map["hasIdFacePhoto"] = true
        if (chip.nameImage != null) map["hasDocumentFrontImage"] = true

        return map
    }

    private fun residenceCardTypeCode(type: LiquidResidenceCardType): String = when (type) {
        LiquidResidenceCardType.RESIDENCE_CARD -> "1"
        LiquidResidenceCardType.SPECIAL_PERMANENT_RESIDENT_CERTIFICATE -> "2"
        LiquidResidenceCardType.RESIDENCE_CARD_GEN2 -> "5"
        LiquidResidenceCardType.SPECIAL_PERMANENT_RESIDENT_CERTIFICATE_GEN2 -> "6"
        LiquidResidenceCardType.SPECIFIED_RESIDENCE_CARD -> "7"
        LiquidResidenceCardType.SPECIFIED_SPECIAL_PERMANENT_RESIDENT_CERTIFICATE -> "8"
        else -> "0"
    }

    fun buildAutoVerificationMap(result: LiquidChipVerificationResult): Map<String, Any?>? {
        val auto = result.autoVerificationResult ?: return null
        val face = auto.autoVerificationFace
        val photo = auto.autoVerificationFacePhoto
        val passive = auto.autoVerificationFacePassive

        val map = mutableMapOf<String, Any?>()
        map["result"] = when (face?.resultType) {
            AutoVerificationFaceResultType.SAME -> "PASS"
            AutoVerificationFaceResultType.NOT_EQUAL -> "FAIL"
            else -> "NOT_APPLICABLE"
        }
        face?.let {
            map["faceResult"] = it.resultType.name
            map["faceScore"] = it.score
        }
        photo?.let {
            map["photoResult"] = it.resultType.name
            map["photoScore"] = it.score
        }
        passive?.let { map["passiveResult"] = it.result }

        val message = buildString {
            face?.let { append("face=${it.resultType}(${it.score}) ") }
            photo?.let { append("photo=${it.resultType}(${it.score}) ") }
            passive?.let { append("passive=$it") }
        }.trim()
        map["message"] = message

        return map
    }

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

        val documentType = toLiquidDocumentType(documentTypeStr)
        if (documentType == null) {
            SdkManager.log("[STEP 12] ERROR unknown documentType: $documentTypeStr")
            result.error("INVALID_DOCUMENT_TYPE", "Unknown documentType: $documentTypeStr", null)
            return
        }
        val verificationMethod = toVerificationMethod(verificationMethodStr)

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
        val verificationMethodStr = call.argument<String>("verificationMethod") ?: "COMPLY_HE"
        val showReviewScreen = call.argument<Boolean>("showReviewScreen") ?: true

        SdkManager.log("  documentType: $documentTypeStr")
        SdkManager.log("  verificationMethod: $verificationMethodStr")
        SdkManager.log("  showReviewScreen: $showReviewScreen")

        val documentType = toLiquidDocumentType(documentTypeStr)
        if (documentType == null) {
            SdkManager.log("[STEP 11] ERROR unknown documentType: $documentTypeStr")
            result.error("INVALID_DOCUMENT_TYPE", "Unknown documentType: $documentTypeStr", null)
            return
        }
        val verificationMethod = toVerificationMethod(verificationMethodStr)

        SdkManager.log("  -> LiquidDocumentType: ${documentType.name}, VerificationMethod: ${verificationMethod.name}")

        val params = VerifyIdChipParameters.Builder(documentType, verificationMethod)
            .setShowReviewScreen(showReviewScreen).build()

        if (!SdkManager.launchersRegistered) {
            SdkManager.log("Launchers not yet registered, queuing chip launch...")
            SdkManager.pendingResult = result
            SdkManager.pendingLaunchType = "chip"
            SdkManager.pendingLaunchParams = params
            SdkManager.pendingRequestedDocumentType = documentType
            return
        }

        SdkManager.pendingResult = result
        SdkManager.pendingRequestedDocumentType = documentType
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