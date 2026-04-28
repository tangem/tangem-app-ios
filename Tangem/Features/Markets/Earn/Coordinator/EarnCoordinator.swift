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

    var isRedesignEnabled: Bool { FeatureProvider.isAvailable(.redesign) }

    // MARK: - Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Data

    private let earnDataProvider: EarnDataProvider = CommonEarnDataService()

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
            rootViewModel = EarnDetailViewModel(
                dataProvider: earnDataProvider,
                filterProvider: filterProvider,
                coordinator: self,
                analyticsProvider: analyticsProvider,
                presentSource: options.presentSource
            )

            if let mostlyUsedTokens = options.mostlyUsedTokens {
                earnDataProvider.applyMostlyUsedTokens(mostlyUsedTokens)
            } else {
                earnDataProvider.refreshMostlyUsedTokens()
            }

            analyticsProvider.logPageOpened()

            if let deeplinkFilter = options.deeplinkFilter {
                filterProvider.apply(deeplinkFilter: deeplinkFilter)
            }
        }
    }
}

// MARK: - Options

extension EarnCoordinator {
    struct Options {
        let mostlyUsedTokens: [EarnTokenModel]?
        let deeplinkFilter: EarnDataFilter?
        let presentSource: MarketsNavigationBackButton.PresentSource

        init(
            mostlyUsedTokens: [EarnTokenModel]?,
            deeplinkFilter: EarnDataFilter? = nil,
            presentSource: MarketsNavigationBackButton.PresentSource = .navigation
        ) {
            self.mostlyUsedTokens = mostlyUsedTokens
            self.deeplinkFilter = deeplinkFilter
            self.presentSource = presentSource
        }
    }
}

// MARK: - EarnDetailRoutable

@MainActor
extension EarnCoordinator: EarnDetailRoutable {
    func dismiss() {
        dismissAction(())
    }

    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {
        routeOnEarnTokenResolvedAction(resolution, source)
    }

    func openNetworksFilter() {
        if isRedesignEnabled {
            let viewModel = EarnNetworkFilterBottomSheetViewModel(
                filterProvider: filterProvider,
                analyticsProvider: analyticsProvider,
                onDismiss: { [weak self] in
                    Task { @MainActor in
                        self?.floatingSheetPresenter.removeActiveSheet()
                    }
                }
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        } else {
            networkFilterBottomSheetViewModel = EarnNetworkFilterBottomSheetViewModel(
                filterProvider: filterProvider,
                analyticsProvider: analyticsProvider,
                onDismiss: { [weak self] in
                    self?.networkFilterBottomSheetViewModel = nil
                }
            )
        }
    }

    func openTypesFilter() {
        if isRedesignEnabled {
            let viewModel = EarnTypeFilterBottomSheetViewModel(
                filterProvider: filterProvider,
                analyticsProvider: analyticsProvider,
                onDismiss: { [weak self] in
                    Task { @MainActor in
                        self?.floatingSheetPresenter.removeActiveSheet()
                    }
                }
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        } else {
            typeFilterBottomSheetViewModel = EarnTypeFilterBottomSheetViewModel(
                filterProvider: filterProvider,
                analyticsProvider: analyticsProvider,
                onDismiss: { [weak self] in
                    self?.typeFilterBottomSheetViewModel = nil
                }
            )
        }
    }
}
