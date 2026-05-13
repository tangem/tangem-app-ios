//
//  MarketsSearchCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemStaking
import struct TangemUIUtils.AlertBinder

final class MarketsSearchCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published var rootViewModel: MarketsSearchViewModel? = nil
    @Published var error: AlertBinder? = nil

    // MARK: - Coordinators

    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var marketsSearchCoordinator: MarketsSearchCoordinator?

    // MARK: - Child ViewModels

    @Published var marketsListOrderBottomSheetViewModel: MarketsListOrderBottomSheetViewModel?

    // MARK: - Private

    private(set) var leadingButton: MarketsSearchNavigationBar<DefaultNavigationBarTitle>.LeadingButton = .back

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        leadingButton = options.leadingButton

        let marketsViewModel = MarketsSearchViewModel(
            initialOrderType: options.initialOrderType,
            initialIntervalType: options.initialIntervalType,
            quotesRepositoryUpdateHelper: options.quotesRepositoryUpdateHelper,
            coordinator: self
        )

        rootViewModel = marketsViewModel
    }
}

extension MarketsSearchCoordinator {
    struct Options {
        let initialOrderType: MarketsListOrderType?
        let initialIntervalType: MarketsPriceIntervalType?
        let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
        /// Style of the leading button in the navigation bar: `.back` for in-app navigation
        /// (e.g. "See All" from the Markets bottom sheet), `.close` for modal deeplink entry.
        let leadingButton: MarketsSearchNavigationBar<DefaultNavigationBarTitle>.LeadingButton
    }
}

// MARK: - MarketsRoutable

extension MarketsSearchCoordinator: MarketsRoutable {
    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider) {
        marketsListOrderBottomSheetViewModel = .init(from: provider, onDismiss: { [weak self] in
            self?.marketsListOrderBottomSheetViewModel = nil
        })
    }

    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel) {
        let tokenDetailsCoordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.tokenDetailsCoordinator = nil
            }
        )
        tokenDetailsCoordinator.start(with: .init(info: tokenInfo, style: .marketsSheet))

        self.tokenDetailsCoordinator = tokenDetailsCoordinator
    }
}
