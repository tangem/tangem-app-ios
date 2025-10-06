//
//  ActionButtonsSwapCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

typealias ActionButtonsTokenSelectorViewModel = TokenSelectorViewModel<
    ActionButtonsTokenSelectorItem,
    ActionButtonsTokenSelectorItemBuilder
>

final class ActionButtonsSwapCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Published property

    @Published private(set) var actionButtonsSwapViewModel: ActionButtonsSwapViewModel?
    @Published private(set) var expressCoordinator: ExpressCoordinator?

    // MARK: - Private property

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter
    private let userWalletModel: UserWalletModel
    private let yieldModuleNotificationInteractor: YieldModuleNoticeInteractor

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        userWalletModel: some UserWalletModel,
        dismissAction: @escaping Action<Void>,
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
        actionButtonsSwapViewModel = ActionButtonsSwapViewModel(
            coordinator: self,
            userWalletModel: userWalletModel,
            sourceSwapTokeSelectorViewModel: makeTokenSelectorViewModel()
        )
    }
}

// MARK: - Options

extension ActionButtonsSwapCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - ActionButtonsSwapRoutable

extension ActionButtonsSwapCoordinator: ActionButtonsSwapRoutable {
    func openExpress(
        for sourceWalletModel: any WalletModel,
        and destinationWalletModel: any WalletModel,
        with userWalletModel: UserWalletModel
    ) {
        let dismissAction: Action<(walletModel: any WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] _ in
            self?.dismiss()
        }

        expressCoordinator = makeExpressCoordinator(
            for: sourceWalletModel,
            and: destinationWalletModel,
            with: userWalletModel,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
    }

    func dismiss() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .swap)
        dismissAction(())
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

    func makeExpressCoordinator(
        for walletModel: any WalletModel,
        and destinationWalletModel: any WalletModel,
        with userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<(walletModel: any WalletModel, userWalletModel: UserWalletModel)?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> ExpressCoordinator {
        let input = CommonExpressModulesFactory.InputModel(
            userWalletModel: userWalletModel,
            initialWalletModel: walletModel,
            destinationWalletModel: destinationWalletModel
        )
        let factory = CommonExpressModulesFactory(inputModel: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        return coordinator
    }
}
