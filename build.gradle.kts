// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
}
android {
    defaultConfig {
        // ... other settings
        multiDexEnabled true 
    }

   compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}

    kotlinOptions {
        jvmTarget = '1.8'
    }
}
dependencies {
    // Try version 2.1.5 or 2.1.4, which handle modern JDK 17/21 better
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.5'
}