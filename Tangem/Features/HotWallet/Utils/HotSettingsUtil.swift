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

    func calculateAccessCodeState() async -> AccessCodeState {
        if isBackupNeeded {
            return .backupNeeded
        }

        if !isAccessCodeCreated {
            return .onboarding(needsValidation: false)
        }

        if isAccessCodeRequired {
            return .onboarding(needsValidation: true)
        }

        let isBiometricsSuccessful = await isBiometricsSuccessful()

        return .onboarding(needsValidation: !isBiometricsSuccessful)
    }

    func calculateSeedPhraseState() async -> SeedPhraseState {
        if isAccessCodeRequired {
            return .onboarding(needsValidation: true)
        } else {
            let isBiometricsSuccessful = await isBiometricsSuccessful()
            return .onboarding(needsValidation: !isBiometricsSuccessful)
        }
    }
}

// MARK: - Private methods

private extension HotSettingsUtil {
    func isBiometricsSuccessful() async -> Bool {
        let context = try? await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)
        return context != nil
    }
}

// MARK: - Types

extension HotSettingsUtil {
    enum WalletSetting {
        case accessCode
        case backup(hasBackup: Bool)
    }

    enum AccessCodeState {
        case backupNeeded
        case onboarding(needsValidation: Bool)
    }

    enum SeedPhraseState {
        case onboarding(needsValidation: Bool)
    }
}
