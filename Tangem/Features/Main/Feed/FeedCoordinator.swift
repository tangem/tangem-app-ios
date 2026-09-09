//
//  FeedCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUI

final class FeedCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: FeedViewModel?
    @Published var path: [FeedDestination] = []

    let shtorkaStateObject = MainShtorkaStateObject()

    // MARK: - Child sheets

    @Published var portfolioTokenList: MarketsPortfolioTokenListViewModel?

    /// Holds whichever filter sheet is on screen or queued, so a second tap can't stack another one behind it.
    /// Weak on purpose: a sheet that goes away without its dismiss handler - `removeAllSheets()`, say - clears the
    /// reference by itself instead of locking the filter routes out for good.
    private weak var presentedFilterSheet: AnyObject?

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.earnDataFilterProvider) private var earnFilterProvider: EarnDataFilterProvider
    @Injected(\.earnAnalyticsProvider) private var earnAnalyticsProvider: EarnAnalyticsProvider

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = FeedViewModelFactory().makeViewModel(coordinator: self)
    }

    private func pop() {
        _ = path.popLast()
    }
}

// MARK: - Options

extension FeedCoordinator {
    struct Options {}
}

// MARK: - FeedRoutable

extension FeedCoordinator: FeedRoutable {
    func openToken(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(info: token, style: .marketsSheet))
        path.append(.token(coordinator))
    }

    func openPulseTagFilter(with input: PulseTagFilterInput) {
        Task { @MainActor [weak self] in
            guard let self, presentedFilterSheet == nil else { return }

            let viewModel = PulseTagFilterBottomSheetViewModel(
                input: input,
                onDismiss: { [weak self] in
                    self?.dismissFilterSheet()
                }
            )

            present(filterSheet: viewModel)
        }
    }

    func openRealAssetsCategoryFilter(with input: RealAssetsCategoryFilterInput) {
        Task { @MainActor [weak self] in
            guard let self, presentedFilterSheet == nil else { return }

            let viewModel = MarketsRealAssetsFilterBottomSheetViewModel(
                input: input,
                onDismiss: { [weak self] in
                    self?.dismissFilterSheet()
                }
            )

            present(filterSheet: viewModel)
        }
    }

    func openEarnNetworksFilter() {
        Task { @MainActor [weak self] in
            guard let self, presentedFilterSheet == nil else { return }

            let viewModel = EarnNetworkFilterBottomSheetViewModel(
                filterProvider: earnFilterProvider,
                analyticsProvider: earnAnalyticsProvider,
                onDismiss: { [weak self] in
                    self?.dismissFilterSheet()
                }
            )

            present(filterSheet: viewModel)
        }
    }

    func openEarnTypesFilter() {
        Task { @MainActor [weak self] in
            guard let self, presentedFilterSheet == nil else { return }

            let viewModel = EarnTypeFilterBottomSheetViewModel(
                filterProvider: earnFilterProvider,
                analyticsProvider: earnAnalyticsProvider,
                onDismiss: { [weak self] in
                    self?.dismissFilterSheet()
                }
            )

            present(filterSheet: viewModel)
        }
    }

    func routeOnEarnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {
        switch resolution {
        case .toAdd(let token, let userWalletModels):
            openAddEarnToken(for: token, userWalletModels: userWalletModels, source: source)
        case .alreadyAdded(let walletModel, _):
            openPortfolioToken(walletModel)
        }
    }

    func openPortfolioToken(_ walletModel: any WalletModel) {
        guard
            let userWalletModel = userWalletRepository.models[walletModel.userWalletId],
            let accountModel = walletModel.account
        else {
            return
        }

        let coordinator = TokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.pop() },
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
        path.append(.portfolioToken(coordinator))
    }

    func choosePortfolioToken(from walletModels: [any WalletModel]) {
        portfolioTokenList = MarketsPortfolioTokenListViewModel(
            walletModels: walletModels,
            onSelect: { [weak self] walletModel in self?.openPortfolioToken(walletModel) },
            coordinator: self
        )
    }

    func returnToRoot() {
        guard path.isNotEmpty || rootViewModel?.searchViewModel.isActive == true else {
            return
        }

        withTransaction(.withoutAnimations()) {
            path.removeAll()
            portfolioTokenList = nil
            rootViewModel?.searchViewModel.reset()
        }
    }
}

// MARK: - Filter sheets

@MainActor
private extension FeedCoordinator {
    func present(filterSheet viewModel: some FloatingSheetContentViewModel & AnyObject) {
        presentedFilterSheet = viewModel
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func dismissFilterSheet() {
        presentedFilterSheet = nil
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - Earn

private extension FeedCoordinator {
    func openAddEarnToken(
        for token: EarnTokenModel,
        userWalletModels: [any UserWalletModel],
        source: EarnOpportunitySource
    ) {
        earnAnalyticsProvider.logAddTokenScreenOpened(
            token: token.symbol,
            blockchain: token.networkName,
            source: source.rawValue
        )

        let configuration = EarnAddTokenFlowConfigurationFactory.make(
            earnToken: token,
            coordinator: self,
            analyticsProvider: earnAnalyticsProvider
        )

        Task { @MainActor [weak self] in
            guard let self else { return }

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

extension FeedCoordinator: EarnAddTokenRoutable {
    func presentTokenDetails(by walletModel: any WalletModel, with userWalletModel: UserWalletModel) {
        openPortfolioToken(walletModel)
    }

    func close() {
        floatingSheetPresenter.removeActiveSheet()
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
}

// MARK: - MarketsPortfolioTokenListRoutable

extension FeedCoordinator: MarketsPortfolioTokenListRoutable {
    func closePortfolioTokenList() {
        portfolioTokenList = nil
    }
}

// MARK: - Constants

private extension FeedCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }
}
