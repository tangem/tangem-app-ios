//
//  PolymarketGameState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketGameState {
    let score: PolymarketGameScore
    let period: String?
    let isLive: Bool
    let hasEnded: Bool

    init?(event: PolymarketEvent, liveGame: PolymarketLiveGame?) {
        guard let restGame = event.game else {
            return nil
        }

        let restStage = Stage(isLive: event.isLive, hasEnded: restGame.hasEnded)
        let liveStage = liveGame.map { Stage(isLive: $0.isLive, hasEnded: $0.hasEnded) }

        guard let liveGame, let liveStage, liveStage >= restStage else {
            score = restGame.score
            period = restGame.period
            isLive = restStage == .live
            hasEnded = restStage == .ended
            return
        }

        score = liveGame.score
        period = liveGame.period
        isLive = liveStage == .live
        hasEnded = liveStage == .ended
    }

    var showsLiveBadge: Bool {
        guard isLive, let period else {
            return isLive
        }

        return !Constants.stoppedPeriods.contains(period.uppercased())
    }
}

// MARK: - Stage

private extension PolymarketGameState {
    enum Stage: Comparable {
        case notStarted
        case live
        case ended

        init(isLive: Bool, hasEnded: Bool) {
            if hasEnded {
                self = .ended
            } else {
                self = isLive ? .live : .notStarted
            }
        }

        static func < (lhs: Stage, rhs: Stage) -> Bool {
            lhs.progress < rhs.progress
        }

        private var progress: Int {
            switch self {
            case .notStarted: 0
            case .live: 1
            case .ended: 2
            }
        }
    }
}

// MARK: - Constants

private extension PolymarketGameState {
    enum Constants {
        static let stoppedPeriods: Set<String> = ["CAN", "POST", "INT", "AB"]
    }
}
