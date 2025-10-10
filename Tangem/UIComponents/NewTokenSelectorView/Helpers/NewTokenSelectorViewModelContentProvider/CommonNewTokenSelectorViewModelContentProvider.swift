//
//  CommonNewTokenSelectorViewModelContentProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class CommonNewTokenSelectorViewModelContentProvider: NewTokenSelectorViewModelContentProvider {
    private let cryptoAccountModelWithWalletManager = CommonCryptoAccountsWalletModelsManager()

    var itemsPublisher: AnyPublisher<NewTokenSelectorList, Never> {
        cryptoAccountModelWithWalletManager
            .cryptoAccountModelWithWalletPublisher
            .withWeakCaptureOf(self)
            .receiveOnGlobal()
            .map { $0.mapToNewTokenSelectorItemList(wallets: $1) }
            .eraseToAnyPublisher()
    }

    private func mapToNewTokenSelectorItemList(wallets: [CryptoAccountsWallet]) -> NewTokenSelectorList {
        wallets.map { wallet in
            let selectorWallet = NewTokenSelectorItem.Wallet(userWalletInfo: wallet.userWalletInfo)
            let list: [NewTokenSelectorAccountListItem] = wallet.accounts.map { account in
                let iconViewData = AccountIconViewBuilder().makeAccountIconViewData(accountModel: account.account)
                let selectorAccount = NewTokenSelectorItem.Account(
                    name: account.account.name,
                    icon: iconViewData,
                    walletModelsManager: account.walletModelsManager
                )

                let items = account.walletModels.map { walletModel in
                    NewTokenSelectorItem(
                        wallet: selectorWallet,
                        account: selectorAccount,
                        walletModel: walletModel
                    )
                }

                return NewTokenSelectorAccountListItem(account: selectorAccount, items: items)
            }

            return NewTokenSelectorListItem(wallet: selectorWallet, list: list)
        }
    }
}
