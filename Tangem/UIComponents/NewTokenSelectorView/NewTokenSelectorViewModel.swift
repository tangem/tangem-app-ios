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
    @Published private(set) var viewState: State = .empty

    private let provider: NewTokenSelectorViewModelContentProvider
    private let filter: NewTokenSelectorViewModelSearchFilter
    private let availabilityProvider: any NewTokenSelectorViewModelAvailabilityProvider
    private weak var output: NewTokenSelectorViewModelOutput?

    init(
        provider: any NewTokenSelectorViewModelContentProvider,
        filter: any NewTokenSelectorViewModelSearchFilter,
        availabilityProvider: any NewTokenSelectorViewModelAvailabilityProvider,
        output: any NewTokenSelectorViewModelOutput,
    ) {
        self.provider = provider
        self.filter = filter
        self.availabilityProvider = availabilityProvider
        self.output = output

        bind()
    }

    private func bind() {
        Publishers
            .CombineLatest(provider.itemsPublisher, $searchText)
            .withWeakCaptureOf(self)
            .map { $0.mapToState($1.0, searchText: $1.1) }
            .receiveOnMain()
            .assign(to: &$viewState)
    }

    private func mapToState(_ list: NewTokenSelectorList, searchText: String) -> State {
        let searchText = searchText.trimmed()
        let filtered = searchText.isEmpty ? list : filter.filter(list: list, searchText: searchText)

        if filtered.isEmpty {
            return .empty
        }

        // If at least one wallet has more then one accounts then all item have to wrapped
        let hasMultipleAccounts = filtered.contains { $0.hasMultipleAccounts }

        if hasMultipleAccounts {
            let wrapped: [NewTokenSelectorGroupedSectionWrapperViewModel] = filtered.map { wallet in
                let wrapperViewModel = mapToNewTokenSelectorGroupedSectionWrapperViewModel(
                    wallet: wallet.wallet,
                    items: wallet.list
                )

                return wrapperViewModel
            }

            return .walletsWithAccounts(wrapped)
        }

        let wallets: [NewTokenSelectorGroupedSectionViewModel] = filtered.flatMap { $0.list }.map { wallet in
            let wrapperViewModel = mapToNewTokenSelectorGroupedSectionViewModel(
                wallet: .init(name: wallet.account.name),
                items: wallet.items
            )

            return wrapperViewModel
        }

        return .wallets(wallets)
    }

    private func mapToNewTokenSelectorGroupedSectionWrapperViewModel(
        wallet: NewTokenSelectorItem.Wallet,
        items: [NewTokenSelectorAccountListItem]
    ) -> NewTokenSelectorGroupedSectionWrapperViewModel {
        let sections = items.map { account in
            mapToNewTokenSelectorGroupedSectionViewModel(account: account.account, items: account.items)
        }

        return NewTokenSelectorGroupedSectionWrapperViewModel(
            isOpen: true,
            wallet: wallet.name,
            sections: sections
        )
    }

    private func mapToNewTokenSelectorGroupedSectionViewModel(
        wallet: NewTokenSelectorItem.Wallet,
        items: [NewTokenSelectorItem]
    ) -> NewTokenSelectorGroupedSectionViewModel {
        NewTokenSelectorGroupedSectionViewModel(
            header: .wallet(wallet.name),
            items: items.map(mapToNewTokenSelectorGroupedSectionViewModel)
        )
    }

    private func mapToNewTokenSelectorGroupedSectionViewModel(
        account: NewTokenSelectorItem.Account,
        items: [NewTokenSelectorItem]
    ) -> NewTokenSelectorGroupedSectionViewModel {
        NewTokenSelectorGroupedSectionViewModel(
            header: .account(icon: account.icon, name: account.name),
            items: items.map(mapToNewTokenSelectorGroupedSectionViewModel)
        )
    }

    private func mapToNewTokenSelectorGroupedSectionViewModel(
        item: NewTokenSelectorItem
    ) -> NewTokenSelectorItemViewModel {
        let disabledReason = availabilityProvider.isAvailable(item: item)

        return NewTokenSelectorItemViewModel(
            id: item.walletModel.id,
            name: item.walletModel.tokenItem.name,
            symbol: item.walletModel.tokenItem.currencySymbol,
            tokenIconInfo: TokenIconInfoBuilder().build(from: item.walletModel.tokenItem, isCustom: item.walletModel.isCustom),
            disabledReason: disabledReason,
            cryptoBalanceProvider: item.cryptoBalanceProvider,
            fiatBalanceProvider: item.cryptoBalanceProvider,
            action: { [weak self] in
                self?.output?.usedDidSelect(item: item)
            }
        )
    }
}

extension NewTokenSelectorViewModel {
    enum State {
        case empty
        case wallets([NewTokenSelectorGroupedSectionViewModel])
        case walletsWithAccounts([NewTokenSelectorGroupedSectionWrapperViewModel])
    }
}
