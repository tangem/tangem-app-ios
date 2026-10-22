//
//  PolymarketOutcomeButtonTitle.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

extension PolymarketEvent {
    func buttonTitles(for market: PolymarketMarket) -> [String] {
        let abbreviations = market.outcomes.compactMap(teamAbbreviation)

        guard !market.outcomes.isEmpty, abbreviations.count == market.outcomes.count else {
            return market.outcomes.map(\.title)
        }

        return abbreviations
    }

    private func teamAbbreviation(for outcome: PolymarketOutcome) -> String? {
        let label = Self.normalized(outcome.title)

        guard
            !label.isEmpty,
            let team = teams.first(where: { team in
                [team.name, team.alias].compactMap { $0 }.contains { Self.normalized($0) == label }
            })
        else {
            return nil
        }

        return team.abbreviation?.uppercased()
    }

    private static func normalized(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
