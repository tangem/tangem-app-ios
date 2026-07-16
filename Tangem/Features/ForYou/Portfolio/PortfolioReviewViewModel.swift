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
    // MARK: - Published

    @Published private(set) var state: ViewState = .loading
    @Published var selectedPeriod: ForYouPeriodSegment = .initial

    // MARK: - Properties

    private let dataSource = MockForYouPortfolioDataSource()
    private var expandedIds: Set<String> = []
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init() {
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
}

// MARK: - Bind

private extension PortfolioReviewViewModel {
    func bind() {
        dataSource.statePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.apply(state)
            }
            .store(in: &bag)
    }

    func apply(_ newState: ViewState) {
        // Seed expansion from the first content; user taps drive it afterwards.
        if expandedIds.isEmpty, case .content(let content) = newState {
            expandedIds = Set(content.tokenList.filter(\.isExpanded).map(\.id))
        }

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
            return .content(Content(tokenList: tokenList, periodSegments: content.periodSegments))
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
