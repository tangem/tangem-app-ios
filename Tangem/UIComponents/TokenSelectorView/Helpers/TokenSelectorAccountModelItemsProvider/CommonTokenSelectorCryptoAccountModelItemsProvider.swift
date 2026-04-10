//
//  CommonTokenSelectorCryptoAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct CommonTokenSelectorCryptoAccountModelItemsProvider {
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

// MARK: - TokenSelectorCryptoAccountModelItemsProvider

extension CommonTokenSelectorCryptoAccountModelItemsProvider: TokenSelectorAccountModelItemsProvider {
    var items: [TokenSelectorItem] {
        tokenSectionsAdapter
            .organizedSections(from: cryptoAccount.walletModelsManager.walletModels)
            .flatMap { $0.items.compactMap { $0.walletModel } }
            .map { mapToTokenSelectorItem(walletModel: $0) }
    }

    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> {
        let walletModelsPublisher = cryptoAccount.walletModelsManager.walletModelsPublisher

        return tokenSectionsAdapter
            .organizedSections(from: walletModelsPublisher, on: .main)
            .map { section in
                section
                    .flatMap { $0.items.compactMap { $0.walletModel } }
                    .map { mapToTokenSelectorItem(walletModel: $0) }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonTokenSelectorCryptoAccountModelItemsProvider {
    private func mapToTokenSelectorItem(walletModel: any WalletModel) -> TokenSelectorItem {
        TokenSelectorItem(
            userWalletInfo: userWalletInfo,
            kind: .crypto(walletModel, cryptoAccount),
        )
    }
}
