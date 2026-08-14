//
//  MobileCreationUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk

final class MobileCreationUtil {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// - Parameters:
    ///   - hasMnemonicBackup: whether the user already holds the recovery phrase of the wallet being imported.
    ///   - hasICloudBackup: whether a backup of the wallet being imported already exists in iCloud.
    func makeImportedModel(
        mnemonic: Mnemonic,
        passphrase: String?,
        hasMnemonicBackup: Bool,
        hasICloudBackup: Bool
    ) async throws -> UserWalletModel {
        let walletInfo = try await MobileWalletInitializer().initializeWallet(
            parameters: WalletInitializerParameters(
                mnemonic: mnemonic,
                passphrase: passphrase,
                hasMnemonicBackup: hasMnemonicBackup,
                hasICloudBackup: hasICloudBackup
            )
        )

        let userWalletConfig = MobileUserWalletConfig(mobileWalletInfo: walletInfo)
        let userWalletId = UserWalletId(config: userWalletConfig)

        guard !userWalletRepository.models.contains(where: { $0.userWalletId == userWalletId }) else {
            throw UserWalletRepositoryError.duplicateWalletAdded
        }

        guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
            walletInfo: .mobileWallet(walletInfo),
            keys: .mobileWallet(keys: walletInfo.keys),
        ) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        return userWalletModel
    }
}
