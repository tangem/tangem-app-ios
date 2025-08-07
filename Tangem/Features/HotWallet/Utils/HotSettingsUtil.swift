//
//  HotSettingsUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemFoundation
import TangemHotSdk
import class TangemSdk.BiometricsUtil

final class HotSettingsUtil {
    private var isAccessCodeFeatureAvailable: Bool {
        userWalletConfig.isFeatureVisible(.userWalletAccessCode)
    }

    private var isBackupFeatureAvailable: Bool {
        userWalletConfig.isFeatureVisible(.backup)
    }

    private var isBackupNeeded: Bool {
        !userWalletConfig.hasFeature(.mnemonicBackup)
    }

    private lazy var hotSdk: HotSdk = CommonHotSdk()
    private lazy var accessCodeUtil = HotAccessCodeUtil(userWalletId: userWalletId, config: userWalletConfig)

    private let userWalletId: UserWalletId
    private let userWalletConfig: UserWalletConfig

    init(userWalletModel: UserWalletModel) {
        userWalletId = userWalletModel.userWalletId
        userWalletConfig = userWalletModel.config
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

    func calculateAccessCodeState() async -> AccessCodeState? {
        if isBackupNeeded {
            return .needsBackup
        }

        switch await unlock() {
        case .successful:
            return .onboarding
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

private extension HotSettingsUtil {
    func unlock() async -> UnlockResult {
        do {
            let result = try await accessCodeUtil.unlock(method: .default(useBiometrics: false))

            switch result {
            case .accessCode(let context):
                let encryptionKey = try hotSdk.userWalletEncryptionKey(context: context)

                guard
                    let configEncryptionKey = UserWalletEncryptionKey(config: userWalletConfig),
                    encryptionKey.symmetricKey == configEncryptionKey.symmetricKey
                else {
                    return .failed
                }

                return .successful

            case .biometricsRequired:
                let context = try await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)
                let storageEncryptionKeys = try UserWalletEncryptionKeyStorage().fetch(userWalletIds: [userWalletId], context: context)

                guard
                    let storageEncryptionKey = storageEncryptionKeys[userWalletId],
                    let configEncryptionKey = UserWalletEncryptionKey(config: userWalletConfig),
                    storageEncryptionKey == configEncryptionKey
                else {
                    return .failed
                }

                return .successful

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                return .failed
            }

        } catch {
            return .failed
        }
    }

    enum UnlockResult {
        case successful
        case canceled
        case failed
    }
}

// MARK: - Types

extension HotSettingsUtil {
    enum WalletSetting {
        case accessCode
        case backup(hasBackup: Bool)
    }

    enum AccessCodeState {
        case needsBackup
        case onboarding
    }

    enum SeedPhraseState {
        case onboarding
    }
}
