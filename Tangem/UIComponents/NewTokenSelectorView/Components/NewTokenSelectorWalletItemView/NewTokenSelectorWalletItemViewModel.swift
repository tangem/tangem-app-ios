//
//  NewTokenSelectorWalletItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts

final class NewTokenSelectorWalletItemViewModel: ObservableObject, Identifiable {
    @Published var isOpen: Bool = true
    @Published private(set) var viewType: ViewType?
    @Published private(set) var visibleItemsCount: Int?

    var contentVisibility: NewTokenSelectorViewModel.ContentVisibility {
        visibleItemsCount == .zero ? .empty : .visible
    }

    private let wallet: NewTokenSelectorWallet
    private let mapper: any NewTokenSelectorItemViewModelMapper

    init(
        wallet: NewTokenSelectorWallet,
        mapper: any NewTokenSelectorItemViewModelMapper
    ) {
        self.wallet = wallet
        self.mapper = mapper

        bind()
    }

    private func bind() {
        wallet.accountsPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToViewType(accountType: $1) }
            .assign(to: &$viewType)

        $viewType
            // 1. Collect empty state from each section (wallet, account)
            .map { viewType -> [AnyPublisher<Int, Never>] in
                switch viewType {
                case .none:
                    return [.empty]
                case .wallet(let wallet):
                    return [wallet.$items.compactMap { $0?.count }.eraseToAnyPublisher()]
                case .accounts(_, let accounts):
                    return accounts.map {
                        $0.$items.compactMap { $0?.count }.eraseToAnyPublisher()
                    }
                }
            }
            // 2. Sum items from each section
            .flatMapLatest { $0.combineLatest().map { $0.sum() } }
            .assign(to: &$visibleItemsCount)
    }

    private func mapToViewType(accountType: NewTokenSelectorWallet.AccountType) -> ViewType {
        switch accountType {
        case .single(let account):
            let header = NewTokenSelectorAccountViewModel.HeaderType.wallet(wallet.wallet.name)

            return .wallet(
                mapper.mapToNewTokenSelectorAccountViewModel(header: header, account: account)
            )

        case .multiple(let accounts):
            let accounts = accounts.map { account in
                let icon = AccountModelUtils.UI.iconViewData(accountModel: account.cryptoAccount)
                let header = NewTokenSelectorAccountViewModel.HeaderType.account(
                    icon: icon,
                    name: account.cryptoAccount.name
                )

                return mapper.mapToNewTokenSelectorAccountViewModel(header: header, account: account)
            }

            return .accounts(walletName: wallet.wallet.name, accounts: accounts)
        }
    }
}

extension NewTokenSelectorWalletItemViewModel {
    enum ViewType {
        case wallet(NewTokenSelectorAccountViewModel)
        case accounts(walletName: String, accounts: [NewTokenSelectorAccountViewModel])
    }
}
