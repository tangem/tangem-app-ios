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
    private let statusUtil: HotStatusUtil

    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        statusUtil = HotStatusUtil(userWalletModel: userWalletModel)
    }
}

// MARK: - Internal methods

extension HotSettingsUtil {
    var walletSettings: [WalletSetting] {
        var settings: [WalletSetting] = []

        if statusUtil.isAccessCodeFeatureAvailable {
            settings.append(.accessCode)
        }

        if statusUtil.isBackupFeatureAvailable {
            settings.append(.backup(hasBackup: !statusUtil.isBackupNeeded))
        }

        return settings
    }

    func calculateAccessCodeState() async -> AccessCodeState {
        if statusUtil.isBackupNeeded {
            return .backupNeeded
        }

        if !statusUtil.isAccessCodeCreated {
            return .onboarding(needsValidation: false)
        }

        if statusUtil.isAccessCodeRequired {
            return .onboarding(needsValidation: true)
        }

        let isBiometricsSuccessful = await isBiometricsSuccessful()

        return .onboarding(needsValidation: !isBiometricsSuccessful)
    }

    func calculateSeedPhraseState() async -> SeedPhraseState {
        guard statusUtil.isAccessCodeCreated else {
            return .onboarding(needsValidation: false)
        }

        if statusUtil.isAccessCodeRequired {
            return .onboarding(needsValidation: true)
        } else {
            let isBiometricsSuccessful = await isBiometricsSuccessful()
            return .onboarding(needsValidation: !isBiometricsSuccessful)
        }
    }
}

// MARK: - Private methods

private extension HotSettingsUtil {
    // [REDACTED_TODO_COMMENT]
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
