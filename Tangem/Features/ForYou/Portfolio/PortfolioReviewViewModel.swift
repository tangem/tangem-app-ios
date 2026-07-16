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

    private var expandedIds: Set<String> = []
    private var bag: Set<AnyCancellable> = []

    // MARK: - Published

    @Published private(set) var state: ViewState = .init(tokenList: [], periodSegments: ForYouPeriodSegment.all)
    @Published var selectedPeriod: ForYouPeriodSegment = .initial

    // MARK: - Init

    init(mapper: PortfolioReviewMapper = PortfolioReviewMapper()) {
        self.mapper = mapper
        bind()
    }

    // MARK: - Methods

    func toggle(id: String) {
        expandedIds.formSymmetricDifference([id])
        state = state.expanding(expandedIds)
    }
}

// MARK: - Data flow

private extension PortfolioReviewViewModel {
    func bind() {
        selectedModelPublisher()
            .withWeakCaptureOf(self)
            .map { viewModel, selectedModel in
                viewModel.statePublisher(for: selectedModel)
            }
            .switchToLatest()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.apply(state)
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

    /// Wallet models + total balance + app currency → mapped view state.
    func statePublisher(for selectedModel: UserWalletModel?) -> AnyPublisher<ViewState, Never> {
        guard let selectedModel else {
            // No selected wallet → empty list (not an endless loading state).
            return Just(ViewState(tokenList: [], periodSegments: ForYouPeriodSegment.all))
                .eraseToAnyPublisher()
        }

        // `totalBalancePublisher` is here purely as a trigger: it re-fires as per-model balances resolve,
        // which is what drives the loading → content transition (the wallet-models publisher itself does
        // not re-emit on balance changes). The percent denominator is derived inside the mapper.
        return Publishers.CombineLatest3(
            AccountWalletModelsAggregator.walletModelsPublisher(from: selectedModel.accountModelsManager),
            selectedModel.totalBalancePublisher,
            AppSettings.shared.$selectedCurrencyCode
        )
        .map { [mapper] walletModels, _, _ in
            mapper.map(walletModels: walletModels)
        }
        .eraseToAnyPublisher()
    }

    func apply(_ newState: ViewState) {
        // Expansion is driven solely by user taps; re-apply it onto every fresh emission.
        state = newState.expanding(expandedIds)
    }
}

// MARK: - Expansion

private extension PortfolioReviewViewModel.ViewState {
    /// Re-derives each item's `isExpanded` flag from the currently expanded asset ids.
    func expanding(_ expandedIds: Set<String>) -> Self {
        Self(
            tokenList: tokenList.map { $0.updating(isExpanded: expandedIds.contains($0.id)) },
            periodSegments: periodSegments
        )
    }
}

// MARK: - Private helpers

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
