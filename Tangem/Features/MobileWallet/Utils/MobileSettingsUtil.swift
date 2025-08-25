//
//  MobileSettingsUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemFoundation
import TangemMobileWalletSdk

final class MobileSettingsUtil {
    @Injected(\.sessionMobileAccessCodeStorageManager)
    private var accessCodeStorageManager: MobileAccessCodeStorageManager

    private var isAccessCodeFeatureAvailable: Bool {
        userWalletConfig.isFeatureVisible(.userWalletAccessCode)
    }

    private var isBackupFeatureAvailable: Bool {
        userWalletConfig.isFeatureVisible(.userWalletBackup)
    }

    private var isBackupNeeded: Bool {
        userWalletConfig.hasFeature(.mnemonicBackup) && userWalletConfig.hasFeature(.iCloudBackup)
    }

    private var userWalletConfig: UserWalletConfig {
        userWalletModel.config
    }

    private lazy var accessCodeManager = SessionMobileAccessCodeManager(
        userWalletId: userWalletModel.userWalletId,
        configuration: .default,
        storageManager: accessCodeStorageManager
    )

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - Internal methods

extension MobileSettingsUtil {
    var walletSettings: [WalletSetting] {
        var settings: [WalletSetting] = []

        if isAccessCodeFeatureAvailable {
            settings.append(.accessCode)
        }

        if isBackupFeatureAvailable {
            settings.append(.backup(needsBackup: isBackupNeeded))
        }

        return settings
    }

    func calculateAccessCodeState() async -> AccessCodeState? {
        if isBackupNeeded {
            return .needsBackup
        }

        switch await unlock() {
        case .successful(let context):
            return .onboarding(context: context)
        case .canceled, .failed:
            return .none
        }
    }

    func calculateSeedPhraseState() async -> SeedPhraseState? {
        switch await unlock() {
        case .successful:
            return .onboarding
        case .canceled, .failed:
            return .none
        }
    }
}

// MARK: - Unlocking

private extension MobileSettingsUtil {
    func unlock() async -> UnlockResult {
        do {
            let authUtil = MobileAuthUtil(
                userWalletId: userWalletModel.userWalletId,
                config: userWalletModel.config,
                biometricsProvider: CommonUserWalletBiometricsProvider(),
                accessCodeManager: accessCodeManager
            )
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .failed
            }

        } catch {
            return .failed
        }
    }

    enum UnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed
    }
}

// MARK: - Types

extension MobileSettingsUtil {
    enum WalletSetting {
        case accessCode
        case backup(needsBackup: Bool)
    }

    enum AccessCodeState {
        case needsBackup
        case onboarding(context: MobileWalletContext)
    }

    enum SeedPhraseState {
        case onboarding
    }
}
