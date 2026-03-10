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

    func mapToAccountsAwareTokenSelectorAccount(
        userWalletInfo: UserWalletInfo,
        cryptoAccount: any CryptoAccountModel
    ) -> AccountsAwareTokenSelectorAccount {
        let itemsProvider = CommonAccountsAwareTokenSelectorCryptoAccountModelItemsProvider(
            userWalletInfo: userWalletInfo,
            cryptoAccount: cryptoAccount
        )

        return AccountsAwareTokenSelectorAccount(account: cryptoAccount, itemsProvider: itemsProvider)
    }

    func mapToAccountsAwareTokenSelectorAccount(
        userWalletInfo: UserWalletInfo,
        tangemPayAccountModel: any TangemPayAccountModel
    ) -> AccountsAwareTokenSelectorAccount {
        let itemsProvider = CommonAccountsAwareTokenSelectorTangemPayAccountModelItemsProvider(
            userWalletInfo: userWalletInfo,
            tangemPayAccountModel: tangemPayAccountModel
        )

        return AccountsAwareTokenSelectorAccount(account: tangemPayAccountModel, itemsProvider: itemsProvider)
    }

    func mapToAccountType(
        accountModels: [AccountModel],
        userWalletInfo: UserWalletInfo,
        isUserWalletLocked: Bool
    ) -> AccountsAwareTokenSelectorWallet.AccountType {
        let firstStandard = accountModels.firstStandard()
        if firstStandard == nil {
            assert(isUserWalletLocked, "Non-locked wallet should contain at least one crypto account (main)")
            return .multiple([])
        }

        let items: [AccountsAwareTokenSelectorAccount] = accountModels
            .flatMap { accountModel -> [AccountsAwareTokenSelectorAccount] in
                switch accountModel {
                case .standard(.single(let account)):
                    [mapToAccountsAwareTokenSelectorAccount(userWalletInfo: userWalletInfo, cryptoAccount: account)]

                case .standard(.multiple(let accounts)):
                    accounts.map { mapToAccountsAwareTokenSelectorAccount(userWalletInfo: userWalletInfo, cryptoAccount: $0) }

                case .tangemPay(let tangemPayAccountModel):
                    [
                        mapToAccountsAwareTokenSelectorAccount(
                            userWalletInfo: userWalletInfo,
                            tangemPayAccountModel: tangemPayAccountModel
                        ),
                    ]
                }
            }

        if items.count == 1, let first = items.first {
            return .single(first)
        }

        return .multiple(items)
    }
}
