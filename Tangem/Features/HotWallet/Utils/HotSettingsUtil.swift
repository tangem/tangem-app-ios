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
        userWalletConfig.isFeatureVisible(.userWalletBackup)
    }

    private var isBackupNeeded: Bool {
        userWalletConfig.hasFeature(.mnemonicBackup) && userWalletConfig.hasFeature(.iCloudBackup)
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

private extension HotSettingsUtil {
    func unlock() async -> UnlockResult {
        do {
            let result = try await accessCodeUtil.unlock(method: .default(useBiometrics: false))

            switch result {
            case .accessCode(let context):
                return try handleAccessCodeUnlockResult(context: context)

            case .biometricsRequired:
                return await unlockWithBiometrics()

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                // [REDACTED_TODO_COMMENT]
                return .failed
            }

        } catch {
            return .failed
        }
    }

    func unlockWithBiometrics() async -> UnlockResult {
        do {
            let laContext = try await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)
            let context = try hotSdk.validate(auth: .biometrics(context: laContext), for: userWalletId)
            return .successful(context: context)
        } catch {
            return await unlockWithAccessCode()
        }
    }

    func unlockWithAccessCode() async -> UnlockResult {
        do {
            let result = try await accessCodeUtil.unlock(method: .manual(useBiometrics: false))

            switch result {
            case .accessCode(let context):
                return try handleAccessCodeUnlockResult(context: context)

            case .biometricsRequired:
                assertionFailure("Case \(result): should never occur in unlock with access-code flow.")
                return .failed

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                // [REDACTED_TODO_COMMENT]
                return .failed
            }

        } catch {
            AppLogger.error("Unlock with AccessCode failed:", error: error)
            return .failed
        }
    }

    func handleAccessCodeUnlockResult(context: MobileWalletContext) throws -> UnlockResult {
        let encryptionKey = try hotSdk.userWalletEncryptionKey(context: context)

        guard
            let configEncryptionKey = UserWalletEncryptionKey(config: userWalletConfig),
            encryptionKey.symmetricKey == configEncryptionKey.symmetricKey
        else {
            throw MobileWalletError.encryptionKeyMismatched
        }

        return .successful(context: context)
    }

    enum UnlockResult {
        case successful(context: MobileWalletContext)
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
        case onboarding(context: MobileWalletContext)
    }

    enum SeedPhraseState {
        case onboarding
    }
}
