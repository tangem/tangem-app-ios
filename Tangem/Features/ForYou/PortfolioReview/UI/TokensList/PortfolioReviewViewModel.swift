//
//  PortfolioReviewViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine
import CombineExt

final class PortfolioReviewViewModel: ObservableObject {
    // MARK: - Typealias

    typealias SelectionScopePublisher = ForYouAccountSelectionResolver.SelectionScopePublisher

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Properties

    private let mapper: PortfolioReviewMapper
    private let selectionScopePublisher: SelectionScopePublisher
    private let indicatorsProvider: PortfolioReviewIndicatorsProvider

    private weak var router: PortfolioReviewRoutable?

    private var expandedIds: Set<String> = []
    private var subscription: AnyCancellable?

    // MARK: - Publishers

    @Published private(set) var state: ViewState = .loading
    @Published private(set) var showsOutdatedDataBanner = false

    @Published var selectedPeriod: ForYouPeriodSegment = .initial
    @Published var selectedChartSegmentID: GaugeSegment.ID?

    // MARK: - Init

    init(
        mapper: PortfolioReviewMapper = PortfolioReviewMapper(),
        selectionScopePublisher: SelectionScopePublisher,
        indicatorsProvider: PortfolioReviewIndicatorsProvider = CommonPortfolioReviewIndicatorsProvider(),
        router: PortfolioReviewRoutable? = nil
    ) {
        self.mapper = mapper
        self.selectionScopePublisher = selectionScopePublisher
        self.indicatorsProvider = indicatorsProvider
        self.router = router

        bind()
    }

    // MARK: - Internal methods

    func toggle(id: String) {
        guard case .content(let content) = state,
              content.tokenList.first(where: { $0.id == id })?.isExpandable == true else {
            return
        }

        expandedIds.formSymmetricDifference([id])
        state = state.expanding(expandedIds)
    }

    @MainActor
    func selectToken(id: String) {
        // Aggregate/unmapped rows (e.g. "Other") carry no concrete token — tapping them is a no-op.
        guard let tokenItem = tokenItem(for: id) else {
            return
        }

        router?.openTokenSummary(tokenItem: tokenItem, period: selectedPeriod.period)
    }

    private func tokenItem(for id: String) -> TokenItem? {
        guard case .content(let content) = state else {
            return nil
        }

        for item in content.tokenList {
            if item.assetRow.id == id {
                return item.assetRow.tokenItem
            }

            if let row = item.networkRows.first(where: { $0.id == id }) {
                return row.tokenItem
            }
        }

        return nil
    }

    @MainActor
    func addFundsTapped() {
        let preferredWalletId = userWalletRepository.selectedModel?.userWalletId
        router?.openAddFunds(userWalletModels: userWalletRepository.models, preferredWalletId: preferredWalletId)
    }
}

// MARK: - Data flow

