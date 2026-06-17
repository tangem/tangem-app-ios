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

    func convertToPriceChangeState(changePercent: Decimal?, loading: Bool = false) -> PriceChangeView.State {
        guard let changePercent else {
            return .noData
        }

        let result = priceChangeFormatter.formatPercentValue(changePercent, option: .priceChange)
        let changeType = result.signType.priceChangeViewChangeType
        return loading
            ? .loadingCached(changeType: changeType, text: result.formattedText)
            : .loaded(changeType: changeType, text: result.formattedText)
    }

    func calculatePriceChangeStateBetween(currentPrice: Decimal, previousPrice: Decimal) -> PriceChangeView.State {
        let priceChangePercentage = (currentPrice - previousPrice) / previousPrice * 100.0

        return convertToPriceChangeState(changePercent: priceChangePercentage)
    }
}

private extension PriceChangeUtility {
    enum Constants {
        static let percentDivider: Decimal = 0.01
    }
}
