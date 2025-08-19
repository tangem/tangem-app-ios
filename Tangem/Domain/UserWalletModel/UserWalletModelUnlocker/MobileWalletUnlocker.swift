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

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private lazy var unlockUtil = MobileUnlockUtil(
        userWalletId: userWalletId,
        config: config,
        biometricsProvider: UserWalletBiometricsUnlocker()
    )

    private let userWalletId: UserWalletId
    private let config: UserWalletConfig

    init(userWalletId: UserWalletId, config: UserWalletConfig, info: MobileWalletInfo) {
        self.userWalletId = userWalletId
        self.config = config
        canUnlockAutomatically = !info.isAccessCodeSet
        canShowUnlockUIAutomatically = info.isAccessCodeSet
    }

    func unlock() async -> UserWalletModelUnlockerResult {
        do {
            if canUnlockAutomatically {
                let context = try mobileWalletSdk.validate(auth: .none, for: userWalletId)
                return try makeSuccessResult(context: context)
            } else {
                let unlockResult = try await unlockUtil.unlock()
                return try map(result: unlockResult)
            }
        } catch {
            AppLogger.error("MobileWallet unlock failed:", error: error)
            return .error(error)
        }
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
