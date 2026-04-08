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
    @Published var selectedWalletId: UserWalletId?

    @Published private(set) var wallets: [TokenSelectorWalletItemViewModel]
    @Published private(set) var walletChips: [WalletChipData] = []
    @Published private(set) var contentVisibility: ContentVisibility = .visible(itemsCount: 0)
    @Published private(set) var scrollToTopTrigger: UUID?

    private let walletsProvider: any TokenSelectorWalletsProvider
    private let availabilityProvider: any TokenSelectorItemAvailabilityProvider
    private weak var expandedStateStorage: (any TokenSelectorExpandedStateStorage)?

    private let viewModelsMapper: TokenSelectorViewModelsMapper
    private var bag: Set<AnyCancellable> = []

    init(
        walletsProvider: any TokenSelectorWalletsProvider,
        availabilityProvider: any TokenSelectorItemAvailabilityProvider,
        collapsibleAccounts: Bool = false,
        expandedStateStorage: (any TokenSelectorExpandedStateStorage)? = nil,
        initialSelectedItem: TokenItem? = nil
    ) {
        self.walletsProvider = walletsProvider
        self.availabilityProvider = availabilityProvider
        self.expandedStateStorage = expandedStateStorage

        viewModelsMapper = TokenSelectorViewModelsMapper(
            walletsProvider: walletsProvider,
            availabilityProvider: availabilityProvider,
            collapsibleAccounts: collapsibleAccounts,
            expandedStateStorage: expandedStateStorage
        )

        // Pre-filter items before creating wallet VMs so the initial render is already correct
        viewModelsMapper.setInitialSelectedItem(initialSelectedItem)

        wallets = viewModelsMapper.wallets

        // Set initial contentVisibility synchronously so the Combine pipeline's first emission
        // is a duplicate and gets filtered by removeDuplicates(), preventing animation triggers
        let initialTotal = wallets.reduce(0) { total, wallet in
            switch wallet.viewType {
            case .wallet(let account): total + account.items.count
            case .accounts(_, let accounts): total + accounts.reduce(0) { $0 + $1.items.count }
            }
        }
        contentVisibility = initialTotal == 0 ? .empty : .visible(itemsCount: initialTotal)

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

    func setupWalletFilter(currentWalletId: UserWalletId? = nil) {
        // Always suppress collapsible wallet headers
        for wallet in wallets {
            wallet.hideWalletHeader = true
        }

        let walletsWithContent = wallets.filter { wallet in
            switch wallet.viewType {
            case .wallet(let account):
                return !account.items.isEmpty
            case .accounts(_, let accounts):
                return accounts.contains { !$0.items.isEmpty }
            }
        }

        guard walletsWithContent.count >= 2 else {
            walletChips = []
            return
        }

        walletChips = walletsWithContent.map { WalletChipData(id: $0.walletId, name: $0.walletName) }

        let chipIds = walletChips.map(\.id)

        // Restore persisted selection, fall back to current wallet, then first chip
        if let stored = expandedStateStorage?.selectedWalletId, chipIds.contains(stored) {
            selectedWalletId = stored
        } else if let currentWalletId, chipIds.contains(currentWalletId) {
            selectedWalletId = currentWalletId
        } else {
            selectedWalletId = walletChips.first?.id
        }

        // Apply initial filter
        updateWalletVisibility(selectedId: selectedWalletId)

        // React to selection changes: persist and update visibility
        $selectedWalletId
            .dropFirst()
            .sink { [weak self] walletId in
                self?.expandedStateStorage?.selectedWalletId = walletId
                self?.updateWalletVisibility(selectedId: walletId)
            }
            .store(in: &bag)
    }

    private func updateWalletVisibility(selectedId: UserWalletId?) {
        guard let selectedId else {
            wallets.forEach { $0.isFilteredOut = false }
            return
        }
        for wallet in wallets {
            wallet.isFilteredOut = wallet.walletId != selectedId
        }
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

    struct WalletChipData: Identifiable {
        let id: UserWalletId
        let name: String
    }
}
