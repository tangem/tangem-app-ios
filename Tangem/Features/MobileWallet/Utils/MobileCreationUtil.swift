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
    /// Builds a model for a brand-new mobile wallet.
    /// The caller is responsible for adding the returned model to `UserWalletRepository`.
    func makeCreatedModel(
        hasMnemonicBackup: Bool = false,
        hasICloudBackup: Bool = false,
        hasSocialLogin: Bool = false
    ) async throws -> UserWalletModel {
        let preparedWallet = try await prepareNewWallet(
            hasMnemonicBackup: hasMnemonicBackup,
            hasICloudBackup: hasICloudBackup,
            hasSocialLogin: hasSocialLogin
        )
        let userWalletModel = try makeModel(preparedWallet: preparedWallet)

        // The name is captured here: WalletCreationHelper would otherwise re-derive it from the
        // repository inside the detached task, racing the caller's `add` and registering the
        // wallet on the backend under a different name than the local model.
        let userWalletName = userWalletModel.name
        Task.detached {
            let walletCreationHelper = WalletCreationHelper(
                userWalletId: preparedWallet.walletId,
                userWalletName: userWalletName,
                userWalletConfig: MobileUserWalletConfig(mobileWalletInfo: preparedWallet.walletInfo)
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
        let preparedWallet = try await prepareImportedWallet(
            mnemonic: mnemonic,
            passphrase: passphrase,
            hasMnemonicBackup: hasMnemonicBackup,
            hasICloudBackup: hasICloudBackup,
            hasSocialLogin: hasSocialLogin
        )

        return try makeModel(preparedWallet: preparedWallet)
    }

    func prepareNewWallet(
        hasMnemonicBackup: Bool,
        hasICloudBackup: Bool,
        hasSocialLogin: Bool
    ) async throws -> PreparedWallet {
        let parameters = WalletInitializerParameters(
            mnemonic: nil,
            passphrase: nil,
            isImported: false,
            hasMnemonicBackup: hasMnemonicBackup,
            hasICloudBackup: hasICloudBackup,
            hasSocialLogin: hasSocialLogin
        )

        let walletInfo = try await Task.detached {
            try await MobileWalletInitializer().initializeWallet(parameters: parameters)
        }.value

        return try makePreparedWallet(walletInfo: walletInfo)
    }

    func prepareImportedWallet(
        mnemonic: Mnemonic,
        passphrase: String?,
        hasMnemonicBackup: Bool,
        hasICloudBackup: Bool,
        hasSocialLogin: Bool
    ) async throws -> PreparedWallet {
        let walletInfo = try await MobileWalletInitializer().initializeWallet(
            parameters: WalletInitializerParameters(
                mnemonic: mnemonic,
                passphrase: passphrase,
                isImported: true,
                hasMnemonicBackup: hasMnemonicBackup,
                hasICloudBackup: hasICloudBackup,
                hasSocialLogin: hasSocialLogin
            )
        )

        return try makePreparedWallet(walletInfo: walletInfo)
    }

    func makeModel(preparedWallet: PreparedWallet) throws -> UserWalletModel {
        guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
            walletInfo: .mobileWallet(preparedWallet.walletInfo),
            keys: .mobileWallet(keys: preparedWallet.walletInfo.keys),
        ) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        return userWalletModel
    }
}

// MARK: - Private methods

private extension MobileCreationUtil {
    func makePreparedWallet(walletInfo: MobileWalletInfo) throws -> PreparedWallet {
        guard let walletId = UserWalletId(config: MobileUserWalletConfig(mobileWalletInfo: walletInfo)) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        return PreparedWallet(walletId: walletId, walletInfo: walletInfo)
    }
}

// MARK: - Types

extension MobileCreationUtil {
    struct PreparedWallet {
        let walletId: UserWalletId
        let walletInfo: MobileWalletInfo
    }
}
