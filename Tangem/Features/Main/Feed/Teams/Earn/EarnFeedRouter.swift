//
//  EarnFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics
import TangemFoundation
import TangemUI

protocol EarnFeedRoutable: AnyObject {
    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource)
    func openNetworksFilter()
    func openTypesFilter()
}

final class EarnFeedRouter {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.earnDataFilterProvider) private var filterProvider: EarnDataFilterProvider
    @Injected(\.earnAnalyticsProvider) private var analyticsProvider: EarnAnalyticsProvider

    private weak var navigation: (any FeedNavigation)?

    /// Holds whichever filter sheet is on screen or queued, so a second tap can't stack another one behind it.
    /// Weak on purpose: a sheet that goes away without its dismiss handler — `removeAllSheets()`, say — clears the
    /// reference by itself instead of locking the filter routes out for good.
    private weak var presentedFilterSheet: AnyObject?

    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
    }
}

// MARK: - EarnFeedRoutable

extension EarnFeedRouter: EarnFeedRoutable {
    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {
        switch resolution {
        case .toAdd(let token, let userWalletModels):
            openAddToken(for: token, userWalletModels: userWalletModels, source: source)
        case .alreadyAdded(let walletModel, _):
            openPortfolioToken(walletModel)
        }
    }

    func openNetworksFilter() {
        Task { @MainActor [weak self] in
            guard let self, presentedFilterSheet == nil else {
                return
            }

            let viewModel = EarnNetworkFilterBottomSheetViewModel(
                filterProvider: filterProvider,
                analyticsProvider: analyticsProvider,
                onDismiss: { [weak self] in self?.dismissFilterSheet() }
            )

            present(filterSheet: viewModel)
        }
    }

    func openTypesFilter() {
        Task { @MainActor [weak self] in
            guard let self, presentedFilterSheet == nil else {
                return
            }

            let viewModel = EarnTypeFilterBottomSheetViewModel(
                filterProvider: filterProvider,
                analyticsProvider: analyticsProvider,
                onDismiss: { [weak self] in self?.dismissFilterSheet() }
            )

            present(filterSheet: viewModel)
        }
    }
}

// MARK: - Filter sheets

@MainActor
private extension EarnFeedRouter {
    func present(filterSheet viewModel: some FloatingSheetContentViewModel & AnyObject) {
        presentedFilterSheet = viewModel
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func dismissFilterSheet() {
        presentedFilterSheet = nil
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - Portfolio token

private extension EarnFeedRouter {
    func openPortfolioToken(_ walletModel: any WalletModel) {
        guard
            let userWalletModel = userWalletRepository.models[walletModel.userWalletId],
            let accountModel = walletModel.account
        else {
            return
        }

        let coordinator = TokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.navigation?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: accountModel.walletModelsManager,
                userTokensManager: accountModel.userTokensManager,
                addressBookManager: userWalletModel.addressBookManager,
                walletModel: walletModel,
                presentSource: .markets
            )
        )
        navigation?.push(.portfolioToken(coordinator))
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
        openPortfolioToken(walletModel)
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
