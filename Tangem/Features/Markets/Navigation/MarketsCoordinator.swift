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
import TangemUI

class MarketsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root Published

    @Published private(set) var marketsViewModel: MarketsViewModel?
    @Published private(set) var marketsMainViewModel: MarketsMainViewModel?

    // MARK: - Coordinators

    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var mainTokenDetailsCoordinator: TokenDetailsCoordinator? = nil
    @Published var marketsSearchCoordinator: MarketsSearchCoordinator?
    @Published var newsListCoordinator: NewsListCoordinator?
    @Published var newsPagerViewModel: NewsPagerViewModel?
    @Published var newsPagerTokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var earnListCoordinator: EarnCoordinator?

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
        let coordinator = NewsListCoordinator(
            dismissAction: { [weak self] in
                self?.newsListCoordinator = nil
            }
        )

        coordinator.start(with: .init())

        newsListCoordinator = coordinator
    }

    func openNewsDetails(newsIds: [Int], selectedIndex: Int) {
        let viewModel = NewsPagerViewModel(
            newsIds: newsIds,
            initialIndex: selectedIndex,
            dataSource: SingleNewsDataSource(),
            analyticsSource: .markets,
            coordinator: self
        )
        newsPagerViewModel = viewModel
    }

    // MARK: - Earn

    func routeOnTokenResolved(_ resolution: EarnTokenResolution) {
        switch resolution {
        case .toAdd(let token, let userWalletModels):
            openAddEarnToken(for: token, userWalletModels: userWalletModels)
        case .alreadyAdded(let walletModel, let userWalletModel):
            openMainTokenDetails(walletModel: walletModel, with: userWalletModel)
        }
    }

    private func openAddEarnToken(for token: EarnTokenModel, userWalletModels: [any UserWalletModel]) {
        let configuration = EarnAddTokenFlowConfigurationFactory.make(
            earnToken: token,
            coordinator: self
        )

        Task { @MainActor in
            let viewModel = AccountsAwareAddTokenFlowViewModel(
                userWalletModels: userWalletModels,
                configuration: configuration,
                coordinator: self
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openSeeAllEarnWidget(mostlyUsedTokens: [EarnTokenModel]) {
        let coordinator = EarnCoordinator(
            dismissAction: { [weak self] in
                self?.earnListCoordinator = nil
            },
            routeOnEarnTokenResolvedAction: { [weak self] resolution in
                self?.routeOnTokenResolved(resolution)
            }
        )

        coordinator.start(with: .init(mostlyUsedTokens: mostlyUsedTokens))

        earnListCoordinator = coordinator
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

// MARK: - EarnAddTokenRoutable, AccountsAwareAddTokenFlowRoutable

extension MarketsCoordinator: EarnAddTokenRoutable {
    func presentTokenDetails(by walletModel: any WalletModel, with userWalletModel: any UserWalletModel) {
        openMainTokenDetails(walletModel: walletModel, with: userWalletModel)
    }

    func close() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func presentSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }

    private func openMainTokenDetails(walletModel: any WalletModel, with userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.mainTokenDetailsCoordinator = nil
        }

        guard let coordinator = MarketsMainTokenDetailsCoordinatorFactory.make(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            dismissAction: dismissAction
        ) else {
            return
        }

        mainTokenDetailsCoordinator = coordinator
    }
}

// MARK: - NewsDetailsRoutable (for widget pager)

extension MarketsCoordinator: NewsDetailsRoutable {
    func dismissNewsDetails() {
        newsPagerViewModel = nil
    }

    func share(url: String) {
        guard let url = URL(string: url) else { return }
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openTokenDetails(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in
                self?.newsPagerTokenDetailsCoordinator = nil
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(info: token, style: .marketsSheet))
        newsPagerTokenDetailsCoordinator = coordinator
    }
}

private extension MarketsCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }
}
