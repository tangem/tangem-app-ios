//
//  TokenMarketsDetailsPriceInfoHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenMarketsDetailsPriceInfoHelper {
    typealias PriceInfo = (price: String, priceChangeState: TokenPriceChangeView.State)

    private let tokenInfo: MarketsTokenModel
    private let priceChangeInfo: [String: Decimal]
    private let fiatBalanceFormattingOptions: BalanceFormattingOptions

    private let priceChangeUtility = PriceChangeUtility()
    private let balanceFormatter = BalanceFormatter()

    init(
        tokenInfo: MarketsTokenModel,
        priceChangeInfo: [String: Decimal],
        fiatBalanceFormattingOptions: BalanceFormattingOptions
    ) {
        self.tokenInfo = tokenInfo
        self.priceChangeInfo = priceChangeInfo
        self.fiatBalanceFormattingOptions = fiatBalanceFormattingOptions
    }

    func makePriceInfo(
        selectedPrice: Decimal?,
        selectedPriceChangeIntervalType: MarketsPriceIntervalType
    ) -> PriceInfo {
        guard
            let selectedPrice,
            let currentPrice = tokenInfo.currentPrice
        else {
            // Fallback to the price info defined by the selected `MarketsPriceIntervalType`
            return makePriceInfo(using: selectedPriceChangeIntervalType)
        }

        let priceChangeState = priceChangeUtility.calculatePriceChangeStateBetween(
            currentPrice: currentPrice,
            previousPrice: selectedPrice
        )

        let price = balanceFormatter.formatFiatBalance(
            selectedPrice,
            formattingOptions: fiatBalanceFormattingOptions
        )

        return (price, priceChangeState)
    }

    private func makePriceInfo(using selectedPriceChangeIntervalType: MarketsPriceIntervalType) -> PriceInfo {
        let changePercent = priceChangeInfo[selectedPriceChangeIntervalType.rawValue]
        let priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: changePercent)

        let price = balanceFormatter.formatFiatBalance(
            tokenInfo.currentPrice,
            formattingOptions: fiatBalanceFormattingOptions
        )

        return (price, priceChangeState)
    }
}
