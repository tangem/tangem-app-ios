//
//  MobileWalletUnlocker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletSdk

class MobileWalletUnlocker: UserWalletModelUnlocker {
    let canUnlockAutomatically: Bool
    let canShowUnlockUIAutomatically: Bool
    let analyticsSignInType: Analytics.SignInType

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletId: UserWalletId
    private let config: UserWalletConfig

    init(userWalletId: UserWalletId, config: UserWalletConfig, info: MobileWalletInfo) {
        self.userWalletId = userWalletId
        self.config = config
        canUnlockAutomatically = !info.accessCodeStatus.hasAccessCode
        canShowUnlockUIAutomatically = info.accessCodeStatus.hasAccessCode
        analyticsSignInType = info.accessCodeStatus.hasAccessCode ? .accessCode : .noSecurity
    }

    func unlock() async -> UserWalletModelUnlockerResult {
        do {
            if canUnlockAutomatically {
                let context = try mobileWalletSdk.validate(auth: .none, for: userWalletId)
                return try makeSuccessResult(context: context)
            } else {
                return try await unlockWithFallback()
            }
        } catch {
            AppLogger.error("MobileWallet unlock failed:", error: error)
            return .error(error)
        }
    }
}

// MARK: - Unlocking

private extension MobileWalletUnlocker {
    func unlockWithFallback() async throws -> UserWalletModelUnlockerResult {
        let accessCodeManager = CommonMobileAccessCodeManager(
            userWalletId: userWalletId,
            configuration: .default,
            storageManager: CommonMobileAccessCodeStorageManager()
        )
        let unlockUtil = MobileUnlockUtil(
            userWalletId: userWalletId,
            config: config,
            biometricsProvider: UserWalletBiometricsUnlocker(),
            accessCodeManager: accessCodeManager
        )
        let unlockResult = try await unlockUtil.unlock()
        return try map(result: unlockResult)
    }
}

// MARK: - Private methods

private extension MobileWalletUnlocker {
    func makeSuccessResult(context: MobileWalletContext) throws -> UserWalletModelUnlockerResult {
        let encryptionKey = try mobileWalletSdk.userWalletEncryptionKey(context: context)
        return .success(userWalletId: userWalletId, encryptionKey: encryptionKey)
    }
}

// MARK: - Mapping

private extension MobileWalletUnlocker {
    func map(result: MobileUnlockUtil.Result) throws -> UserWalletModelUnlockerResult {
        switch result {
        case .accessCode(let context):
            return try makeSuccessResult(context: context)
        case .biometrics(let context):
            return .biometrics(context)
        case .canceled:
            return .error(CancellationError())
        case .userWalletNeedsToDelete:
            return .userWalletNeedsToDelete
        }
    }
}
