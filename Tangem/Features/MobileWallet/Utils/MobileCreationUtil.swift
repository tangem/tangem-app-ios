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
        let preparedWallet = try await prepareNewWallet(
            hasMnemonicBackup: hasMnemonicBackup,
            hasICloudBackup: hasICloudBackup,
            hasSocialLogin: hasSocialLogin
        )
        let userWalletModel = try makeModelOrCleanUp(preparedWallet: preparedWallet)

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

        return try makeModelOrCleanUp(preparedWallet: preparedWallet)
    }

    func prepareNewWallet(
        hasMnemonicBackup: Bool,
        hasICloudBackup: Bool,
        hasSocialLogin: Bool
    ) async throws -> MobileWalletInitializer.PreparedWallet {
        let parameters = WalletInitializerParameters(
            mnemonic: nil,
            passphrase: nil,
            isImported: false,
            hasMnemonicBackup: hasMnemonicBackup,
            hasICloudBackup: hasICloudBackup,
            hasSocialLogin: hasSocialLogin
        )

        return try await Task.detached {
            try await MobileWalletInitializer().initializeWallet(parameters: parameters)
        }.value
    }

    func prepareImportedWallet(
        mnemonic: Mnemonic,
        passphrase: String?,
        hasMnemonicBackup: Bool,
        hasICloudBackup: Bool,
        hasSocialLogin: Bool
    ) async throws -> MobileWalletInitializer.PreparedWallet {
        try await MobileWalletInitializer().initializeWallet(
            parameters: WalletInitializerParameters(
                mnemonic: mnemonic,
                passphrase: passphrase,
                isImported: true,
                hasMnemonicBackup: hasMnemonicBackup,
                hasICloudBackup: hasICloudBackup,
                hasSocialLogin: hasSocialLogin
            )
        )
    }

    func makeModel(preparedWallet: MobileWalletInitializer.PreparedWallet) throws -> UserWalletModel {
        guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
            walletInfo: .mobileWallet(preparedWallet.walletInfo),
            keys: .mobileWallet(keys: preparedWallet.walletInfo.keys),
        ) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        return userWalletModel
    }

    func store(_ userWalletModel: UserWalletModel) throws {
        do {
            try userWalletRepository.add(userWalletModel: userWalletModel)
        } catch {
            discard(userWalletModel)
            throw error
        }

        BackendAuthenticationRegistrar.registerNewUnprotectedMobileWallet(userWalletModel)
    }

    func discard(_ userWalletModel: UserWalletModel) {
        userWalletModel.dispose()

        guard userWalletRepository.models[userWalletModel.userWalletId] == nil else {
            return
        }

        MobileCleanupUtil.cleanMobileWallet(walletId: userWalletModel.userWalletId)
    }
}

// MARK: - Private methods

private extension MobileCreationUtil {
    func makeModelOrCleanUp(preparedWallet: MobileWalletInitializer.PreparedWallet) throws -> UserWalletModel {
        do {
            return try makeModel(preparedWallet: preparedWallet)
        } catch {
            MobileCleanupUtil.cleanMobileWallet(walletId: preparedWallet.walletId)
            throw error
        }
    }
}
