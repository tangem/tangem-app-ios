//
//  PolymarketMapper+PriceHistory.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketMapper {
    func mapPriceHistory(_ response: PolymarketDTO.PriceHistoryResponse) -> [PolymarketPricePoint] {
        var probabilities: [TimeInterval: Decimal] = [:]

        for point in response.history where PriceHistoryConstants.probabilityRange.contains(point.price) {
            probabilities[point.timestamp] = point.price
        }

        return probabilities
            .map { PolymarketPricePoint(date: Date(timeIntervalSince1970: $0.key), probability: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Constants

private enum PriceHistoryConstants {
    static let probabilityRange: ClosedRange<Decimal> = 0 ... 1
}
