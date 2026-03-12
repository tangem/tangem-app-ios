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

        let newSettingsVersion = 1

        guard AppSettings.shared.settingsVersion < newSettingsVersion else {
            return
        }

        switch AppSettings.shared.settingsVersion {
        case 0: migrateUseBiometricAuthenticationIfNeeded()
        default: break
        }

        AppSettings.shared.settingsVersion = newSettingsVersion
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
        storage.clear()
    }
}
