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

    func team(named text: String) -> PolymarketTeam? {
        let label = Self.normalized(text)

        guard !label.isEmpty else {
            return nil
        }

        return teams.first { team in
            [team.name, team.alias].compactMap { $0 }.contains { Self.normalized($0) == label }
        }
    }

    private func teamAbbreviation(for outcome: PolymarketOutcome) -> String? {
        team(named: outcome.title)?.abbreviation?.uppercased()
    }

    private static func normalized(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
