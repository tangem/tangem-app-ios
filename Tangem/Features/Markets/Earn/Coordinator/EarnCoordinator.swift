//
//  EarnCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder
import TangemFoundation

final class EarnCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>
    let routeOnEarnTokenResolvedAction: (EarnTokenResolution, EarnOpportunitySource) -> Void

    // MARK: - Root ViewModels

    @Published var rootViewModel: EarnDetailViewModel?
    @Published var error: AlertBinder?

    // MARK: - Child ViewModels

    @Published var networkFilterBottomSheetViewModel: EarnNetworkFilterBottomSheetViewModel?
    @Published var typeFilterBottomSheetViewModel: EarnTypeFilterBottomSheetViewModel?

    // MARK: - Injected

    @Injected(\.earnDataFilterProvider) private var filterProvider: EarnDataFilterProvider
    @Injected(\.earnAnalyticsProvider) private var analyticsProvider: EarnAnalyticsProvider

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in },
        routeOnEarnTokenResolvedAction: @escaping (EarnTokenResolution, EarnOpportunitySource) -> Void
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.routeOnEarnTokenResolvedAction = routeOnEarnTokenResolvedAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            let earnDataProvider = EarnDataProvider()

            rootViewModel = EarnDetailViewModel(
                dataProvider: earnDataProvider,
                filterProvider: filterProvider,
                mostlyUsedTokens: options.mostlyUsedTokens,
                coordinator: self,
                analyticsProvider: analyticsProvider
            )
            analyticsProvider.logPageOpened()
        }
    }
}

// MARK: - Options

extension EarnCoordinator {
    struct Options {
        let mostlyUsedTokens: [EarnTokenModel]
    }
}

// MARK: - EarnDetailRoutable

extension EarnCoordinator: EarnDetailRoutable {
    func dismiss() {
        dismissAction(())
    }

    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {
        routeOnEarnTokenResolvedAction(resolution, source)
    }

    func openNetworksFilter() {
        networkFilterBottomSheetViewModel = EarnNetworkFilterBottomSheetViewModel(
            filterProvider: filterProvider,
            analyticsProvider: analyticsProvider,
            onDismiss: { [weak self] in
                self?.networkFilterBottomSheetViewModel = nil
            }
        )
    }

    func openTypesFilter() {
        typeFilterBottomSheetViewModel = EarnTypeFilterBottomSheetViewModel(
            filterProvider: filterProvider,
            analyticsProvider: analyticsProvider,
            onDismiss: { [weak self] in
                self?.typeFilterBottomSheetViewModel = nil
            }
        )
    }
}
