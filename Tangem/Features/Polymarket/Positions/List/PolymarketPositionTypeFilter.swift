//
//  PolymarketPositionTypeFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket

enum PolymarketPositionTypeFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case won
    case lost
    case disputed
    case pending
    case split
    case closed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: Localization.commonAll
        case .active: Localization.predictionPositionsActive
        case .won: Localization.predictionPositionsWon
        case .lost: Localization.predictionPositionsLost
        case .disputed: Localization.predictionPositionsDisputed
        case .pending: Localization.predictionPositionsPending
        case .split: Localization.predictionPositionsSplit
        case .closed: Localization.predictionPositionsClosed
        }
    }

    static func cases(for tab: PolymarketPositionsTab) -> [Self] {
        switch tab {
        case .active: [.all, .active, .won, .lost, .disputed, .pending, .split]
        case .finished: [.all, .won, .lost, .split, .closed]
        }
    }

    func accepts(_ position: PolymarketPosition) -> Bool {
        switch self {
        case .all: true
        case .active: position.resolutionStatus == .open
        case .disputed: position.resolutionStatus == .disputed
        case .pending: position.resolutionStatus == .pendingResolution || position.resolutionStatus == .proposed
        case .won: position.settlement == .won
        case .lost: position.settlement == .lost
        case .split: position.settlement == .split
        case .closed: false
        }
    }

    func accepts(_ position: PolymarketClosedPosition) -> Bool {
        switch self {
        case .all: true
        case .active, .disputed, .pending: false
        case .won: position.status == .won
        case .lost: position.status == .lost
        case .split: position.status == .split
        case .closed: position.status == .closed
        }
    }
}
