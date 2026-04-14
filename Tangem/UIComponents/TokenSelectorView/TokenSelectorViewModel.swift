//
//  TokenSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAccounts
import TangemFoundation
import TangemMacro

final class TokenSelectorViewModel: ObservableObject {
    @Published var searchText: String = ""

    @Published private(set) var wallets: [TokenSelectorWalletItemViewModel]
    @Published private(set) var contentVisibility: ContentVisibility = .visible(itemsCount: 0)
    @Published private(set) var scrollToTopTrigger: UUID?

    private let walletsProvider: any TokenSelectorWalletsProvider
    private let availabilityProvider: any TokenSelectorItemAvailabilityProvider

    private let viewModelsMapper: TokenSelectorViewModelsMapper
    private var bag: Set<AnyCancellable> = []

    init(
        walletsProvider: any TokenSelectorWalletsProvider,
        availabilityProvider: any TokenSelectorItemAvailabilityProvider,
        collapsibleAccounts: Bool = false,
        expandedStateStorage: (any TokenSelectorExpandedStateStorage)? = nil
    ) {
        self.walletsProvider = walletsProvider
        self.availabilityProvider = availabilityProvider

        viewModelsMapper = TokenSelectorViewModelsMapper(
            walletsProvider: walletsProvider,
            availabilityProvider: availabilityProvider,
            collapsibleAccounts: collapsibleAccounts,
            expandedStateStorage: expandedStateStorage
        )

        wallets = viewModelsMapper.wallets

        viewModelsMapper.setupSearchable(searchTextPublisher: $searchText.eraseToAnyPublisher())
        bind()
    }

    func setup(with output: TokenSelectorViewModelOutput?) {
        viewModelsMapper.setup(with: output)
    }

    func setup(directionPublisher: some Publisher<TokenSelectorItemSwapAvailabilityProvider.SwapDirection?, Never>) {
        guard let availabilityProvider = (availabilityProvider as? TokenSelectorItemSwapAvailabilityProvider) else {
            assertionFailure("setup(directionPublisher:) called with incompatible availabilityProvider")
            return
        }

        availabilityProvider.setup(directionPublisher: directionPublisher)
        viewModelsMapper.setupSelectedItemFilter(selectedItemPublisher: directionPublisher.map { $0?.tokenItem })
    }

    func triggerScrollToTop() {
        scrollToTopTrigger = UUID()
    }

    func setLoading() {
        contentVisibility = .loading
    }

    func itemsCountToDisplay(configuration: SectionHeaderConfiguration, itemsCount: Int) -> Int? {
        guard configuration.showsItemsCount, !searchText.isEmpty, itemsCount > 0 else { return nil }

        return itemsCount
    }

    private func bind() {
        // Scroll to top when search text transitions between empty and non-empty (both directions)
        $searchText
            .pairwise()
            .filter { previous, current in previous.isEmpty != current.isEmpty }
            .sink { [weak self] _ in
                self?.triggerScrollToTop()
            }
            .store(in: &bag)

        // Collect items count from all wallets and compute visibility
        wallets
            .map { $0.$viewType.flatMapLatest { $0.itemsCount } }
            .combineLatest()
            .map { counts -> ContentVisibility in
                let totalCount = counts.sum()
                return totalCount == 0 ? .empty : .visible(itemsCount: totalCount)
            }
            .removeDuplicates()
            .assign(to: &$contentVisibility)
    }
}

// MARK: - ContentVisibility

extension TokenSelectorViewModel {
    @CaseFlagable
    enum ContentVisibility: Equatable {
        case loading
        case visible(itemsCount: Int)
        case empty
    }
}

extension TokenSelectorViewModel {
    struct SectionHeaderConfiguration {
        let title: String
        let showsItemsCount: Bool

        init(title: String, showsItemsCount: Bool = false) {
            self.title = title
            self.showsItemsCount = showsItemsCount
        }
    }
}
