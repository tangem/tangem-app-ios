//
//  ForYouCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemUI

final class ForYouCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    /// Delegated to the host coordinator.
    let routeOnTokenResolvedAction: @MainActor (EarnTokenResolution, EarnOpportunitySource) -> Void

    // MARK: - Root Published

    @Published private(set) var rootViewModel: ForYouViewModel?

    // MARK: - Coordinators

    @Published var stakingCoordinator: StakingDetailsCoordinator?
    @Published var yieldPromoCoordinator: YieldModulePromoCoordinator?
    @Published var yieldActiveCoordinator: YieldModuleActiveCoordinator?
    @Published var earnListCoordinator: EarnCoordinator?
    @Published var addFundsCoordinator: ActionButtonsBuyCoordinator?
    @Published var portfolioTokenDetailsCoordinator: TokenDetailsCoordinator?

    // MARK: - Child ViewModels

    @Published var tokenSummaryViewModel: TokenSummaryViewModel?
    @Published var swapTokenSelectorViewModel: ForYouSwapTokenSelectorViewModel?

    /// Guards the sheet-over-sheet swap race.
    var pendingSwap: (tokenItem: TokenItem, walletId: UserWalletId)?

    // MARK: - Properties

    /// Held during yield handling.
    var yieldDeeplinkRouter: YieldDeeplinkRouter?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>,
        routeOnTokenResolvedAction: @MainActor @escaping (EarnTokenResolution, EarnOpportunitySource) -> Void
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.routeOnTokenResolvedAction = routeOnTokenResolvedAction
    }

    // MARK: - Implementation

    func start(with options: Options) {
        rootViewModel = ForYouViewModel(coordinator: self)
    }
}

extension ForYouCoordinator {
    struct Options {}
}

// MARK: - ForYouRoutable

@MainActor
extension ForYouCoordinator: ForYouRoutable {
    func routeEarnSuggestion(_ resolution: EarnTokenResolution) {
        routeOnTokenResolvedAction(resolution, .forYou)
    }

    func openSeeAllEarn() {
        let coordinator = EarnCoordinator(
            dismissAction: { [weak self] in
                self?.earnListCoordinator = nil
            },
            routeOnEarnTokenResolvedAction: { [weak self] resolution, source in
                self?.routeOnTokenResolvedAction(resolution, source)
            }
        )

        // For You seeds no tokens yet → nil makes the earn list fetch its own suggestions
        coordinator.start(with: .init(mostlyUsedTokens: nil, presentSource: .navigation))
        earnListCoordinator = coordinator
    }
}
