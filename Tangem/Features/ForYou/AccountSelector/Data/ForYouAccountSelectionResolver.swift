//
//  ForYouAccountSelectionResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

struct ForYouAccountSelectionResolver {
    struct WalletAccount {
        let wallet: any UserWalletModel
        let account: any CryptoAccountModel
    }

    typealias WalletAccountsPublisher = AnyPublisher<[WalletAccount], Never>
    typealias SelectionScopePublisher = AnyPublisher<SelectionScope, Never>

    private let userWalletRepository: UserWalletRepository
    private let selectionPublisher: AnyPublisher<ForYouAccountSelection, Never>

    /// The wallet set all the scope publishers derive from.
    var unlockedWallets: [any UserWalletModel] {
        userWalletRepository.models.filter { !$0.isUserWalletLocked }
    }

    /// True when no locked wallet is hiding accounts from the selector's universe.
    var includesAllWallets: Bool {
        userWalletRepository.models.allSatisfy { !$0.isUserWalletLocked }
    }

    var selectionScopePublisher: SelectionScopePublisher {
        Publishers.CombineLatest(allWalletAccountsPublisher(), selectionPublisher)
            .map { [self] all, selection in
                SelectionScope(
                    all: all,
                    selection: selection,
                    includesAllWallets: includesAllWallets
                )
            }
            .eraseToAnyPublisher()
    }

    init(
        userWalletRepository: UserWalletRepository = InjectedValues[\.userWalletRepository],
        selectionPublisher: AnyPublisher<ForYouAccountSelection, Never>
    ) {
        self.userWalletRepository = userWalletRepository
        self.selectionPublisher = selectionPublisher
    }
}

// MARK: - Private helpers

private extension ForYouAccountSelectionResolver {
    /// Every unlocked wallet's crypto accounts; re-emits on wallet-set and account-composition changes.
    func allWalletAccountsPublisher() -> WalletAccountsPublisher {
        userWalletRepository.eventProvider
            .mapToVoid()
            .prepend(())
            .map { [self] _ in walletAccountsPublisher(for: unlockedWallets) }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    /// All the wallets' accounts flattened into one list; no wallets → `[]` (`combineLatest` of nothing never emits).
    func walletAccountsPublisher(for wallets: [any UserWalletModel]) -> WalletAccountsPublisher {
        guard !wallets.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        return wallets
            .map(walletAccountsPublisher)
            .combineLatest()
            .map { $0.flatMap { $0 } }
            .eraseToAnyPublisher()
    }

    func walletAccountsPublisher(for wallet: any UserWalletModel) -> WalletAccountsPublisher {
        wallet.accountModelsManager.cryptoAccountModelsPublisher.map { accounts in
            accounts.map { WalletAccount(wallet: wallet, account: $0) }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - ForYouAccountSelectionResolver+SelectionScope

extension ForYouAccountSelectionResolver {
    struct SelectionScope {
        let all, selected: [WalletAccount]
        let selection: ForYouAccountSelection
        /// No locked wallets are hiding accounts from `all`.
        let includesAllWallets: Bool

        init(all: [WalletAccount], selection: ForYouAccountSelection, includesAllWallets: Bool) {
            self.all = all
            self.selection = selection
            self.includesAllWallets = includesAllWallets

            switch selection {
            case .all:
                selected = all
            case .subset(let ids):
                // A fully stale `.subset` (wallet/user changed) falls back to all accounts.
                let filtered = all.filter { ids.contains(ForYouAccountID($0.account)) }
                selected = filtered.isEmpty ? all : filtered
            }
        }

        var coversAllAccounts: Bool {
            selected.count == all.count
        }

        /// A `.subset` that filters nothing: it covers every available account and no wallet is locked.
        var isRedundantSubset: Bool {
            guard case .subset = selection else {
                return false
            }
            return !all.isEmpty && includesAllWallets && coversAllAccounts
        }
    }
}
