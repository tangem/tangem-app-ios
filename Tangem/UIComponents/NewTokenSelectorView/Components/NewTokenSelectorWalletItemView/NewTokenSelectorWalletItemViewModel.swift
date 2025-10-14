//
//  NewTokenSelectorWalletItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class NewTokenSelectorWalletItemViewModel: ObservableObject, Identifiable {
    @Published var isOpen: Bool = true
    @Published private(set) var viewType: ViewType?

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
                let header = NewTokenSelectorAccountViewModel.HeaderType.account(
                    icon: account.account.icon,
                    name: account.account.name
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
