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

    /// Builds a model for a brand-new mobile wallet.
    /// The caller is responsible for adding the returned model to `UserWalletRepository`.
    func makeCreatedModel(
        hasMnemonicBackup: Bool = false,
        hasICloudBackup: Bool = false,
        hasSocialLogin: Bool = false
    ) async throws -> UserWalletModel {
        let parameters = WalletInitializerParameters(
            mnemonic: nil,
            passphrase: nil,
            hasMnemonicBackup: hasMnemonicBackup,
            hasICloudBackup: hasICloudBackup,
            hasSocialLogin: hasSocialLogin
        )

        let walletInfo = try await Task.detached {
            try await MobileWalletInitializer().initializeWallet(parameters: parameters)
        }.value

        guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
            walletInfo: .mobileWallet(walletInfo),
            keys: .mobileWallet(keys: walletInfo.keys),
        ) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        // The name is captured here: WalletCreationHelper would otherwise re-derive it from the
        // repository inside the detached task, racing the caller's `add` and registering the
        // wallet on the backend under a different name than the local model.
        let userWalletName = userWalletModel.name
        Task.detached {
            let userWalletConfig = MobileUserWalletConfig(mobileWalletInfo: walletInfo)
            guard let userWalletId = UserWalletId(config: userWalletConfig) else { return }
            let walletCreationHelper = WalletCreationHelper(
                userWalletId: userWalletId,
                userWalletName: userWalletName,
                userWalletConfig: userWalletConfig
            )
            try? await walletCreationHelper.createWallet()
        }

        return userWalletModel
    }

    /// Builds the user wallet model without adding it to the repository.
    /// Note: `MobileWalletInitializer` stores the wallet keys in the mobile wallet SDK
    /// storage as a side effect, before the returned model is persisted anywhere.
    ///
    /// - Parameters:
    ///   - hasMnemonicBackup: whether the user already holds the recovery phrase of the wallet being imported.
    ///   - hasICloudBackup: whether a backup of the wallet being imported already exists in iCloud.
    ///   - hasSocialLogin: whether the wallet being imported was created through social login.
    func makeImportedModel(
        mnemonic: Mnemonic,
        passphrase: String?,
        hasMnemonicBackup: Bool,
        hasICloudBackup: Bool,
        hasSocialLogin: Bool
    ) async throws -> UserWalletModel {
        let walletInfo = try await MobileWalletInitializer().initializeWallet(
            parameters: WalletInitializerParameters(
                mnemonic: mnemonic,
                passphrase: passphrase,
                hasMnemonicBackup: hasMnemonicBackup,
                hasICloudBackup: hasICloudBackup,
                hasSocialLogin: hasSocialLogin
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
