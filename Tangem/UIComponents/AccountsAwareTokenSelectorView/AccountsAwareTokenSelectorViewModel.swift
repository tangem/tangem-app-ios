//
//  AccountsAwareTokenSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts
import TangemFoundation
import BlockchainSdk

final class AccountsAwareTokenSelectorViewModel: ObservableObject {
    @Published var searchText: String = ""

    @Published private(set) var wallets: [AccountsAwareTokenSelectorWalletItemViewModel]
    @Published private(set) var contentVisibility: ContentVisibility = .visible

    // MARK: - External Search (for Express all tokens search)

    @Published private(set) var externalSearchResults: [MarketTokenItemViewModel] = []
    @Published private(set) var isSearchingExternal: Bool = false

    private let walletsProvider: any AccountsAwareTokenSelectorWalletsProvider
    private let availabilityProvider: any AccountsAwareTokenSelectorItemAvailabilityProvider
    private let externalSearchProvider: ExpressSearchTokensProvider?

    private let viewModelsMapper: AccountsAwareTokenSelectorViewModelsMapper

    // Markets dependencies for external search results display
    private lazy var chartsProvider = MarketsListChartsHistoryProvider()
    private lazy var filterProvider = MarketsListDataFilterProvider()
    private lazy var marketCapFormatter = MarketCapFormatter(
        divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
        baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
        notationFormatter: .init()
    )

    private var externalSearchTask: Task<Void, Never>?
    private var externalSearchCancellable: AnyCancellable?

    private weak var externalTokenSelectionHandler: ExpressExternalTokenSelectionHandler?

    init(
        walletsProvider: any AccountsAwareTokenSelectorWalletsProvider,
        availabilityProvider: any AccountsAwareTokenSelectorItemAvailabilityProvider,
        externalSearchProvider: ExpressSearchTokensProvider? = nil
    ) {
        self.walletsProvider = walletsProvider
        self.availabilityProvider = availabilityProvider
        self.externalSearchProvider = externalSearchProvider

        viewModelsMapper = AccountsAwareTokenSelectorViewModelsMapper(
            walletsProvider: walletsProvider,
            availabilityProvider: availabilityProvider
        )

        wallets = viewModelsMapper.wallets

        viewModelsMapper.setupSearchable(searchTextPublisher: $searchText.eraseToAnyPublisher())
        bind()

        if externalSearchProvider != nil {
            bindExternalSearch()
        }
    }

    func setup(with output: AccountsAwareTokenSelectorViewModelOutput?) {
        viewModelsMapper.setup(with: output)
    }

    func setup(directionPublisher: some Publisher<AccountsAwareTokenSelectorItemSwapAvailabilityProvider.SwapDirection?, Never>) {
        guard let availabilityProvider = (availabilityProvider as? AccountsAwareTokenSelectorItemSwapAvailabilityProvider) else {
            assertionFailure("setup(directionPublisher:) called with incompatible availabilityProvider")
            return
        }

        availabilityProvider.setup(directionPublisher: directionPublisher)
        viewModelsMapper.setupSelectedItemFilter(selectedItemPublisher: directionPublisher.map { $0?.tokenItem })
    }

    func setup(externalTokenSelectionHandler: ExpressExternalTokenSelectionHandler?) {
        self.externalTokenSelectionHandler = externalTokenSelectionHandler
    }

    private func bind() {
        // Collect visibility states from all wallets
        wallets
            .map { $0.$contentVisibility }
            .combineLatest()
            .removeDuplicates()
            .map { $0.allConforms { $0 == .empty } ? .empty : .visible }
            .removeDuplicates()
            .assign(to: &$contentVisibility)
    }

    private func bindExternalSearch() {
        externalSearchCancellable = $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performExternalSearch(text: text)
            }
    }

    private func performExternalSearch(text: String) {
        externalSearchTask?.cancel()

        guard let externalSearchProvider, text.count >= 2 else {
            externalSearchResults = []
            isSearchingExternal = false
            return
        }

        isSearchingExternal = true

        externalSearchTask = Task { [weak self] in
            guard let self else { return }

            do {
                let tokens = try await externalSearchProvider.search(text: text)

                guard !Task.isCancelled else { return }

                // Fetch chart data for the tokens
                let tokenIds = tokens.map(\.id)
                chartsProvider.fetch(for: tokenIds, with: filterProvider.currentFilterValue.interval)

                await MainActor.run {
                    self.externalSearchResults = tokens.map { token in
                        self.makeMarketsItemViewModel(token: token)
                    }
                    self.isSearchingExternal = false
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.externalSearchResults = []
                    self.isSearchingExternal = false
                }
            }
        }
    }

    private func makeMarketsItemViewModel(token: MarketsTokenModel) -> MarketTokenItemViewModel {
        MarketTokenItemViewModel(
            tokenModel: token,
            marketCapFormatter: marketCapFormatter,
            chartsProvider: chartsProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.externalTokenSelectionHandler?.didSelectExternalToken(token)
            }
        )
    }
}

// MARK: - ContentVisibility

extension AccountsAwareTokenSelectorViewModel {
    enum ContentVisibility: Equatable {
        case visible
        case empty
    }
}

// MARK: - ExpressExternalTokenSelectionHandler

protocol ExpressExternalTokenSelectionHandler: AnyObject {
    func didSelectExternalToken(_ token: MarketsTokenModel)
}
