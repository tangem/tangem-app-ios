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

    @Injected(\.userWalletRepository) var userWalletRepository: UserWalletRepository
    @Injected(\.tangemStoriesPresenter) var tangemStoriesPresenter: any TangemStoriesPresenter
    @Injected(\.expressAvailabilityProvider) var expressAvailabilityProvider: ExpressAvailabilityProvider

    let floatingSheetPresenter: FloatingSheetPresenter
    let floatingSheetPresentingStateProvider: FloatingSheetPresentingStateProvider
    let selectedAccountsProvider = ForYouSelectedAccountsProvider()
    let analyticsLogger: ForYouAnalyticsLogger
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
    @Published var sendCoordinator: SendCoordinator?

    // MARK: - Child ViewModels

    @Published var tokenSummaryViewModel: TokenSummaryViewModel?
    @Published var swapTokenSelectorViewModel: ForYouSwapTokenSelectorViewModel?

    /// Deferred until the presenting sheet finishes dismissing, avoiding a sheet-over-sheet race.
    var pendingSwapAction: (@MainActor () -> Void)?

    // MARK: - Properties

    /// Held during yield handling.
    var yieldDeeplinkRouter: YieldDeeplinkRouter?

    /// Read in `openAccountSelector` to avoid presenting the account selector over an already-shown sheet.
    private(set) var isAnySheetPresented = false

    private var sheetStateSubscription: AnyCancellable?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>,
        routeOnTokenResolvedAction: @MainActor @escaping (EarnTokenResolution, EarnOpportunitySource) -> Void,
        floatingSheetPresenter: FloatingSheetPresenter = InjectedValues[\.floatingSheetPresenter],
        floatingSheetPresentingStateProvider: FloatingSheetPresentingStateProvider = InjectedValues[\.floatingSheetPresentingStateProvider],
        analyticsLogger: ForYouAnalyticsLogger = CommonForYouAnalyticsLogger()
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.routeOnTokenResolvedAction = routeOnTokenResolvedAction
        self.floatingSheetPresenter = floatingSheetPresenter
        self.floatingSheetPresentingStateProvider = floatingSheetPresentingStateProvider
        self.analyticsLogger = analyticsLogger

        bind()
    }

    // MARK: - Implementation

    func start(with options: Options) {
        analyticsLogger.logScreenOpened()
        rootViewModel = ForYouViewModel(
            coordinator: self,
            selectedAccountsProvider: selectedAccountsProvider,
            analyticsLogger: analyticsLogger
        )
    }
}

extension ForYouCoordinator {
    struct Options {}
}

// MARK: - Private

private extension ForYouCoordinator {
    func bind() {
        sheetStateSubscription = floatingSheetPresentingStateProvider
            .hasPresentedSheetPublisher
            .sink { [weak self] in self?.isAnySheetPresented = $0 }
    }
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
