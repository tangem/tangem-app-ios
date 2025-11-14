//
//  SwapNewTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

class SwapNewTokenSelectorWalletsProvider: CommonNewTokenSelectorWalletsProvider {
    let selectedItem: AnyPublisher<TokenItem?, Never>

    init(
        selectedItem: AnyPublisher<TokenItem?, Never>,
        availabilityProviderFactory: any NewTokenSelectorItemAvailabilityProviderFactory
    ) {
        self.selectedItem = selectedItem

        super.init(availabilityProviderFactory: availabilityProviderFactory)
    }

    override func mapToNewTokenSelectorAccount(wallet: any UserWalletModel, cryptoAccount: any CryptoAccountModel) -> NewTokenSelectorAccount {
        let account = super.mapToNewTokenSelectorAccount(wallet: wallet, cryptoAccount: cryptoAccount)
        let itemsPublisher = Publishers
            .CombineLatest(account.itemsPublisher, selectedItem)
            .map { items, selected in
                if let selected {
                    return items.filter { $0.walletModel.tokenItem != selected }
                }

                return items
            }
            .eraseToAnyPublisher()

        return NewTokenSelectorAccount(cryptoAccount: account.cryptoAccount, itemsPublisher: itemsPublisher)
    }
}
