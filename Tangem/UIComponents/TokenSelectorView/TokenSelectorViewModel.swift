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
    @Published var selectedChipId: String?

    @Published private(set) var wallets: [TokenSelectorWalletItemViewModel]
    @Published private(set) var walletChips: [WalletChipData] = []
    @Published private(set) var contentVisibility: ContentVisibility = .empty
    @Published private(set) var scrollToTopTrigger: UUID?

    private let walletsProvider: any TokenSelectorWalletsProvider
    private let availabilityProvider: any TokenSelectorItemAvailabilityProvider
    private weak var tokenSelectorStateStorage: (any TokenSelectorStateStorage)?

    private let viewModelsMapper: TokenSelectorViewModelsMapper
    private var walletFilterSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        walletsProvider: any TokenSelectorWalletsProvider,
        availabilityProvider: any TokenSelectorItemAvailabilityProvider,
        collapsibleAccounts: Bool = false,
        tokenSelectorStateStorage: (any TokenSelectorStateStorage)? = nil,
        currentWalletId: UserWalletId? = nil,
        initialSelectedItem: TokenItem? = nil
    ) {
        self.walletsProvider = walletsProvider
        self.availabilityProvider = availabilityProvider
        self.tokenSelectorStateStorage = tokenSelectorStateStorage

        viewModelsMapper = TokenSelectorViewModelsMapper(
            walletsProvider: walletsProvider,
            availabilityProvider: availabilityProvider,
            collapsibleAccounts: collapsibleAccounts,
            tokenSelectorStateStorage: tokenSelectorStateStorage
        )

        // Pre-filter items before creating wallet VMs so the initial render is already correct
        viewModelsMapper.setInitialSelectedItem(initialSelectedItem)

        wallets = viewModelsMapper.wallets

        contentVisibility = .empty

        viewModelsMapper.setupSearchable(searchTextPublisher: $searchText.eraseToAnyPublisher())
        setupWalletFilter(currentWalletId: currentWalletId)
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
            .map { $0.viewType.itemsCount }
            .combineLatest()
            .map { counts -> ContentVisibility in
                let totalCount = counts.sum()
                return totalCount == 0 ? .empty : .visible(itemsCount: totalCount)
            }
            .removeDuplicates()
            .assign(to: &$contentVisibility)
    }

    private func setupWalletFilter(currentWalletId: UserWalletId? = nil) {
        guard wallets.count >= 2 else {
            walletChips = []
            selectedChipId = nil
            updateWalletVisibility(selectedId: nil)
            walletFilterSubscription = nil
            return
        }

        walletChips = wallets.map { WalletChipData(id: $0.walletId.stringValue, name: $0.walletName) }

        let chipIds = walletChips.map(\.id)

        let selectedWalletId: String?
        if let stored = tokenSelectorStateStorage?.selectedWalletId?.stringValue, chipIds.contains(stored) {
            selectedWalletId = stored
        } else if let currentWalletId, chipIds.contains(currentWalletId.stringValue) {
            selectedWalletId = currentWalletId.stringValue
        } else {
            selectedWalletId = walletChips.first?.id
        }

        selectedChipId = selectedWalletId

        updateWalletVisibility(selectedId: selectedWalletId)

        walletFilterSubscription = $selectedChipId
            .dropFirst()
            .sink { [weak self] chipId in
                guard let self else { return }
                let walletId = wallets.first { $0.walletId.stringValue == chipId }?.walletId
                tokenSelectorStateStorage?.selectedWalletId = walletId
                updateWalletVisibility(selectedId: chipId)
            }
    }

    private func updateWalletVisibility(selectedId: String?) {
        guard let selectedId else {
            wallets.forEach { $0.update(isFilteredOut: false) }
            return
        }
        for wallet in wallets {
            wallet.update(isFilteredOut: wallet.walletId.stringValue != selectedId)
        }
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
        let id: String
        let name: String
    }
}

// MARK: - Factory

extension TokenSelectorViewModel {
    static func common(
        walletsProvider: any TokenSelectorWalletsProvider = .common(),
        availabilityProvider: any TokenSelectorItemAvailabilityProvider,
        initialSelectedItem: TokenItem? = nil
    ) -> TokenSelectorViewModel {
        @Injected(\.tokenSelectorStateStorage)
        var stateStorage: TokenSelectorStateStorage

        @Injected(\.userWalletRepository)
        var userWalletRepository: UserWalletRepository

        return TokenSelectorViewModel(
            walletsProvider: walletsProvider,
            availabilityProvider: availabilityProvider,
            collapsibleAccounts: true,
            tokenSelectorStateStorage: stateStorage,
            currentWalletId: userWalletRepository.selectedModel?.userWalletId,
            initialSelectedItem: initialSelectedItem
        )
    }
}
