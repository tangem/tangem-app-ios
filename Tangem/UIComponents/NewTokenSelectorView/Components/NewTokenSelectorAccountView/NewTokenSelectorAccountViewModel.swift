//
//  NewTokenSelectorAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAccounts

final class NewTokenSelectorAccountViewModel: ObservableObject, Identifiable {
    let header: HeaderType
    @Published private(set) var items: [NewTokenSelectorItemViewModel]?

    private let account: NewTokenSelectorAccount
    private let searchTextPublisher: AnyPublisher<String, Never>
    private let mapper: any NewTokenSelectorItemViewModelMapper

    private var itemsSubscription: AnyCancellable?

    init(
        header: HeaderType,
        account: NewTokenSelectorAccount,
        searchTextPublisher: AnyPublisher<String, Never>,
        mapper: any NewTokenSelectorItemViewModelMapper,
    ) {
        self.header = header
        self.account = account
        self.searchTextPublisher = searchTextPublisher
        self.mapper = mapper

        bind()
    }

    private func bind() {
        itemsSubscription = account.itemsPublisher
            .combineLatest(searchTextPublisher.map { $0.trimmed() })
            .map { items, searchText in
                if searchText.isEmpty {
                    return items
                }

                return items.filter { $0.isMatching(searchText: searchText) }
            }
            .withWeakCaptureOf(self)
            .map { $0.mapToNewTokenSelectorItemViewModels(items: $1) }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink(receiveValue: { viewModel, items in
                withAnimation(.easeInOut) { viewModel.items = items }
            })
    }

    private func mapToNewTokenSelectorItemViewModels(items: [NewTokenSelectorItem]) -> [NewTokenSelectorItemViewModel] {
        items.map { item in
            mapper.mapToNewTokenSelectorItemViewModel(item: item)
        }
    }
}

extension NewTokenSelectorAccountViewModel {
    enum HeaderType: Hashable {
        case wallet(String)
        case account(icon: AccountIconView.ViewData, name: String)
    }
}
