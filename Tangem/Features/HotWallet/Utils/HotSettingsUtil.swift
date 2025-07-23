//
//  HotSettingsUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import class TangemSdk.BiometricsUtil

struct HotSettingsUtil {
    private let userWalletModel: UserWalletModel

    private var isAccessCodeFeatureAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    private var isBackupFeatureAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    private var isBackupNeeded: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    // [REDACTED_TODO_COMMENT]
    private var isAccessCodeCreated: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    private var isAccessCodeRequired: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - Internal methods

extension HotSettingsUtil {
    var walletSettings: [WalletSetting] {
        var settings: [WalletSetting] = []

        if isAccessCodeFeatureAvailable {
            settings.append(.accessCode)
        }

        if isBackupFeatureAvailable {
            settings.append(.backup(hasBackup: !isBackupNeeded))
        }

        return settings
    }

    func performAccessCodeAction() async -> AccessCodeActionResult {
        if isBackupNeeded {
            return .backupNeeded
        }

        if !isAccessCodeCreated {
            return .onboarding(needsValidation: false)
        }

        if isAccessCodeRequired {
            return .onboarding(needsValidation: true)
        }

        do {
            let _ = try await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)
            return .onboarding(needsValidation: false)
        } catch {
            return .onboarding(needsValidation: true)
        }
    }
}

// MARK: - Types

extension HotSettingsUtil {
    enum WalletSetting {
        case accessCode
        case backup(hasBackup: Bool)
    }

    enum AccessCodeActionResult {
        case backupNeeded
        case onboarding(needsValidation: Bool)
    }
}
