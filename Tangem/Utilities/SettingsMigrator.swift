//
//  SettingsMigrator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum SettingsMigrator {
    static func migrateIfNeeded() {
        cleanStorageIfNeeded()

        let newSettingsVersion = 2

        guard AppSettings.shared.settingsVersion < newSettingsVersion else {
            return
        }

        switch AppSettings.shared.settingsVersion {
        case 0:
            migrateUseBiometricAuthenticationIfNeeded()
            fallthrough
        case 1:
            cleanExistingURLCacheIfNeeded()
            fallthrough
        default:
            // No-op, all migrations for previous versions have been applied
            break
        }

        AppSettings.shared.settingsVersion = newSettingsVersion
    }

    private static func cleanExistingURLCacheIfNeeded() {
        // Start the URL cache cleaning only if there are something to clean (> 0 launches)
        // `migrateIfNeeded` is called before the current launch is recorded, therefore we compare to 0
        guard AppSettings.shared.numberOfLaunches > 0 else {
            return
        }

        URLCache.shared.removeAllCachedResponses()
    }

    private static func migrateUseBiometricAuthenticationIfNeeded() {
        if !AppSettings.shared.useBiometricAuthentication,
           AppSettings.shared.saveUserWallets,
           BiometricsUtil.isAvailable {
            AppSettings.shared.useBiometricAuthentication = true
        }

        AppSettings.shared.saveUserWallets = true
    }

    private static func cleanStorageIfNeeded() {
        guard !AppSettings.shared.saveUserWallets else {
            return
        }

        let storage = UserWalletDataStorage()
        storage.clean()
    }
}
