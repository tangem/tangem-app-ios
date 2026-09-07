//
//  FeedDestination.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedDestination {
    case token(MarketsTokenDetailsCoordinator)
    case portfolioToken(TokenDetailsCoordinator)
}

extension FeedDestination: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.token(let lhs), .token(let rhs)): lhs === rhs
        case (.portfolioToken(let lhs), .portfolioToken(let rhs)): lhs === rhs
        default: false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .token(let coordinator): hasher.combine(ObjectIdentifier(coordinator))
        case .portfolioToken(let coordinator): hasher.combine(ObjectIdentifier(coordinator))
        }
    }
}
