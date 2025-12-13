package com.attoexa.gravityapp

import android.app.Activity
import android.os.Bundle

class PermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // This activity is required by Health Connect for Android 13 and below
        // It explains to users why the app needs health data permissions
        // The health package will handle showing the actual permission dialog
        finish()
    }
}

