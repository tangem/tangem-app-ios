//
//  MobileAuthUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import TangemFoundation
import TangemMobileWalletSdk
import class TangemSdk.BiometricsUtil

final class MobileAuthUtil {
    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private lazy var accessCodeManager = SessionMobileAccessCodeManager(
        userWalletId: userWalletId,
        configuration: .default,
        storageManager: CommonMobileAccessCodeStorageManager()
    )

    private var isAccessCodeSet: Bool {
        config.userWalletAccessCodeStatus.hasAccessCode
    }

    private var isAccessCodeRequired: Bool {
        AppSettings.shared.requireAccessCodes
    }

    private var isBiometricsAvailable: Bool {
        BiometricsUtil.isAvailable &&
            AppSettings.shared.useBiometricAuthentication &&
            mobileWalletSdk.isBiometricsEnabled(for: userWalletId)
    }

    private let userWalletId: UserWalletId
    private let config: UserWalletConfig
    private let biometricsProvider: UserWalletBiometricsProvider

    init(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        biometricsProvider: UserWalletBiometricsProvider
    ) {
        self.userWalletId = userWalletId
        self.config = config
        self.biometricsProvider = biometricsProvider
    }
}

// MARK: - Internal methods

extension MobileAuthUtil {
    func unlock() async throws -> Result {
        if isAccessCodeSet {
            return try await unlockResult()
        } else {
            let context = try mobileWalletSdk.validate(auth: .none, for: userWalletId)
            return .successful(context)
        }
    }
}

// MARK: - Unlocking

private extension MobileAuthUtil {
    func unlockResult() async throws -> Result {
        if isAccessCodeRequired {
            return try await unlockWithFallback()
        } else if isBiometricsAvailable {
            do {
                return try await unlockWithBiometrics()
            } catch {
                return try await unlockWithFallback()
            }
        } else {
            return try await unlockWithFallback()
        }
    }

    func unlockWithBiometrics() async throws -> Result {
        do {
            let context = try await biometricsProvider.unlock()
            return try handleBiometrics(laContext: context)
        } catch {
            AppLogger.error("Mobile authUtil failed to unlock with biometrics", error: error)
            throw error
        }
    }

    func unlockWithFallback() async throws -> Result {
        let unlockUtil = MobileUnlockUtil(
            userWalletId: userWalletId,
            config: config,
            biometricsProvider: biometricsProvider,
            accessCodeManager: accessCodeManager
        )
        let unlockResult = try await unlockUtil.unlock()
        return try map(result: unlockResult)
    }
}

// MARK: - Private methods

private extension MobileAuthUtil {
    func handleBiometrics(laContext: LAContext) throws -> Result {
        let context = try mobileWalletSdk.validate(auth: .biometrics(context: laContext), for: userWalletId)
        accessCodeManager.cleanWrongAccessCodes()
        return .successful(context)
    }

    func handleAccessCode(context: MobileWalletContext) throws -> Result {
        let encryptionKey = try mobileWalletSdk.userWalletEncryptionKey(context: context)
        guard
            let configEncryptionKey = UserWalletEncryptionKey(config: config),
            encryptionKey.symmetricKey == configEncryptionKey.symmetricKey
        else {
            throw MobileWalletError.encryptionKeyMismatched
        }

        if BiometricsUtil.isAvailable,
           AppSettings.shared.useBiometricAuthentication,
           !AppSettings.shared.requireAccessCodes,
           !mobileWalletSdk.isBiometricsEnabled(for: userWalletId) {
            try? mobileWalletSdk.refreshBiometrics(context: context)
        }

        return .successful(context)
    }
}

// MARK: - Mapping

private extension MobileAuthUtil {
    func map(result: MobileUnlockUtil.Result) throws -> Result {
        switch result {
        case .accessCode(let context):
            return try handleAccessCode(context: context)
        case .biometrics(let laContext):
            return try handleBiometrics(laContext: laContext)
        case .canceled:
            return .canceled
        case .userWalletNeedsToDelete:
            return .userWalletNeedsToDelete
        }
    }
}

// MARK: - Types

extension MobileAuthUtil {
    enum Result {
        /// Mobile wallet context was successfully received.
        case successful(MobileWalletContext)
        /// Authorization was canceled by the user.
        case canceled
        /// Wallet needs to be deleted.
        case userWalletNeedsToDelete
    }
}