private extension PortfolioReviewViewModel {
    func bind() {
        subscription = selectedModelPublisher()
            // Rebuild only when wallet presence flips; dedup the bare Bool — a self-carrying tuple in removeDuplicates would leak.
            .map { $0 != nil }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, hasSelectedWallet in
                viewModel.statePublisher(hasSelectedWallet: hasSelectedWallet)
            }
            .switchToLatest()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                viewModel.showsOutdatedDataBanner = output.isOutdatedData
                viewModel.apply(output.state)
            }
    }

    func selectedModelPublisher() -> AnyPublisher<UserWalletModel?, Never> {
        userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .map { viewModel, _ in
                viewModel.userWalletRepository.selectedModel
            }
            .prepend(userWalletRepository.selectedModel)
            .removeDuplicates {
                $0?.userWalletId == $1?.userWalletId
            }
            .eraseToAnyPublisher()
    }

    func statePublisher(hasSelectedWallet: Bool) -> AnyPublisher<(state: ViewState, isOutdatedData: Bool), Never> {
        guard hasSelectedWallet else {
            // No selected wallet → empty content (not an endless loading state).
            return Just(
                (
                    state: .content(.init(tokenList: [], periodSegments: ForYouPeriodSegment.all, chart: .noData(.cantLoad), showsAddFunds: false)),
                    isOutdatedData: false
                )
            )
            .eraseToAnyPublisher()
        }

        // Shared once: a single cross-wallet subscription feeds the total balance, the token list, and the indicators.
        let selectedAccounts = selectionScopePublisher
            .map { $0.selected.map(\.account) }
            .share(replay: 1)
            .eraseToAnyPublisher()

        let walletModelsPublisher = selectedAccounts
            .map(Self.walletModelsPublisher)
            .switchToLatest()
            .share(replay: 1)
            .eraseToAnyPublisher()

        return Publishers.CombineLatest3(
            walletModelsPublisher,
            totalBalancePublisher(for: selectedAccounts),
            AppSettings.shared.$selectedCurrencyCode
        )
        .combineLatest(
            indicatorsPublisher(for: walletModelsPublisher),
            $selectedPeriod.map(\.timeframe).removeDuplicates()
        )
        .map { [mapper] base, indicators, timeframe in
            let (walletModels, totalBalance, _) = base
            let mapped = mapper.map(
                walletModels: walletModels,
                totalBalance: totalBalance,
                indicators: indicators,
                timeframe: timeframe
            )
            return (
                state: mapped.state,
                isOutdatedData: PortfolioReviewOutdatedDataResolver.isOutdated(
                    totalBalance,
                    displayedItems: mapped.displayedTokenItems
                )
            )
        }
        .eraseToAnyPublisher()
    }

    /// Sums the selected accounts' fiat totals into one state (loading/failed if any is; loaded sum otherwise).
    func totalBalancePublisher(for accounts: AnyPublisher<[any CryptoAccountModel], Never>) -> AnyPublisher<TotalBalanceState, Never> {
        accounts
            .map { accounts -> AnyPublisher<TotalBalanceState, Never> in
                guard !accounts.isEmpty else {
                    return Just(.loaded(balance: 0)).eraseToAnyPublisher()
                }

                return accounts
                    .map(\.fiatTotalBalanceProvider.totalBalancePublisher)
                    .combineLatest()
                    .map { TotalBalanceStatesCombiner().mapToTotalBalanceState(states: $0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    /// Wallet models of the given accounts; no accounts → `[]` (`combineLatest` of nothing never emits).
    static func walletModelsPublisher(for accounts: [any CryptoAccountModel]) -> AnyPublisher<[any WalletModel], Never> {
        guard !accounts.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        return accounts
            .map(\.walletModelsManager.walletModelsPublisher)
            .combineLatest()
            .map { $0.flattened() }
            .eraseToAnyPublisher()
    }

    /// Refetches only when the symbol set changes; starts empty so the pipeline isn't gated on it.
    func indicatorsPublisher(
        for walletModelsPublisher: AnyPublisher<[any WalletModel], Never>
    ) -> AnyPublisher<[String: [TokenSummaryIndicator]], Never> {
        walletModelsPublisher
            .map { walletModels in
                Set(walletModels.map { $0.tokenItem.currencySymbol.uppercased() })
            }
            .removeDuplicates()
            .map { [indicatorsProvider] symbols in
                Future<[String: [TokenSummaryIndicator]], Never>.async {
                    (try? await indicatorsProvider.loadIndicators(symbols: Array(symbols))) ?? [:]
                }
            }
            .switchToLatest()
            .prepend([String: [TokenSummaryIndicator]]())
            .eraseToAnyPublisher()
    }

    func apply(_ newState: ViewState) {
        state = newState.expanding(expandedIds)

        // A scope change can drop the selected segment — clear it so the tooltip doesn't resurrect later.
        if let selectedID = selectedChartSegmentID, !newState.containsChartSegment(selectedID) {
            selectedChartSegmentID = nil
        }
    }
}

// MARK: - ViewState helpers

private extension PortfolioReviewViewModel.ViewState {
    func containsChartSegment(_ id: GaugeSegment.ID) -> Bool {
        guard case .content(let content) = self, case .loaded(let assets, _, _) = content.chart else {
            return false
        }

        return assets.contains { $0.id == id }
    }

    func expanding(_ expandedIds: Set<String>) -> Self {
        switch self {
        case .loading:
            return self
        case .content(let content):
            let tokenList = content.tokenList.map { $0.updating(isExpanded: expandedIds.contains($0.id)) }
            return .content(Content(tokenList: tokenList, periodSegments: content.periodSegments, chart: content.chart, showsAddFunds: content.showsAddFunds))
        }
    }
}

private extension ForYouTokenListItem {
    func updating(isExpanded: Bool) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: id,
            assetRow: assetRow,
            networkRows: networkRows,
            isExpanded: isExpanded,
            isExpandable: isExpandable
        )
    }
}
