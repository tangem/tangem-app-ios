//
//  PolymarketFeeBreakdownSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPolymarket

@MainActor
final class PolymarketFeeBreakdownSheetViewModel: ObservableObject, Identifiable {
    // MARK: - View state

    @Published private(set) var orderCaption: String
    @Published private(set) var orderValue: String
    @Published private(set) var polymarketFee: String
    @Published private(set) var tangemBuilderFee: String
    @Published private(set) var total: String
    @Published private(set) var isRefreshing = false

    // MARK: - Dependencies

    private let model: PolymarketOrderModel

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(model: PolymarketOrderModel) {
        self.model = model

        let content = Content(state: model.state) ?? .placeholder

        orderCaption = content.orderCaption
        orderValue = content.orderValue
        polymarketFee = content.polymarketFee
        tangemBuilderFee = content.tangemBuilderFee
        total = content.total

        bind()
    }
}

// MARK: - Binding

private extension PolymarketFeeBreakdownSheetViewModel {
    func bind() {
        model
            .$state
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.update(with: state)
            }
            .store(in: &bag)
    }

    /// The last figures survive a quote that is merely in flight; one that will never arrive clears
    /// them, so the sheet cannot state a total the row behind it already shows as a dash.
    func update(with state: PolymarketOrderModel.State) {
        guard let content = Content(state: state) else {
            isRefreshing = state.quote.isAwaited

            if !isRefreshing {
                apply(.placeholder)
            }

            return
        }

        apply(content)
        isRefreshing = false
    }

    func apply(_ content: Content) {
        orderCaption = content.orderCaption
        orderValue = content.orderValue
        polymarketFee = content.polymarketFee
        tangemBuilderFee = content.tangemBuilderFee
        total = content.total
    }
}

// MARK: - Quote state

/// A quote still on its way is worth shimmering for; a market that stopped answering will never send one.
private extension PolymarketOrderQuoteState {
    var isAwaited: Bool {
        switch self {
        case .empty, .loading: true
        case .content, .unavailable, .failed: false
        }
    }
}

// MARK: - Content

private extension PolymarketFeeBreakdownSheetViewModel {
    struct Content {
        let orderCaption: String
        let orderValue: String
        let polymarketFee: String
        let tangemBuilderFee: String
        let total: String

        init?(state: PolymarketOrderModel.State) {
            guard let quote = state.quote.quote else { return nil }

            let shares = PolymarketOrderFormatter.shares(quote.shares)
            let price = PolymarketPriceFormatter.centsText(quote.averagePrice)
            let slippage = PolymarketSlippageFormatter.percentText(state.slippagePercent)

            // [REDACTED_TODO_COMMENT]
            orderCaption = "Buying \(shares) shares at \(price) each. Final shares count (and corresponding pUSD amount executed) may vary within your \(slippage) slippage limit, depending on what this market can match."
            orderValue = PolymarketOrderFormatter.money(quote.notional)
            polymarketFee = PolymarketOrderFormatter.money(quote.fees.market)
            tangemBuilderFee = PolymarketOrderFormatter.money(quote.fees.builder)
            total = PolymarketOrderFormatter.money(quote.total)
        }

        private init(
            orderCaption: String,
            orderValue: String,
            polymarketFee: String,
            tangemBuilderFee: String,
            total: String
        ) {
            self.orderCaption = orderCaption
            self.orderValue = orderValue
            self.polymarketFee = polymarketFee
            self.tangemBuilderFee = tangemBuilderFee
            self.total = total
        }

        static let placeholder = Content(
            orderCaption: "",
            orderValue: BalanceFormatter.defaultEmptyBalanceString,
            polymarketFee: BalanceFormatter.defaultEmptyBalanceString,
            tangemBuilderFee: BalanceFormatter.defaultEmptyBalanceString,
            total: BalanceFormatter.defaultEmptyBalanceString
        )
    }
}
