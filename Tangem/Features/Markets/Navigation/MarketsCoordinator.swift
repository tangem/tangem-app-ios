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

    private var openFeeCurrency: OpenFeeCurrency?

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
        openFeeCurrency = options.openFeeCurrency
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
    struct Options {
        let openFeeCurrency: OpenFeeCurrency?
    }
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
            with: .init(info: tokenInfo, style: .marketsSheet, openFeeCurrency: openFeeCurrency)
        )

        self.tokenDetailsCoordinator = tokenDetailsCoordinator
    }
}

// MARK: - MarketsMainRoutable

extension MarketsCoordinator: MarketsMainRoutable {
    func openSeeAll(with widgetType: MarketsWidgetType) {
        switch widgetType {
        case .market, .pulse:
            let marketsSearchCoordinator = MarketsSearchCoordinator(
                dismissAction: { [weak self] in
                    self?.marketsSearchCoordinator = nil
                }
            )

            marketsSearchCoordinator.start(with: .init(quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper))

            self.marketsSearchCoordinator = marketsSearchCoordinator
        case .earn, .news:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }
}
