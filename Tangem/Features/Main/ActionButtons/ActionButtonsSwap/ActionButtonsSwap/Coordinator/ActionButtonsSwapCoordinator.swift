//
//  ActionButtonsSwapCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

typealias ActionButtonsTokenSelectorViewModel = TokenSelectorViewModel<
    ActionButtonsTokenSelectorItem,
    ActionButtonsTokenSelectorItemBuilder
>

final class ActionButtonsSwapCoordinator: CoordinatorObject {
    let dismissAction: Action<ExpressCoordinator.DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Published

    @Published private(set) var viewType: ViewType?

    // MARK: - Private property

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter
    private let userWalletModel: UserWalletModel
    private let yieldModuleNotificationInteractor: YieldModuleNoticeInteractor

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        userWalletModel: some UserWalletModel,
        dismissAction: @escaping Action<ExpressCoordinator.DismissOptions?>,
        tokenSorter: some TokenAvailabilitySorter,
        yieldModuleNotificationInteractor: YieldModuleNoticeInteractor,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.tokenSorter = tokenSorter
        self.expressTokensListAdapter = expressTokensListAdapter
        self.userWalletModel = userWalletModel
        self.yieldModuleNotificationInteractor = yieldModuleNotificationInteractor
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .default:
            viewType = .legacy(ActionButtonsSwapViewModel(
                coordinator: self,
                userWalletModel: userWalletModel,
                sourceSwapTokenSelectorViewModel: makeTokenSelectorViewModel()
            ))
        case .new(let tokenSelectorViewModel):
            // Create external search view model if feature toggle is enabled
            let marketsTokensViewModel: SwapMarketsTokensViewModel?
            if FeatureProvider.isAvailable(.expressAllTokensSearch) {
                marketsTokensViewModel = SwapMarketsTokensViewModel()
            } else {
                marketsTokensViewModel = nil
            }

            viewType = .new(
                AccountsAwareActionButtonsSwapViewModel(
                    tokenSelectorViewModel: tokenSelectorViewModel,
                    marketsTokensViewModel: marketsTokensViewModel,
                    coordinator: self
                )
            )
        }
    }
}

// MARK: - Options

extension ActionButtonsSwapCoordinator {
    enum Options {
        case `default`
        case new(tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel)
    }
}

// MARK: - ActionButtonsSwapRoutable

extension ActionButtonsSwapCoordinator: ActionButtonsSwapRoutable {
    func openExpress(input: ExpressDependenciesInput) {
        let factory = CommonExpressModulesFactory(input: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)
        viewType = .express(coordinator)
    }

    func dismiss() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .swap)
        dismiss(with: .none)
    }

    func showYieldNotificationIfNeeded(for walletModel: any WalletModel, completion: (() -> Void)?) {
        guard yieldModuleNotificationInteractor.shouldShowYieldModuleAlert(for: walletModel.tokenItem) else {
            completion.map { $0() }
            return
        }

        Task { @MainActor in
            let vm = YieldNoticeViewModel(tokenItem: walletModel.tokenItem) { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
                completion.map { $0() }
            }

            floatingSheetPresenter.enqueue(sheet: vm)
        }
    }
}

// MARK: - Factory methods

private extension ActionButtonsSwapCoordinator {
    func makeTokenSelectorViewModel() -> ActionButtonsTokenSelectorViewModel {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: SwapTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}

extension ActionButtonsSwapCoordinator {
    enum ViewType: Identifiable {
        case legacy(ActionButtonsSwapViewModel)
        case new(AccountsAwareActionButtonsSwapViewModel)
        case express(ExpressCoordinator)

        var id: String {
            switch self {
            case .legacy: "legacy"
            case .new: "new"
            case .express: "express"
            }
        }
    }
}

// MARK: - Constants

private extension ActionButtonsSwapCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }
}
