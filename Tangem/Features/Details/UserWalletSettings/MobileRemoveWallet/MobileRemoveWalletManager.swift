//
//  MobileRemoveWalletManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileRemoveWalletManager: AnyObject {
    var backupState: MobileRemoveWalletBackupState { get }
    var deletesICloudBackup: Bool { get set }
    func removeWallet()
}

enum MobileRemoveWalletBackupState {
    case iCloudBackup
    case seedBackup
    case noBackup
}

final class CommonMobileRemoveWalletManager {
    var deletesICloudBackup = false

    let backupState: MobileRemoveWalletBackupState

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        backupState = Self.makeBackupState(config: userWalletModel.config)
    }
}

// MARK: - MobileRemoveWalletManager

extension CommonMobileRemoveWalletManager: MobileRemoveWalletManager {
    func removeWallet() {
        if deletesICloudBackup {
            MobileCleanupUtil.cleanBackup(
                walletId: userWalletModel.userWalletId,
                analyticsContextData: userWalletModel.analyticsContextData
            )
        }

        userWalletRepository.delete(userWalletId: userWalletModel.userWalletId)
    }
}

// MARK: - Private methods

private extension CommonMobileRemoveWalletManager {
    static func makeBackupState(config: UserWalletConfig) -> MobileRemoveWalletBackupState {
        if MobileBackupStatusUtil.hasICloudBackup(config: config) {
            return .iCloudBackup
        }

        return MobileBackupStatusUtil.hasMnemonicBackup(config: config) ? .seedBackup : .noBackup
    }
}
