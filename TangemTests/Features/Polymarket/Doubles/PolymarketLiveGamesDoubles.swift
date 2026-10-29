//
//  PolymarketLiveGamesDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import TangemPolymarket
@testable import Tangem

final class PolymarketLiveGamesSourceSpy: Sendable {
    let statuses = PolymarketLiveStreamSpy<PolymarketWebSocketConnectionStatus>()
    let requests = PolymarketTestSignal<PolymarketLiveStreamSpy<PolymarketLiveGame>>()

    private let state = OSAllocatedUnfairLock(initialState: [PolymarketLiveStreamSpy<PolymarketLiveGame>]())

    var streams: [PolymarketLiveStreamSpy<PolymarketLiveGame>] {
        state.withLock { $0 }
    }

    @MainActor
    func makeTracker(delayProvider: any PollDelayProvider = HoldingDelayProviderSpy(holdThreshold: 0)) -> PolymarketFeedLiveGamesTracker {
        PolymarketFeedLiveGamesTracker(
            games: { @MainActor [self] gameIds in games(for: gameIds) },
            statusChanges: { [statuses] in statuses.makeStream() },
            delayProvider: delayProvider
        )
    }

    private func games(for gameIds: Set<String>) -> AsyncStream<PolymarketLiveGame> {
        let stream = PolymarketLiveStreamSpy<PolymarketLiveGame>(assetIds: gameIds)
        state.withLock { $0.append(stream) }
        requests.send(stream)
        return stream.makeStream()
    }
}

// MARK: - Fixtures

enum PolymarketLiveGamesFixtures {
    static let basketballGameId = "20023885"

    static func basketball(
        id: String = "1197295",
        gameId: String = basketballGameId,
        isLive: Bool = true,
        score: String? = "98-101",
        period: String? = "Q4",
        hasEnded: Bool = false
    ) -> PolymarketEvent {
        let market = market(
            id: "\(id)-moneyline",
            groupItemTitle: nil,
            outcomes: [
                PolymarketOutcome(assetId: "\(id)-cle", title: "Cavaliers", probability: Decimal(string: "0.415")),
                PolymarketOutcome(assetId: "\(id)-phi", title: "76ers", probability: Decimal(string: "0.585")),
            ]
        )

        return event(
            id: id,
            title: "Cavaliers vs. 76ers",
            isLive: isLive,
            markets: [market],
            teams: [
                team("Cavaliers", abbreviation: "cle", side: .away),
                team("76ers", abbreviation: "phi", side: .home),
            ],
            game: game(gameId, score: score, period: period, hasEnded: hasEnded)
        )
    }

    static func soccer(
        id: String = "1201001",
        gameId: String = "90114139",
        isLive: Bool = true,
        score: String? = "1-1",
        drawTitle: String = "Draw (Arsenal FC vs. Chelsea FC)",
        drawFirst: Bool = false,
        totalMarketsCount: Int? = nil
    ) -> PolymarketEvent {
        let home = yesNoMarket(id: "\(id)-ars", groupItemTitle: "Arsenal FC")
        let draw = yesNoMarket(id: "\(id)-draw", groupItemTitle: drawTitle)
        let away = yesNoMarket(id: "\(id)-che", groupItemTitle: "Chelsea FC")

        return event(
            id: id,
            title: "Arsenal FC vs. Chelsea FC",
            isLive: isLive,
            markets: drawFirst ? [draw, home, away] : [home, away, draw],
            totalMarketsCount: totalMarketsCount,
            teams: [
                team("Arsenal FC", abbreviation: "ars", side: .home),
                team("Chelsea FC", abbreviation: "che", side: .away),
            ],
            game: game(gameId, score: score, period: "2H", hasEnded: false)
        )
    }

    static func tennis(score: String, period: String? = "S3") -> PolymarketEvent {
        let market = market(
            id: "1223267-moneyline",
            groupItemTitle: nil,
            outcomes: [
                PolymarketOutcome(assetId: "medvedev", title: "Daniil Medvedev", probability: Decimal(string: "0.95")),
                PolymarketOutcome(assetId: "shimabukuro", title: "Sho Shimabukuro", probability: Decimal(string: "0.05")),
            ]
        )

        return event(
            id: "1223267",
            title: "Almaty Open: Daniil Medvedev vs Sho Shimabukuro",
            isLive: true,
            markets: [market],
            teams: [
                team("Daniil Medvedev", abbreviation: nil, side: .home),
                team("Sho Shimabukuro", abbreviation: nil, side: .away),
            ],
            game: game("6471848", score: score, period: period, hasEnded: false)
        )
    }

    static func liveGame(
        _ gameId: String,
        score: String?,
        period: String? = "Q4",
        isLive: Bool = true,
        hasEnded: Bool = false
    ) -> PolymarketLiveGame {
        PolymarketLiveGame(
            gameId: gameId,
            score: PolymarketGameScore(parsing: score, period: period),
            period: period,
            isLive: isLive,
            hasEnded: hasEnded
        )
    }

    static func game(_ gameId: String, score: String?, period: String?, hasEnded: Bool) -> PolymarketEventGame {
        PolymarketEventGame(
            gameId: gameId,
            score: PolymarketGameScore(parsing: score, period: period),
            period: period,
            hasEnded: hasEnded
        )
    }

    static func team(_ name: String, abbreviation: String?, side: PolymarketTeam.Side) -> PolymarketTeam {
        PolymarketTeam(name: name, abbreviation: abbreviation, alias: nil, logoURL: nil, side: side)
    }

    static func yesNoMarket(id: String, groupItemTitle: String, yesFirst: Bool = true) -> PolymarketMarket {
        let yes = PolymarketOutcome(assetId: "\(id)-yes", title: "Yes", probability: Decimal(string: "0.4"))
        let no = PolymarketOutcome(assetId: "\(id)-no", title: "No", probability: Decimal(string: "0.6"))

        return market(id: id, groupItemTitle: groupItemTitle, outcomes: yesFirst ? [yes, no] : [no, yes])
    }

    static func market(id: String, groupItemTitle: String?, outcomes: [PolymarketOutcome]) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
            title: id,
            groupItemTitle: groupItemTitle,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            isAcceptingOrders: true,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: 0,
            outcomes: outcomes
        )
    }

    static func event(
        id: String,
        title: String,
        isLive: Bool,
        markets: [PolymarketMarket],
        totalMarketsCount: Int? = nil,
        teams: [PolymarketTeam],
        game: PolymarketEventGame?
    ) -> PolymarketEvent {
        PolymarketEvent(
            id: id,
            slug: id,
            title: title,
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isLive: isLive,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: totalMarketsCount ?? markets.count,
            isNegRisk: false,
            displayMode: .plainMarkets,
            markets: markets,
            teams: teams,
            game: game
        )
    }
}
