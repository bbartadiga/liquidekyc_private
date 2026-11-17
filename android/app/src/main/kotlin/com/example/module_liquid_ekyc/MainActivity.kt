package com.example.module_liquid_ekyc

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc.LiquidEkycPlugin())
    }
}