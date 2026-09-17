//
//  FeedDestination.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedDestination: Hashable, Identifiable {
    case forYou(ForYouCoordinator)
    case accountForm(AccountFormViewModel)
    case jointAccount(JointAccountManagementCoordinator)
    case token(MarketsTokenDetailsCoordinator)
    case portfolioToken(TokenDetailsCoordinator)

    var id: ObjectIdentifier {
        switch self {
        case .forYou(let coordinator): ObjectIdentifier(coordinator)
        case .accountForm(let viewModel): ObjectIdentifier(viewModel)
        case .jointAccount(let coordinator): ObjectIdentifier(coordinator)
        case .token(let coordinator): ObjectIdentifier(coordinator)
        case .portfolioToken(let coordinator): ObjectIdentifier(coordinator)
        }
    }

    var isFullScreenPresentation: Bool {
        switch self {
        case .jointAccount:
            return true
        default:
            return false
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
