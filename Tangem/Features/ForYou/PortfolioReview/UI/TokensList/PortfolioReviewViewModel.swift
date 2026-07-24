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

final class PortfolioReviewViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Properties

    private let mapper: PortfolioReviewMapper

    private weak var router: PortfolioReviewRoutable?

    private var expandedIds: Set<String> = []
    private var bag: Set<AnyCancellable> = []

    // MARK: - Published

    @Published private(set) var state: ViewState = .loading
    @Published private(set) var showsOutdatedDataBanner = false

    @Published var selectedPeriod: ForYouPeriodSegment = .initial
    @Published var selectedChartSegmentID: GaugeSegment.ID?

    // MARK: - Init

    init(mapper: PortfolioReviewMapper = PortfolioReviewMapper(), router: PortfolioReviewRoutable? = nil) {
        self.mapper = mapper
        self.router = router

        bind()
    }

    // MARK: - Methods

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

        let sourceWalletId = userWalletRepository.selectedModel?.userWalletId
        router?.openTokenSummary(tokenItem: tokenItem, sourceWalletId: sourceWalletId)
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
        selectedModelPublisher()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { viewModel, _ in
                // New wallet → drop the previous wallet's expansion and chart selection (ids collide across
                // wallets, e.g. shared currencyId).
                viewModel.expandedIds.removeAll()
                viewModel.selectedChartSegmentID = nil
            })
            .map { viewModel, selectedModel in
                viewModel.statePublisher(for: selectedModel)
            }
            .switchToLatest()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                viewModel.showsOutdatedDataBanner = output.isOutdatedData
                viewModel.apply(output.state)
            }
            .store(in: &bag)
    }

    /// The selected wallet, re-emitted whenever the repository's selection changes.
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

    /// Wallet models + total balance + app currency → mapped view state + outdated-data flag.
    func statePublisher(
        for selectedModel: UserWalletModel?
    ) -> AnyPublisher<(state: ViewState, isOutdatedData: Bool), Never> {
        guard let selectedModel else {
            // No selected wallet → empty content (not an endless loading state).
            return Just(
                (
                    state: .content(.init(tokenList: [], periodSegments: ForYouPeriodSegment.all, chart: .noData(.cantLoad), showsAddFunds: false)),
                    isOutdatedData: false
                )
            )
            .eraseToAnyPublisher()
        }

        // `totalBalancePublisher` gates skeleton → content/empty, re-fires as balances resolve
        // (the wallet-models publisher itself does not re-emit on balance changes), and feeds the outdated-data flag.
        return Publishers.CombineLatest3(
            AccountWalletModelsAggregator.walletModelsPublisher(from: selectedModel.accountModelsManager),
            selectedModel.totalBalancePublisher,
            AppSettings.shared.$selectedCurrencyCode
        )
        .map { [mapper] walletModels, totalBalance, _ in
            let mapped = mapper.map(walletModels: walletModels, totalBalance: totalBalance)
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

    func apply(_ newState: ViewState) {
        state = newState.expanding(expandedIds)
    }
}

// MARK: - Expansion

private extension PortfolioReviewViewModel.ViewState {
    /// Re-derives each item's `isExpanded` flag from the currently expanded asset ids.
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
