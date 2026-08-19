//
//  ForYouSwapTokenSelectorViewModel.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class ForYouSwapTokenSelectorViewModel: ObservableObject, Identifiable {
    let tokenSelectorViewModel: TokenSelectorViewModel

    private let onSelect: (any WalletModel, UserWalletInfo) -> Void
    private let onClose: () -> Void

    init(
        coin: TokenItem,
        walletId: UserWalletId,
        onSelect: @escaping (any WalletModel, UserWalletInfo) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onSelect = onSelect
        self.onClose = onClose

        tokenSelectorViewModel = .swap(
            walletsProvider: ForYouSwapSourceWalletsProvider(walletId: walletId, currencyId: coin.currencyId),
            preferredWalletId: walletId
        )
        tokenSelectorViewModel.setup(with: self)
    }

    func close() {
        onClose()
    }
}

extension ForYouSwapTokenSelectorViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        guard case .crypto(let walletModel, _) = item.kind else {
            onClose()
            return
        }

        onSelect(walletModel, item.userWalletInfo)
    }
}

// MARK: - Coin-scoped source wallets provider

private struct ForYouSwapSourceWalletsProvider: TokenSelectorWalletsProvider {
    let walletId: UserWalletId
    let currencyId: String?

    private let base = CommonTokenSelectorWalletsProvider()

    var wallets: [TokenSelectorWallet] {
        base.wallets
            .filter { $0.wallet.id == walletId }
            .map { wallet in
                TokenSelectorWallet(wallet: wallet.wallet, accounts: scoped(wallet.accounts))
            }
    }

    private func scoped(_ accountType: TokenSelectorWallet.AccountType) -> TokenSelectorWallet.AccountType {
        switch accountType {
        case .single(let account):
            .single(scoped(account))
        case .multiple(let accounts):
            .multiple(accounts.map(scoped))
        }
    }

    private func scoped(_ account: TokenSelectorAccount) -> TokenSelectorAccount {
        TokenSelectorAccount(
            account: account.account,
            itemsProvider: CoinScopedItemsProvider(base: account.itemsProvider, currencyId: currencyId),
            rateProvider: account.rateProvider
        )
    }
}

private struct CoinScopedItemsProvider: TokenSelectorAccountModelItemsProvider {
    let base: any TokenSelectorAccountModelItemsProvider
    let currencyId: String?

    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> {
        // A `nil` `currencyId` identifies no coin — matching on it would lump together every unmapped custom token.
        guard let currencyId else {
            return .just(output: [])
        }

        return base.itemsPublisher
            .map { items in
                items.filter { $0.tokenItem.currencyId == currencyId }
            }
            .eraseToAnyPublisher()
    }
}
