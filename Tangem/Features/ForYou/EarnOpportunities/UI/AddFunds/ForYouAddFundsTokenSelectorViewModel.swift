//
//  ForYouAddFundsTokenSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import CombineExt
import TangemFoundation
import TangemUI
import TangemAccounts

@MainActor
final class ForYouAddFundsTokenSelectorViewModel: ObservableObject {
    typealias SelectionAction = (any WalletModel, any UserWalletModel) -> Void

    // MARK: - Properties

    private let holdings: [Holding]
    private let selectionAction: SelectionAction
    private let closeAction: () -> Void

    // MARK: - Publishers

    @Published private(set) var sections: [Section] = []

    // MARK: - Init

    init(
        holdings: [Holding],
        selectionAction: @escaping SelectionAction,
        closeAction: @escaping () -> Void
    ) {
        self.holdings = holdings
        self.selectionAction = selectionAction
        self.closeAction = closeAction

        sections = makeSections()
        bind()
    }

    // MARK: - Public action

    func close() {
        closeAction()
    }
}

// MARK: - Types

extension ForYouAddFundsTokenSelectorViewModel {
    struct Section: Identifiable {
        let id: String
        let accountIcon: AccountIconView.ViewData
        let accountName: String
        let rows: [RowData]
    }

    struct RowData: Identifiable {
        let id: String
        let tokenIconInfo: TokenIconInfo
        let name: String
        let network: String
        let fiat: String
        let crypto: String
        let onTap: () -> Void
    }

    typealias Holding = EarnAddFundsHoldingsAggregator.Holding
}

// MARK: - Private

private extension ForYouAddFundsTokenSelectorViewModel {
    func bind() {
        holdings
            .map(\.balanceChangesPublisher)
            .combineLatest()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, _ in viewModel.makeSections() }
            .assign(to: &$sections)
    }

    func select(_ holding: Holding) {
        selectionAction(holding.walletModel, holding.userWalletModel)
    }

    func makeSections() -> [Section] {
        SectionsFactory.make(holdings: holdings) { [weak self] in self?.select($0) }
    }
}

// MARK: - Balance changes

private extension EarnAddFundsHoldingsAggregator.Holding {
    /// Emits whenever the holding's fiat or crypto balance changes.
    var balanceChangesPublisher: AnyPublisher<Void, Never> {
        Publishers.CombineLatest(
            walletModel.fiatTotalTokenBalanceProvider.formattedBalanceTypePublisher,
            walletModel.totalTokenBalanceProvider.formattedBalanceTypePublisher
        )
        .mapToVoid()
        .eraseToAnyPublisher()
    }
}

// MARK: - FloatingSheetContentViewModel

extension ForYouAddFundsTokenSelectorViewModel: FloatingSheetContentViewModel {}
