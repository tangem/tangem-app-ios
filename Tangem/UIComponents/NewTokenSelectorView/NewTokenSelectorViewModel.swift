//
//  NewTokenSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts
import TangemFoundation

final class NewTokenSelectorViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var wallets: [NewTokenSelectorWalletItemViewModel] = []

    private let walletsProvider: any NewTokenSelectorWalletsProvider
    private weak var output: NewTokenSelectorViewModelOutput?

    private var bag: Set<AnyCancellable> = []

    init(
        walletsProvider: any NewTokenSelectorWalletsProvider,
        output: any NewTokenSelectorViewModelOutput,
    ) {
        self.walletsProvider = walletsProvider
        self.output = output

        bind()
    }

    private func bind() {
        walletsProvider.walletsPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToNewTokenSelectorWalletItemViewModels(wallets: $1) }
            .receiveOnMain()
            .assign(to: &$wallets)
    }

    private func mapToNewTokenSelectorWalletItemViewModels(wallets: [NewTokenSelectorWallet]) -> [NewTokenSelectorWalletItemViewModel] {
        let wallets = wallets.map { wallet in
            mapToNewTokenSelectorWalletItemViewModel(wallet: wallet)
        }

        return wallets
    }
}

// MARK: - NewTokenSelectorItemViewModelMapper

extension NewTokenSelectorViewModel: NewTokenSelectorItemViewModelMapper {
    func mapToNewTokenSelectorWalletItemViewModel(wallet: NewTokenSelectorWallet) -> NewTokenSelectorWalletItemViewModel {
        NewTokenSelectorWalletItemViewModel(wallet: wallet, mapper: self)
    }

    func mapToNewTokenSelectorAccountViewModel(
        header: NewTokenSelectorAccountViewModel.HeaderType,
        account: NewTokenSelectorAccount
    ) -> NewTokenSelectorAccountViewModel {
        NewTokenSelectorAccountViewModel(
            header: header,
            account: account,
            searchTextPublisher: $searchText.eraseToAnyPublisher(),
            mapper: self
        )
    }

    func mapToNewTokenSelectorItemViewModel(item: NewTokenSelectorItem) -> NewTokenSelectorItemViewModel {
        NewTokenSelectorItemViewModel(
            id: item.walletModel.id,
            name: item.walletModel.tokenItem.name,
            symbol: item.walletModel.tokenItem.currencySymbol,
            tokenIconInfo: TokenIconInfoBuilder().build(from: item.walletModel.tokenItem, isCustom: item.walletModel.isCustom),
            availabilityProvider: item.availabilityProvider,
            cryptoBalanceProvider: item.cryptoBalanceProvider,
            fiatBalanceProvider: item.fiatBalanceProvider,
            action: { [weak self] in
                self?.output?.usedDidSelect(item: item)
            }
        )
    }
}
