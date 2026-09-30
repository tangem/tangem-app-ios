//
//  PriceChangeUtility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct PriceChangeUtility {
    private let priceChangeFormatter = PriceChangeFormatter()

    func convertToPriceChangeState(changeFractional: Decimal?) -> PriceChangeView.State {
        guard let changeFractional else {
            return .noData
        }

        let result = priceChangeFormatter.formatFractionalValue(changeFractional, option: .priceChange)
        return .loaded(changeType: result.signType.priceChangeViewChangeType, text: result.formattedText)
    }

    func convertToPriceChangeState(
        changePercent: Decimal?,
        changeValue: Decimal? = nil,
        loading: Bool = false
    ) -> PriceChangeView.State {
        guard let changePercent else {
            return .noData
        }

        let priceChangeResult = priceChangeFormatter.formatPercentValue(changePercent, option: .priceChange)

        let changeType = priceChangeResult.signType.priceChangeViewChangeType
        let text = priceChangeResult.formattedText

        return loading
            ? .loadingCached(changeType: changeType, text: text)
            : .loaded(changeType: changeType, text: text)
    }

    func calculatePriceChangeStateBetween(currentPrice: Decimal, previousPrice: Decimal) -> PriceChangeView.State {
        // A zero reference price (chart points for a token that had no market yet) has no meaningful percentage;
        // dividing by it produced `NaN`, which the formatter rendered literally as "NaN %".
        guard previousPrice != 0 else {
            return .noData
        }

        let priceChangePercentage = (currentPrice - previousPrice) / previousPrice * 100.0

        return convertToPriceChangeState(changePercent: priceChangePercentage)
    }
}

private extension PriceChangeUtility {
    enum Constants {
        static let percentDivider: Decimal = 0.01
    }
}
