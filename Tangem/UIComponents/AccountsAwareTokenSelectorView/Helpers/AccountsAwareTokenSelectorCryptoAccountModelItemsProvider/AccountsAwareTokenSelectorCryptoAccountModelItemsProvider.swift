//
//  AccountsAwareTokenSelectorCryptoAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol AccountsAwareTokenSelectorCryptoAccountModelItemsProvider {
    var itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItem], Never> { get }
}

struct CommonAccountsAwareTokenSelectorCryptoAccountModelItemsProvider {
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

// MARK: - AccountsAwareTokenSelectorCryptoAccountModelItemsProvider

extension CommonAccountsAwareTokenSelectorCryptoAccountModelItemsProvider: AccountsAwareTokenSelectorCryptoAccountModelItemsProvider {
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

private extension CommonAccountsAwareTokenSelectorCryptoAccountModelItemsProvider {
    private func mapToAccountsAwareTokenSelectorItem(walletModel: any WalletModel) -> AccountsAwareTokenSelectorItem {
        AccountsAwareTokenSelectorItem(
            userWalletInfo: userWalletInfo,
            account: cryptoAccount,
            walletModel: walletModel,
        )
    }
}
