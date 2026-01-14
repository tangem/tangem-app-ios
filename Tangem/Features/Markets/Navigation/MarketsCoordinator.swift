//
//  MarketsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class MarketsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root Published

    @Published private(set) var marketsViewModel: MarketsViewModel?
    @Published private(set) var marketsMainViewModel: MarketsMainViewModel?

    // MARK: - Coordinators

    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var marketsSearchCoordinator: MarketsSearchCoordinator?

    // MARK: - Child ViewModels

    @Published var marketsListOrderBottomSheetViewModel: MarketsListOrderBottomSheetViewModel?

    // MARK: - Private Properties

    private lazy var quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper = CommonMarketsQuotesUpdateHelper()

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLogger.debug("MarketsCoordinator deinit")
    }

    // MARK: - Implementation

    func start(with options: MarketsCoordinator.Options) {
        let quotesRepositoryUpdateHelper = CommonMarketsQuotesUpdateHelper()

        if FeatureProvider.isAvailable(.marketsAndNews) {
            let viewModel = MarketsMainViewModel(
                quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
                coordinator: self
            )

            marketsMainViewModel = viewModel
        } else {
            let viewModel = MarketsViewModel(
                quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
                coordinator: self
            )

            marketsViewModel = viewModel
        }
    }
}

extension MarketsCoordinator {
    struct Options {}
}

extension MarketsCoordinator: MarketsRoutable {
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
        tokenDetailsCoordinator.start(
            with: .init(info: tokenInfo, style: .marketsSheet)
        )

        self.tokenDetailsCoordinator = tokenDetailsCoordinator
    }
}

// MARK: - MarketsMainRoutable

extension MarketsCoordinator: MarketsMainRoutable {
    func openSeeAllTopMarketWidget() {
        openSeeAllMarket(with: .market)
    }

    func openSeeAllPulseMarketWidget(with orderType: MarketsListOrderType) {
        openSeeAllMarket(with: .pulse, orderType: orderType)
    }

    // MARK: - News

    func openSeeAllNewsWidget() {
        // [REDACTED_TODO_COMMENT]
    }

    func openNews(by id: NewsId) {
        // [REDACTED_TODO_COMMENT]
    }

    // MARK: - Private Implementation

    private func openSeeAllMarket(with widgetType: MarketsWidgetType, orderType: MarketsListOrderType? = nil) {
        let marketsSearchCoordinator = MarketsSearchCoordinator(
            dismissAction: { [weak self] in
                self?.marketsSearchCoordinator = nil
            }
        )

        marketsSearchCoordinator.start(
            with: .init(
                initialOrderType: orderType,
                quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper
            )
        )

        self.marketsSearchCoordinator = marketsSearchCoordinator
    }
}
