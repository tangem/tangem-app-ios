//
//  AppGroupSharedStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Single source of truth for values exchanged between the main app and the Notification Service
/// Extension through their shared App Group.
///
/// This file is a member of **both** the `Tangem` and `TangemNotificationServiceExtension` targets, so
/// every storage key and accessor is defined exactly once and stays in sync across the process
/// boundary. Each shared value is exposed as a typed property — call sites never reference the raw key.
///
/// The App Group identifier is read straight from the running bundle's `Info.plist` `SUITE_NAME` key.
/// We deliberately avoid `TangemFoundation.InfoDictionaryUtils` here: the extension would otherwise have
/// to link the `TangemModules` umbrella (BlockchainSdk, WalletCore, …) and blow the NSE memory limit.
/// `InfoDictionaryUtils` reads the very same key, so the behavior is identical. Both targets inherit the
/// host's build-variant `SUITE_NAME`, so they always resolve the same container per variant.
enum AppGroupSharedStorage {
    /// Customer.io CDP API key. The app bundles it from its config file and publishes it here; the
    /// extension reads it to initialize the Customer.io SDK and record the `delivered` metric.
    static var customerIOCdpApiKey: String? {
        get { sharedDefaults?.string(forKey: Key.customerIOCdpApiKey) }
        set { sharedDefaults?.set(newValue, forKey: Key.customerIOCdpApiKey) }
    }

    private enum Key {
        static let customerIOCdpApiKey = "com.tangem.customerio.cdpApiKey"
    }

    private static var sharedDefaults: UserDefaults? {
        guard let suiteName = Bundle.main.object(forInfoDictionaryKey: "SUITE_NAME") as? String else {
            return nil
        }

        return UserDefaults(suiteName: suiteName)
    }
}
