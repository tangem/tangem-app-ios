//
//  MarketsTokenDetailsDateHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemFoundation

struct MarketsTokenDetailsDateHelper {
    private let initialDate: Date

    private var calendar: Calendar { .autoupdatingCurrent }

    init(
        initialDate: Date
    ) {
        self.initialDate = initialDate
    }

    func makePriceDate(
        selectedDate: Date?,
        selectedPriceChangeIntervalType intervalType: MarketsPriceIntervalType
    ) -> String {
        switch (intervalType, selectedDate) {
        case (.day, .none):
            return Localization.commonToday
        case (.all, .none):
            return Localization.commonAll
        case (_, .none):
            let dateFormatter = MarketsTokenDetailsDateFormatterRepository.shared.priceDateFormatter(for: intervalType)
            let intervalBeginningDate = makeIntervalBeginningDate(using: intervalType)
            return makePriceDate(intervalBeginningDate: intervalBeginningDate, dateFormatter: dateFormatter)
        case (_, .some(let selectedDate)):
            let dateFormatter = MarketsTokenDetailsDateFormatterRepository.shared.priceDateFormatter(for: intervalType)
            return makePriceDate(intervalBeginningDate: selectedDate, dateFormatter: dateFormatter)
        }
    }

    private func makePriceDate(intervalBeginningDate: Date, dateFormatter: DateFormatter) -> String {
        return "\(dateFormatter.string(from: intervalBeginningDate)) \(AppConstants.enDashSign) \(Localization.commonNow)"
    }

    private func makeIntervalBeginningDate(using selectedPriceChangeIntervalType: MarketsPriceIntervalType) -> Date {
        switch selectedPriceChangeIntervalType {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: initialDate) ?? initialDate
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: initialDate) ?? initialDate
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: initialDate) ?? initialDate
        case .halfYear:
            return calendar.date(byAdding: .month, value: -6, to: initialDate) ?? initialDate
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: initialDate) ?? initialDate
        case .day,
             .all:
            assertionFailure("Unreachable")
            return Date()
        }
    }
}
