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
        guard FeatureProvider.isAvailable(.hotWallet) else {
            return
        }

        if !AppSettings.shared.useBiometricAuthentication,
           AppSettings.shared.saveUserWallets,
           BiometricsUtil.isAvailable {
            AppSettings.shared.useBiometricAuthentication = true
        }

        AppSettings.shared.saveUserWallets = true
    }
}
