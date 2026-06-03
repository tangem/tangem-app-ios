//
//  TangemFirebaseDynamicShim.swift
//  TangemFirebaseDynamicShim
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// Currently, Firebase does not support dynamic libraries when installed via SPM, see https://github.com/firebase/firebase-ios-sdk/issues/8945 for details.
// In order to use Firebase in both the app target and the `TangemAnalytics` module we need to use this thin dynamic shim library.
@_exported import FirebaseAnalytics
@_exported import FirebaseCore
@_exported import FirebaseCrashlytics
@_exported import FirebaseMessaging
@_exported import FirebasePerformance
