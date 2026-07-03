package com.example.poc_liquidekyc_flutter.plugins

import android.app.Activity
import androidx.activity.ComponentActivity
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall

class LiquidEkycPlugin : FlutterPlugin, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    companion object {
        const val TAG = "LiquidEkycPlugin"
    }

    private fun log(msg: String) {
        android.util.Log.d(TAG, msg)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        log("onAttachedToEngine - DEBUG_MODE: $DEBUG_MODE")
        channel = MethodChannel(binding.binaryMessenger, SdkConfig.CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
            log("Method call: ${call.method}")
            handleMethodCall(call, result)
        }
        SdkManager.init(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        log("onDetachedFromEngine")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        log("onAttachedToActivity")
        activity = binding.activity

        if (!DEBUG_MODE) {
            val act = binding.activity as? ComponentActivity
            if (act != null) {
                SdkManager.setActivity(act)
                
                val lifecycleState = act.lifecycle.currentState
                log("Current lifecycle state: $lifecycleState")
                
                // Check current lifecycle state
                // SDK requires registration BEFORE STARTED (CREATED or INITIALIZED)
                when (lifecycleState) {
                    androidx.lifecycle.Lifecycle.State.CREATED,
                    androidx.lifecycle.Lifecycle.State.INITIALIZED -> {
                        // Safe to register now
                        log("Lifecycle is CREATED/INITIALIZED - registering launchers")
                        SdkManager.registerLaunchers(act)
                    }
                    else -> {
                        // Activity is past STARTED, register when lifecycle allows
                        log("Activity is past STARTED - will register on next lifecycle event")
                        act.lifecycle.addObserver(object : DefaultLifecycleObserver {
                            override fun onCreate(owner: LifecycleOwner) {
                                // Only register if we haven't registered yet
                                if (!SdkManager.launchersRegistered) {
                                    log("Lifecycle ON_CREATE - registering SDK launchers (deferred)")
                                    SdkManager.registerLaunchers(act)
                                }
                                act.lifecycle.removeObserver(this)
                            }
                        })
                    }
                }
            }
        }
    }

    override fun onDetachedFromActivity() {
        log("onDetachedFromActivity")
        activity = null
        SdkManager.pendingResult?.error("CANCELLED", "Activity detached", null)
        SdkManager.clearActivity()
        SdkManager.clearPending()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        log("onReattachedToActivityForConfigChanges")
        activity = binding.activity
        
        if (!DEBUG_MODE) {
            val act = binding.activity as? ComponentActivity
            if (act != null) {
                SdkManager.setActivity(act)
                act.lifecycle.addObserver(object : DefaultLifecycleObserver {
                    override fun onCreate(owner: LifecycleOwner) {
                        log("Re-registration after config change - ON_CREATE")
                        SdkManager.registerLaunchers(act)
                        act.lifecycle.removeObserver(this)
                    }
                })
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        log("onDetachedFromActivityForConfigChanges")
        activity = null
        SdkManager.unregisterLaunchers()
    }
    
    private fun handleMethodCall(call: MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        when (call.method) {
            "startVerify" -> InitHandler.handleStartVerify(call, result)
            "startVerifyTrial" -> InitHandler.handleStartVerifyTrial(call, result)
            "showTermsOfUse" -> TermsHandler.handleShowTermsOfUse(result)
            "verifyIdDocument" -> VerificationHandler.handleVerifyIdDocument(call, result)
            "verifyIdChip" -> VerificationHandler.handleVerifyIdChip(call, result)
            "verifyFace" -> VerificationHandler.handleVerifyFace(call, result)
            "activate" -> FinalizeHandler.handleActivate(result)
            "customizeDesign" -> FinalizeHandler.handleCustomizeDesign(result)
            "changeLanguage" -> FinalizeHandler.handleChangeLanguage(result)
            "getSdkVersion" -> result.success(FinalizeHandler.getSdkVersion())
            "isNfcAvailable" -> result.success(FinalizeHandler.isNfcAvailable())
            "getOcrResults" -> FinalizeHandler.handleGetOcrResults(result)
            else -> result.notImplemented()
        }
    }
}