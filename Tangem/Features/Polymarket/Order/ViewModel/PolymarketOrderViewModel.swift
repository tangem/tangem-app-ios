//
//  PolymarketOrderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

final class PolymarketOrderViewModel: ObservableObject {
    @Published private(set) var slippagePercent: Decimal = PolymarketSlippage.defaultPercent

    let marketRow: PolymarketOrderMarketRow.Model
    let payment: PolymarketOrderPaymentRow.Model
    let fieldViewModel = DecimalNumberTextFieldViewModel(maximumFractionDigits: PolymarketCollateral.decimalCount)

    var slippageText: String {
        PolymarketSlippageFormatter.rowText(slippagePercent)
    }

    private weak var coordinator: PolymarketOrderRoutable?

    init(market: PolymarketMarket, outcome: PolymarketOutcome, coordinator: PolymarketOrderRoutable?) {
        marketRow = .make(market: market, outcome: outcome)
        payment = .makeCollateral(balanceText: BalanceFormatter.defaultEmptyBalanceString)
        self.coordinator = coordinator
    }

    // MARK: - Actions

    func dismiss() {
        coordinator?.closeOrder()
    }

    func openSlippageSelector() {
        coordinator?.openSlippageSelector(percent: slippagePercent) { [weak self] percent in
            self?.slippagePercent = percent
        }
    }

    func proceed() {}
}
