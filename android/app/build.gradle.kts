plugins {
	id("com.android.application")
	id("kotlin-android")
	// The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
	id("dev.flutter.flutter-gradle-plugin")
	id("com.github.triplet.play") version "3.12.1"
}

import com.github.triplet.gradle.androidpublisher.ReleaseStatus
import java.util.Properties

android {
    // Signing properties from key.properties
    val propertiesFile = project.rootProject.file("key.properties")
    val properties = Properties()
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use { properties.load(it) } // Correct Kotlin DSL
    }

    namespace = "com.nextalarm.next_alarm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion // Correctly placed

    signingConfigs {
        create("release") {
            storeFile = file(properties.getProperty("storeFile"))
            storePassword = properties.getProperty("storePassword")
            keyAlias = properties.getProperty("keyAlias")
            keyPassword = properties.getProperty("keyPassword")
        }
    }

	compileOptions {
		sourceCompatibility = JavaVersion.VERSION_17
		targetCompatibility = JavaVersion.VERSION_17
		isCoreLibraryDesugaringEnabled = true
	}

	kotlinOptions {
		jvmTarget = JavaVersion.VERSION_17.toString()
	}

	defaultConfig {
		applicationId = "com.nextalarm.next_alarm"
		minSdk = flutter.minSdkVersion
		targetSdk = flutter.targetSdkVersion
		versionCode = flutter.versionCode
		versionName = flutter.versionName
	}

	buildTypes {
		        release {
		            signingConfig = signingConfigs.getByName("release")
		        }	}
}

flutter {
	source = "../.."
}

dependencies {
	coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

play {
	// Path to Google Play service account JSON credentials.
	// Prefer setting PLAY_SERVICE_ACCOUNT_JSON for local/CI safety.
	val serviceAccountPath = providers
		.environmentVariable("PLAY_SERVICE_ACCOUNT_JSON")
		.orElse("${rootDir}/play-service-account.json")
		.get()
	serviceAccountCredentials.set(file(serviceAccountPath))

	// Default upload track is internal unless overridden by PLAY_TRACK.
	track.set(providers.environmentVariable("PLAY_TRACK").orElse("internal"))
	releaseStatus.set(ReleaseStatus.COMPLETED)
	defaultToAppBundles.set(true)
}
