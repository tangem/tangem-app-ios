//
//  CommonAccountsAwareTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class CommonAccountsAwareTokenSelectorWalletsProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - AccountsAwareTokenSelectorWalletsProvider

extension CommonAccountsAwareTokenSelectorWalletsProvider: AccountsAwareTokenSelectorWalletsProvider {
    var wallets: [AccountsAwareTokenSelectorWallet] {
        userWalletRepository.models.map { userWalletModel in
            mapToAccountsAwareTokenSelectorWallet(userWalletModel: userWalletModel)
        }
    }
}

// MARK: - AccountsAwareTokenSelectorWalletsProvider

private extension CommonAccountsAwareTokenSelectorWalletsProvider {
    func mapToAccountsAwareTokenSelectorWallet(userWalletModel: any UserWalletModel) -> AccountsAwareTokenSelectorWallet {
        let userWalletInfo = userWalletModel.userWalletInfo
        let isUserWalletLocked = userWalletModel.isUserWalletLocked
        let accounts = mapToAccountType(
            accountModels: userWalletModel.accountModelsManager.accountModels,
            userWalletInfo: userWalletInfo,
            isUserWalletLocked: isUserWalletLocked
        )
        let accountsPublisher = userWalletModel
            .accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .map { mapper, accountModels in
                mapper.mapToAccountType(
                    accountModels: accountModels,
                    userWalletInfo: userWalletInfo,
                    isUserWalletLocked: isUserWalletLocked
                )
            }
            .eraseToAnyPublisher()

        return AccountsAwareTokenSelectorWallet(
            wallet: userWalletInfo,
            accounts: accounts,
            accountsPublisher: accountsPublisher
        )
    }

    func mapToAccountsAwareTokenSelectorAccount(userWalletInfo: UserWalletInfo, cryptoAccount: any CryptoAccountModel) -> AccountsAwareTokenSelectorAccount {
        let itemsProvider = CommonAccountsAwareTokenSelectorCryptoAccountModelItemsProvider(
            userWalletInfo: userWalletInfo,
            cryptoAccount: cryptoAccount
        )

        return AccountsAwareTokenSelectorAccount(cryptoAccount: cryptoAccount, itemsProvider: itemsProvider)
    }

    func mapToAccountType(
        accountModels: [AccountModel],
        userWalletInfo: UserWalletInfo,
        isUserWalletLocked: Bool
    ) -> AccountsAwareTokenSelectorWallet.AccountType {
        switch accountModels.firstStandard() {
        case .none:
            assert(isUserWalletLocked, "Non-locked wallet should contain at least one crypto account (main)")
            return .multiple([])
        case .standard(.single(let account)):
            return .single(
                mapToAccountsAwareTokenSelectorAccount(userWalletInfo: userWalletInfo, cryptoAccount: account)
            )
        case .standard(.multiple(let accounts)):
            let accounts = accounts
                .map { mapToAccountsAwareTokenSelectorAccount(userWalletInfo: userWalletInfo, cryptoAccount: $0) }

            return .multiple(accounts)
        }
    }
}
