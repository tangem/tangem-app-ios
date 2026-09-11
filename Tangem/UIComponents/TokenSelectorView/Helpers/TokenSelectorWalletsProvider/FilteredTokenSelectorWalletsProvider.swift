//
//  FilteredTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// Restricts a base provider's content to items matching a predicate. The predicate sees the
/// whole `TokenSelectorItem`, so it can filter by the item's kind, not just its token.
struct FilteredTokenSelectorWalletsProvider: TokenSelectorWalletsProvider {
    let base: any TokenSelectorWalletsProvider
    /// Drops wallets entirely — without this, a wallet whose items are all filtered out
    /// stays in the selector as an empty tab.
    let includesWallet: (TokenSelectorWallet) -> Bool
    let isIncluded: (TokenSelectorItem) -> Bool

    init(
        base: any TokenSelectorWalletsProvider,
        includesWallet: @escaping (TokenSelectorWallet) -> Bool = { _ in true },
        isIncluded: @escaping (TokenSelectorItem) -> Bool
    ) {
        self.base = base
        self.includesWallet = includesWallet
        self.isIncluded = isIncluded
    }

    var wallets: [TokenSelectorWallet] {
        base.wallets.filter(includesWallet).map { wallet in
            TokenSelectorWallet(wallet: wallet.wallet, accounts: filtered(wallet.accounts))
        }
    }

    private func filtered(_ accounts: TokenSelectorWallet.AccountType) -> TokenSelectorWallet.AccountType {
        switch accounts {
        case .single(let account):
            .single(wrapped(account))
        case .multiple(let accounts):
            .multiple(accounts.map(wrapped))
        }
    }

    private func wrapped(_ account: TokenSelectorAccount) -> TokenSelectorAccount {
        TokenSelectorAccount(
            account: account.account,
            itemsProvider: FilteredTokenSelectorItemsProvider(base: account.itemsProvider, isIncluded: isIncluded),
            rateProvider: account.rateProvider
        )
    }
}

private struct FilteredTokenSelectorItemsProvider: TokenSelectorAccountModelItemsProvider {
    let base: any TokenSelectorAccountModelItemsProvider
    let isIncluded: (TokenSelectorItem) -> Bool

    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> {
        base.itemsPublisher
            .map { items in items.filter(isIncluded) }
            .eraseToAnyPublisher()
    }
}
