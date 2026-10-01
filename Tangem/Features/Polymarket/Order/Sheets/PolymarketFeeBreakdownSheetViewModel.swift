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
import TangemLocalization
import TangemPolymarket

@MainActor
final class PolymarketFeeBreakdownSheetViewModel: ObservableObject, Identifiable {
    // MARK: - View state

    @Published private(set) var orderTitle: String
    @Published private(set) var orderCaption: String
    @Published private(set) var orderValue: String
    @Published private(set) var polymarketFee: String
    @Published private(set) var tangemBuilderFee: String
    @Published private(set) var total: String
    @Published private(set) var isRefreshing = false

    let currencyCode = PolymarketUtilities.collateralTokenItem.currencySymbol

    // MARK: - Dependencies

    private let model: PolymarketOrderModel

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(model: PolymarketOrderModel) {
        self.model = model

        let content = Content(state: model.state, intent: model.intent) ?? .placeholder(intent: model.intent)

        orderTitle = content.orderTitle
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

    func update(with state: PolymarketOrderModel.State) {
        guard let content = Content(state: state, intent: model.intent) else {
            isRefreshing = state.quote.isAwaitingQuote

            if !isRefreshing {
                apply(.placeholder(intent: model.intent))
            }

            return
        }

        apply(content)
        isRefreshing = false
    }

    func apply(_ content: Content) {
        orderTitle = content.orderTitle
        orderCaption = content.orderCaption
        orderValue = content.orderValue
        polymarketFee = content.polymarketFee
        tangemBuilderFee = content.tangemBuilderFee
        total = content.total
    }
}

// MARK: - Content

private extension PolymarketFeeBreakdownSheetViewModel {
    struct Content {
        let orderTitle: String
        let orderCaption: String
        let orderValue: String
        let polymarketFee: String
        let tangemBuilderFee: String
        let total: String

        init?(state: PolymarketOrderModel.State, intent: PolymarketOrderIntent) {
            guard let quote = state.quote.quote else { return nil }

            let shares = PolymarketOrderFormatter.shares(Self.captionShares(for: intent, quote: quote))
            let price = PolymarketPriceFormatter.cents(quote.averagePrice)
            let slippage = PolymarketSlippageFormatter.percentText(state.slippagePercent)
            let currency = PolymarketUtilities.collateralTokenItem.currencySymbol

            orderTitle = Self.title(for: intent)
            orderCaption = Self.caption(for: intent, shares: shares, price: price, currency: currency, slippage: slippage)
            orderValue = PolymarketOrderFormatter.money(Self.orderValue(for: intent, quote: quote))
            polymarketFee = PolymarketOrderFormatter.money(quote.fees.market)
            tangemBuilderFee = PolymarketOrderFormatter.money(quote.fees.builder)
            total = PolymarketOrderFormatter.money(quote.total)
        }

        static func orderValue(for intent: PolymarketOrderIntent, quote: PolymarketOrderQuote) -> Decimal {
            switch intent {
            case .buy: quote.notional
            case .sell: quote.expectedExecutionAmount
            }
        }

        static func captionShares(for intent: PolymarketOrderIntent, quote: PolymarketOrderQuote) -> Decimal {
            switch intent {
            case .buy: quote.expectedExecutionAmount
            case .sell: quote.shares
            }
        }

        static func title(for intent: PolymarketOrderIntent) -> String {
            switch intent {
            case .buy: Localization.predictionFeeSheetOrder
            case .sell: Localization.predictionCloseTitle
            }
        }

        static func caption(
            for intent: PolymarketOrderIntent,
            shares: String,
            price: String,
            currency: String,
            slippage: String
        ) -> String {
            switch intent {
            case .buy: Localization.predictionFeeSheetBuyDescription(shares, price, currency, slippage)
            case .sell: Localization.predictionFeeSheetSellDescription(shares, price, currency, slippage)
            }
        }

        private init(
            orderTitle: String,
            orderCaption: String,
            orderValue: String,
            polymarketFee: String,
            tangemBuilderFee: String,
            total: String
        ) {
            self.orderTitle = orderTitle
            self.orderCaption = orderCaption
            self.orderValue = orderValue
            self.polymarketFee = polymarketFee
            self.tangemBuilderFee = tangemBuilderFee
            self.total = total
        }

        static func placeholder(intent: PolymarketOrderIntent) -> Content {
            Content(
                orderTitle: title(for: intent),
                orderCaption: "",
                orderValue: BalanceFormatter.defaultEmptyBalanceString,
                polymarketFee: BalanceFormatter.defaultEmptyBalanceString,
                tangemBuilderFee: BalanceFormatter.defaultEmptyBalanceString,
                total: BalanceFormatter.defaultEmptyBalanceString
            )
        }
    }
}
