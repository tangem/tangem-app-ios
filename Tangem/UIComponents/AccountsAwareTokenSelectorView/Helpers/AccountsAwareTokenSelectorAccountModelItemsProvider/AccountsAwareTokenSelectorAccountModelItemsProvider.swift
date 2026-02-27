//
//  AccountsAwareTokenSelectorAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol AccountsAwareTokenSelectorAccountModelItemsProvider {
    var items: [AccountsAwareTokenSelectorItem] { get }
    var itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItem], Never> { get }
}

struct CommonAccountsAwareTokenSelectorAccountModelItemsProvider {
    let userWalletInfo: UserWalletInfo
    let cryptoAccount: any CryptoAccountModel

    private let tokenSectionsAdapter: TokenSectionsAdapter

    init(
        userWalletInfo: UserWalletInfo,
        cryptoAccount: any CryptoAccountModel
    ) {
        self.userWalletInfo = userWalletInfo
        self.cryptoAccount = cryptoAccount

        tokenSectionsAdapter = TokenSectionsAdapter(
            userTokensManager: cryptoAccount.userTokensManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: cryptoAccount.userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
    }
}

// MARK: - AccountsAwareTokenSelectorAccountModelItemsProvider

extension CommonAccountsAwareTokenSelectorAccountModelItemsProvider: AccountsAwareTokenSelectorAccountModelItemsProvider {
    var items: [AccountsAwareTokenSelectorItem] {
        tokenSectionsAdapter
            .organizedSections(from: cryptoAccount.walletModelsManager.walletModels)
            .flatMap { $0.items.compactMap { $0.walletModel } }
            .map { mapToAccountsAwareTokenSelectorItem(walletModel: $0) }
    }

    var itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItem], Never> {
        let walletModelsPublisher = cryptoAccount.walletModelsManager.walletModelsPublisher

        return tokenSectionsAdapter
            .organizedSections(from: walletModelsPublisher, on: .main)
            .map { section in
                section
                    .flatMap { $0.items.compactMap { $0.walletModel } }
                    .map { mapToAccountsAwareTokenSelectorItem(walletModel: $0) }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonAccountsAwareTokenSelectorAccountModelItemsProvider {
    private func mapToAccountsAwareTokenSelectorItem(walletModel: any WalletModel) -> AccountsAwareTokenSelectorItem {
        AccountsAwareTokenSelectorItem(
            userWalletInfo: userWalletInfo,
            source: .crypto(account: cryptoAccount, walletModel: walletModel)
        )
    }
}
