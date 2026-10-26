//
//  PolymarketLiveGameCardPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

private struct PolymarketLiveGameCardShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.spacing) {
                PolymarketLiveGameCard(model: .esportsLiveStub)
                PolymarketLiveGameCard(model: .soccerLiveStub)
                PolymarketLiveGameCard(model: .soccerEndedStub)
                PolymarketLiveGameCard(model: .unparsedScoreStub)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.spacing)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - Constants

private extension PolymarketLiveGameCardShowcase {
    enum Constants {
        static let spacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Stubs

private extension PolymarketEventCard.Outcome {
    static func stub(_ title: String, _ priceText: String, _ style: PolymarketOutcomeStyle) -> Self {
        Self(id: title, title: title, priceText: priceText, style: style, onSelect: {})
    }
}

private extension PolymarketLiveGameCard.Model {
    static func stub(
        title: String,
        category: String,
        home: String,
        away: String,
        score: PolymarketLiveGameCard.Score?,
        showsLiveBadge: Bool,
        period: String?,
        outcomes: [PolymarketEventCard.Outcome]
    ) -> Self {
        Self(
            id: title,
            title: title,
            category: PolymarketEventCard.Category(name: category, icon: nil),
            volumeText: "$6.3M",
            home: PolymarketLiveGameCard.Team(name: home, logoURL: nil),
            away: PolymarketLiveGameCard.Team(name: away, logoURL: nil),
            score: score,
            showsLiveBadge: showsLiveBadge,
            period: period,
            outcomes: outcomes
        )
    }

    static let esportsLiveStub = stub(
        title: "Dota 2: Conventus Stellarum vs 1win",
        category: "Dota 2",
        home: "Conventus Stellarum",
        away: "1win",
        score: PolymarketLiveGameCard.Score(home: "2", away: "1"),
        showsLiveBadge: true,
        period: "3/4",
        outcomes: [.stub("CS", "55¢", .affirmative), .stub("1WIN", "45¢", .negative)]
    )

    static let soccerLiveStub = stub(
        title: "ASC Oțelul Galați – FC Corvinul 1921 Hunedoara",
        category: "Football",
        home: "Otelul Galati",
        away: "FC Corvinul 1921 Hunedoara",
        score: PolymarketLiveGameCard.Score(home: "1", away: "0"),
        showsLiveBadge: true,
        period: "1H",
        outcomes: [.stub("AOG", "36¢", .affirmative), .stub("Draw", "32¢", .neutral), .stub("COR", "34¢", .negative)]
    )

    static let soccerEndedStub = stub(
        title: "Lithuania vs. Andorra",
        category: "Football",
        home: "Lithuania",
        away: "Andorra",
        score: PolymarketLiveGameCard.Score(home: "2", away: "2"),
        showsLiveBadge: false,
        period: "FT",
        outcomes: [.stub("LIT", "1¢", .affirmative), .stub("Draw", "99¢", .neutral), .stub("AND", "1¢", .negative)]
    )

    static let unparsedScoreStub = stub(
        title: "Anna Bondar vs. Renata Zarazua",
        category: "Tennis",
        home: "Anna Bondar",
        away: "Renata Zarazua",
        score: nil,
        showsLiveBadge: true,
        period: nil,
        outcomes: [.stub("WKENT", "36¢", .affirmative), .stub("NMXST", "34¢", .negative)]
    )
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketLiveGameCardShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketLiveGameCardShowcase()
        .preferredColorScheme(.dark)
}
