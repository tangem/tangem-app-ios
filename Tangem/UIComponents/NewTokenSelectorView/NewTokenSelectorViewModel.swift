//
//  NewTokenSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

typealias NewTokenSelectorItemList = [
    NewTokenSelectorItem.Wallet: NewTokenSelectorAccountItemsList
]

typealias NewTokenSelectorAccountItemsList = [
    NewTokenSelectorItem.Account: [NewTokenSelectorItem]
]

extension NewTokenSelectorAccountItemsList {
    var hasMultipleAccounts: Bool {
        keys.count > 1
    }
}

struct NewTokenSelectorItem {
    let wallet: Wallet
    let tokenItem: TokenItem
    let cryptoBalanceProvider: TokenBalanceProvider
    let fiatBalanceProvider: TokenBalanceProvider
}

extension NewTokenSelectorItem {
    struct Wallet: Hashable {
        let name: String
    }

    struct Account: Hashable {
        let icon: AccountModel.Icon
        let name: String
    }
}

protocol NewTokenSelectorViewModelContentProvider {
    var itemsPublisher: AnyPublisher<NewTokenSelectorItemList, Never> { get }
}

protocol NewTokenSelectorViewModelSearchFilter {
    func filter(list: NewTokenSelectorItemList, searchText: String) -> NewTokenSelectorItemList
}

protocol NewTokenSelectorViewModelOutput: AnyObject {
    func usedDidSelect(item: NewTokenSelectorItem)
}

final class NewTokenSelectorViewModel: ObservableObject {
    @Published private(set) var searchText: String = ""
    @Published private(set) var viewState: State = .empty

    private let provider: NewTokenSelectorViewModelContentProvider
    private let filter: NewTokenSelectorViewModelSearchFilter
    private weak var output: NewTokenSelectorViewModelOutput?

    init(
        provider: any NewTokenSelectorViewModelContentProvider,
        filter: any NewTokenSelectorViewModelSearchFilter,
        output: any NewTokenSelectorViewModelOutput,
    ) {
        self.provider = provider
        self.filter = filter
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

    private func mapToState(_ list: NewTokenSelectorItemList, searchText: String) -> State {
        let filtered = searchText.isEmpty ? list : filter.filter(list: list, searchText: searchText)

        if filtered.isEmpty {
            return .empty
        }

        // If at least one wallet has more then one accounts then all item have to wrapped
        let hasMultipleAccounts = filtered.contains { $0.value.hasMultipleAccounts }

        if hasMultipleAccounts {
            let wrapped: [NewTokenSelectorGroupedSectionWrapperViewModel] = list.map { wallet, values in
                let wrapperViewModel = mapToNewTokenSelectorGroupedSectionWrapperViewModel(
                    wallet: wallet,
                    items: values
                )

                return wrapperViewModel
            }

            return .walletsWithAccounts(wrapped)
        }

        let wallets: [NewTokenSelectorGroupedSectionViewModel] = list
            .mapValues { $0.values.flattened() }
            .map { wallet, values in
                let wrapperViewModel = mapToNewTokenSelectorGroupedSectionViewModel(
                    wallet: wallet,
                    items: values
                )

                return wrapperViewModel
            }

        return .wallets(wallets)
    }

    private func mapToNewTokenSelectorGroupedSectionWrapperViewModel(
        wallet: NewTokenSelectorItem.Wallet,
        items: [NewTokenSelectorItem.Account: [NewTokenSelectorItem]]
    ) -> NewTokenSelectorGroupedSectionWrapperViewModel {
        let sections = items.map { account, items in
            mapToNewTokenSelectorGroupedSectionViewModel(account: account, items: items)
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
        NewTokenSelectorItemViewModel(
            id: .init(tokenItem: item.tokenItem),
            name: item.tokenItem.name,
            symbol: item.tokenItem.currencySymbol,
            tokenIconInfo: TokenIconInfoBuilder().build(from: item.tokenItem, isCustom: false),
            disabledReason: .none,
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
