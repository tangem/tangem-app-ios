//
//  MobileWalletUnlocker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemHotSdk

class MobileWalletUnlocker: UserWalletModelUnlocker {
    let canUnlockAutomatically: Bool
    let canShowUnlockUIAutomatically: Bool

    private lazy var hotSdk: HotSdk = CommonHotSdk()

    private let userWalletId: UserWalletId
    private let accessCodeUtil: HotAccessCodeUtil

    init(userWalletId: UserWalletId, config: UserWalletConfig, info: HotWalletInfo) {
        self.userWalletId = userWalletId
        canUnlockAutomatically = !info.isAccessCodeSet
        canShowUnlockUIAutomatically = info.isAccessCodeSet
        accessCodeUtil = HotAccessCodeUtil(userWalletId: userWalletId, config: config)
    }

    func unlock() async -> UserWalletModelUnlockerResult {
        do {
            let unlockResult = try await accessCodeUtil.unlock(method: .manual(useBiometrics: true))

            switch unlockResult {
            case .accessCode(let context):
                let encryptionKey = try hotSdk.userWalletEncryptionKey(context: context)
                return .success(userWalletId: userWalletId, encryptionKey: encryptionKey)

            case .biometricsRequired:
                return .bioSelected

            case .userWalletNeedsToDelete:
                return .userWalletNeedsToDelete

            case .canceled:
                return .error(CancellationError())
            }

        } catch {
            AppLogger.error("MobileWallet unlock failed:", error: error)
            return .error(error)
        }
    }
}
