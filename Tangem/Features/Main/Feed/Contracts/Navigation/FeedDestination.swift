//
//  FeedDestination.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedDestination: Hashable, Identifiable {
    case token(MarketsTokenDetailsCoordinator)
    case portfolioToken(TokenDetailsCoordinator)
    case portfolioTokenList(MarketsPortfolioTokenListViewModel)

    var id: ObjectIdentifier {
        switch self {
        case .token(let coordinator): ObjectIdentifier(coordinator)
        case .portfolioToken(let coordinator): ObjectIdentifier(coordinator)
        case .portfolioTokenList(let viewModel): ObjectIdentifier(viewModel)
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
