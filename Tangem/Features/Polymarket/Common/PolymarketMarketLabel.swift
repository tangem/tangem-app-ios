//
//  PolymarketMarketLabel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

extension PolymarketEvent {
    func listLabel(for market: PolymarketMarket) -> String? {
        guard totalMarketsCount > 1 else {
            return market.groupLabel
        }

        let groupTitle = market.groupLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let question = market.title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let label: String? = switch displayMode {
        case .groupedOutcomes: groupTitle ?? question
        case .plainMarkets: question ?? groupTitle
        }

        return label.flatMap(distinctFromTitle)
    }

    private func distinctFromTitle(_ label: String) -> String? {
        let eventTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard label.compare(eventTitle, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame else {
            return nil
        }

        return label
    }
}

private extension PolymarketMarket {
    var groupLabel: String? {
        guard let label = groupItemTitle?.nilIfEmpty else { return nil }

        guard label.range(of: Constants.matchWinner, options: .caseInsensitive) == nil else { return nil }

        return label
    }
}

// MARK: - Constants

private extension PolymarketMarket {
    enum Constants {
        static let matchWinner = "match winner"
    }
}
