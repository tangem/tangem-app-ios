//
//  LendingDepositResultViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class LendingDepositResultViewModel {
    typealias StateModel = LendingDepositResultContentView.StateModel
    typealias Action = LendingDepositResultContentView.Action

    let state: StateModel

    private weak var router: LendingDepositResultRoutable?

    init(sourceToken: SendSourceToken, amount: Decimal, currentApy: String, router: LendingDepositResultRoutable?) {
        let tokenItem = sourceToken.tokenItem
        let formatter = SendCryptoValueFormatter(decimals: tokenItem.decimalCount, currencySymbol: tokenItem.currencySymbol, trimFractions: true)

        state = StateModel(
            tokenIconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: sourceToken.isCustom),
            amount: formatter.string(from: amount),
            currencySymbol: tokenItem.currencySymbol,
            sourceName: Self.sourceName(sourceToken.header),
            currentApy: currentApy
        )
        self.router = router
    }

    func handle(_ action: Action) {
        switch action {
        case .toToken:
            router?.openToken()
        case .toYield:
            router?.openYield()
        }
    }
}

// MARK: - Private

private extension LendingDepositResultViewModel {
    static func sourceName(_ header: TokenHeader) -> String {
        switch header {
        case .account(let name, _), .wallet(let name, _): name
        }
    }
}
