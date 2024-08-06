//
//  TokenMarketsDetailsDateHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenMarketsDetailsDateHelper {
    private let initialDate: Date

    init(initialDate: Date) {
        self.initialDate = initialDate
    }

    func makeDate(
        selectedDate: Date?,
        selectedPriceChangeIntervalType: MarketsPriceIntervalType
    ) -> Date? {
        guard
            let selectedDate
        else {
            // Fallback to the date defined by the selected `MarketsPriceIntervalType`
            return makeDate(using: selectedPriceChangeIntervalType)
        }

        return selectedDate
    }

    private func makeDate(using selectedPriceChangeIntervalType: MarketsPriceIntervalType) -> Date? {
        switch selectedPriceChangeIntervalType {
        case .day:
            // Causes fallback to the `Localization.commonToday`
            return nil
        case .week:
            return initialDate.dateByAdding(-7, .day).date
        case .month:
            return initialDate.dateByAdding(-1, .month).date
        case .quarter:
            return initialDate.dateByAdding(-3, .month).date
        case .halfYear:
            return initialDate.dateByAdding(-6, .month).date
        case .year:
            return initialDate.dateByAdding(-1, .year).date
        case .all:
            // [REDACTED_TODO_COMMENT]
            return nil
        }
    }
}
