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
    private let analyticsLogger: PortfolioReviewAnalyticsLogger

    private weak var router: PortfolioReviewRoutable?

    private var expandedIds: Set<String> = []
    private var subscription: AnyCancellable?
    private var periodAnalyticsSubscription: AnyCancellable?

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
        analyticsLogger: PortfolioReviewAnalyticsLogger,
        router: PortfolioReviewRoutable? = nil
    ) {
        self.mapper = mapper
        self.selectionScopePublisher = selectionScopePublisher
        self.indicatorsProvider = indicatorsProvider
        self.analyticsLogger = analyticsLogger
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

    /// The diagram is decorative, so every tap on a slice counts — including re-taps on the selected one.
    func chartSegmentTapped() {
        analyticsLogger.logDiagramTap()
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
        bindPeriodAnalytics()

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

    /// `dropFirst` skips the initial period so only user-driven changes are reported.
    func bindPeriodAnalytics() {
        periodAnalyticsSubscription = $selectedPeriod
            .map(\.period)
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, period in
                viewModel.analyticsLogger.logFilterInterval(period: period)
            }
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

        let tokenItemsPublisher = selectedAccounts
            .map(Self.tokenItemsPublisher)
            .switchToLatest()
            .share(replay: 1)
            .eraseToAnyPublisher()

        return Publishers.CombineLatest3(
            tokenItemsPublisher,
            totalBalancePublisher(for: selectedAccounts),
            AppSettings.shared.$selectedCurrencyCode
        )
        .combineLatest(
            indicatorsPublisher(for: tokenItemsPublisher),
            $selectedPeriod.map(\.timeframe).removeDuplicates()
        )
        .map { [mapper] base, indicators, timeframe in
            let (tokenItems, totalBalance, _) = base
            let mapped = mapper.map(
                tokenItems: tokenItems,
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

    /// Going by the stored list, not the wallet models, is what keeps not-yet-derived tokens on screen.
    static func tokenItemsPublisher(for accounts: [any CryptoAccountModel]) -> AnyPublisher<[TokenItemType], Never> {
        guard !accounts.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        return accounts
            .map { account in
                account.walletModelsManager.walletModelsPublisher
                    .combineLatest(account.userTokensManager.userTokensPublisher)
                    .map { walletModels, userTokens in
                        PortfolioReviewTokenItemsResolver.resolve(userTokens: userTokens, walletModels: walletModels)
                    }
                    .eraseToAnyPublisher()
            }
            .combineLatest()
            .map { $0.flattened() }
            .eraseToAnyPublisher()
    }

    /// Refetches only when the symbol set changes; starts empty so the pipeline isn't gated on it.
    func indicatorsPublisher(
        for tokenItemsPublisher: AnyPublisher<[TokenItemType], Never>
    ) -> AnyPublisher<[String: [TokenSummaryIndicator]], Never> {
        tokenItemsPublisher
            .map { tokenItems in
                Set(tokenItems.map { $0.tokenItem.currencySymbol.uppercased() })
            }
            .removeDuplicates()
            .map { [indicatorsProvider] symbols in
                Future<[String: [TokenSummaryIndicator]], Never>.async {
                    do {
                        return try await indicatorsProvider.loadIndicators(symbols: Array(symbols))
                    } catch {
                        AppLogger.error("Failed to load Portfolio Review indicators", error: error)
                        return [:]
                    }
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

private extension TokenItemType {
    var tokenItem: TokenItem {
        switch self {
        case .default(let walletModel): walletModel.tokenItem
        case .withoutDerivation(let tokenItem): tokenItem
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
