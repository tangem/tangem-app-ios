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

    init() {}
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
        func mapToAccountType(accountModels: [AccountModel]) -> AccountsAwareTokenSelectorWallet.AccountType {
            switch accountModels.standard() {
            case .none:
                assertionFailure("UserWalletModel does not contain CryptoAccount")
                return .multiple([])
            case .standard(.single(let account)):
                return .single(
                    mapToAccountsAwareTokenSelectorAccount(wallet: userWalletModel, cryptoAccount: account)
                )
            case .standard(.multiple(let accounts)):
                let accounts = accounts
                    .map { mapToAccountsAwareTokenSelectorAccount(wallet: userWalletModel, cryptoAccount: $0) }

                return .multiple(accounts)
            }
        }

        let accounts = mapToAccountType(accountModels: userWalletModel.accountModelsManager.accountModels)
        let accountsPublisher = userWalletModel
            .accountModelsManager
            .accountModelsPublisher
            .map { mapToAccountType(accountModels: $0) }
            .eraseToAnyPublisher()

        return AccountsAwareTokenSelectorWallet(
            wallet: userWalletModel.userWalletInfo,
            accounts: accounts,
            accountsPublisher: accountsPublisher
        )
    }

    func mapToAccountsAwareTokenSelectorAccount(wallet: any UserWalletModel, cryptoAccount: any CryptoAccountModel) -> AccountsAwareTokenSelectorAccount {
        let itemsProvider = CommonAccountsAwareTokenSelectorCryptoAccountModelItemsProvider(
            userWalletInfo: wallet.userWalletInfo,
            cryptoAccount: cryptoAccount
        )

        return AccountsAwareTokenSelectorAccount(cryptoAccount: cryptoAccount, itemsProvider: itemsProvider)
    }
}
