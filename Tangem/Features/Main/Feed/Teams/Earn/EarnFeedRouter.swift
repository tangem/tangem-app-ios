//
//  EarnFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics
import TangemUI

protocol EarnFeedRoutable: AnyObject {
    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource)
    func openPortfolioToken(_ walletModel: any WalletModel)
    func openNetworksFilter()
    func openTypesFilter()
}

final class EarnFeedRouter {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.earnDataFilterProvider) private var filterProvider: EarnDataFilterProvider
    @Injected(\.earnAnalyticsProvider) private var analyticsProvider: EarnAnalyticsProvider

    private weak var navigation: (any FeedNavigation)?

    private let portfolioTokenRouter: FeedPortfolioTokenRouter

    init(context: FeedContext) {
        navigation = context.navigation
        portfolioTokenRouter = FeedPortfolioTokenRouter(context: context)
    }
}

// MARK: - EarnFeedRoutable

extension EarnFeedRouter: EarnFeedRoutable {
    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {
        switch resolution {
        case .toAdd(let token, let userWalletModels):
            openAddToken(for: token, userWalletModels: userWalletModels, source: source)
        case .alreadyAdded(let walletModel, _):
            portfolioTokenRouter.push(walletModel)
        }
    }

    func openPortfolioToken(_ walletModel: any WalletModel) {
        portfolioTokenRouter.open(walletModel)
    }

    func openNetworksFilter() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let viewModel = EarnNetworkFilterBottomSheetViewModel(
                filterProvider: filterProvider,
                analyticsProvider: analyticsProvider,
                onDismiss: { [weak self] in self?.navigation?.dismissModal() }
            )

            navigation?.presentModal(.earnNetworkFilter(viewModel))
        }
    }

    func openTypesFilter() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let viewModel = EarnTypeFilterBottomSheetViewModel(
                filterProvider: filterProvider,
                analyticsProvider: analyticsProvider,
                onDismiss: { [weak self] in self?.navigation?.dismissModal() }
            )

            navigation?.presentModal(.earnTypeFilter(viewModel))
        }
    }
}

// MARK: - Add token

private extension EarnFeedRouter {
    func openAddToken(
        for token: EarnTokenModel,
        userWalletModels: [any UserWalletModel],
        source: EarnOpportunitySource
    ) {
        analyticsProvider.logAddTokenScreenOpened(
            token: token.symbol,
            blockchain: token.networkName,
            source: source.rawValue
        )

        let configuration = EarnAddTokenFlowConfigurationFactory.make(
            earnToken: token,
            coordinator: self,
            analyticsProvider: analyticsProvider
        )

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let viewModel = AddTokenFlowViewModel(
                userWalletModels: userWalletModels,
                configuration: configuration,
                coordinator: self
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - EarnAddTokenRoutable

extension EarnFeedRouter: EarnAddTokenRoutable {
    func presentTokenDetails(by walletModel: any WalletModel, with userWalletModel: UserWalletModel) {
        portfolioTokenRouter.push(walletModel)
    }

    func close() {
        floatingSheetPresenter.removeActiveSheet()
    }

    func presentSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: Constants.toastTopPadding),
                type: .temporary()
            )
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: Constants.toastTopPadding),
                type: .temporary()
            )
    }
}

// MARK: - Constants

private extension EarnFeedRouter {
    enum Constants {
        static let toastTopPadding: CGFloat = 52
    }
}
