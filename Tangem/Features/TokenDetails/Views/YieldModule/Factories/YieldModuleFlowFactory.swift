//
//  YieldModuleFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol YieldModuleFlowFactory {
    func makeYieldPromoCoordinator(
        apy: Decimal,
        dismissAction: @escaping Action<YieldModulePromoCoordinator.DismissOptions?>
    ) -> YieldModulePromoCoordinator

    func makeYieldActiveCoordinator(
        dismissAction: @escaping Action<YieldModuleActiveCoordinator.DismissOptions?>
    ) -> YieldModuleActiveCoordinator

    func makeYieldAvailableNotificationViewModel(
        apy: Decimal,
        onButtonTap: @escaping (Decimal) -> Void
    ) -> YieldAvailableNotificationViewModel

    func makeYieldStatusViewModel(
        state: YieldStatusViewModel.State,
        navigationAction: @escaping () -> Void
    ) -> YieldStatusViewModel

    func makeYieldModuleBalanceInfoViewModel() -> YieldModuleBalanceInfoViewModel
}

final class CommonYieldModuleFlowFactory {
    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private let transactionDispatcher: any TransactionDispatcher
    private let yieldModuleNotificationInteractor = YieldModuleNoticeInteractor()
    private let yieldModuleManager: any YieldModuleManager

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldModuleManager: YieldModuleManager,
        transactionDispatcher: any TransactionDispatcher
    ) {
        self.yieldModuleManager = yieldModuleManager
        self.transactionDispatcher = transactionDispatcher
        self.walletModel = walletModel
    }

    // MARK: - View Models

    private func makeYieldPromoViewModel(apy: Decimal, coordinator: YieldModulePromoCoordinator) -> YieldModulePromoViewModel {
        let interactor = makeInteractor()
        let startFlowFactory = makeStartFlowFactory(coordinator: coordinator, interactor: interactor)

        return YieldModulePromoViewModel(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            apy: apy,
            coordinator: coordinator,
            startFlowFactory: startFlowFactory,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }

    private func makeYieldModuleActiveViewModel(coordinator: YieldModuleActiveCoordinator) -> YieldModuleActiveViewModel {
        let interactor = makeInteractor()

        return YieldModuleActiveViewModel(
            walletModel: walletModel,
            coordinator: coordinator,
            transactionFlowFactory: makeTransactionFlowFactory(coordinator: coordinator, interactor: interactor),
            yieldManagerInteractor: interactor,
            notificationManager: YieldModuleNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem),
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }

    // MARK: - Factories

    private func makeStartFlowFactory(coordinator: YieldModulePromoCoordinator, interactor: YieldManagerInteractor) -> YieldStartFlowFactory {
        YieldStartFlowFactory(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            coordinator: coordinator,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }

    private func makeTransactionFlowFactory(
        coordinator: YieldModuleActiveCoordinator,
        interactor: YieldManagerInteractor
    ) -> YieldModuleTransactionFlowFactory {
        YieldModuleTransactionFlowFactory(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId),
            coordinator: coordinator
        )
    }

    // MARK: - Interactor

    private func makeInteractor() -> YieldManagerInteractor {
        YieldManagerInteractor(
            transactionDispatcher: transactionDispatcher,
            manager: yieldModuleManager,
            yieldModuleNotificationInteractor: yieldModuleNotificationInteractor
        )
    }
}

// MARK: - YieldModuleFlowFactory

extension CommonYieldModuleFlowFactory: YieldModuleFlowFactory {
    func makeYieldModuleBalanceInfoViewModel() -> YieldModuleBalanceInfoViewModel {
        YieldModuleBalanceInfoViewModel(tokenName: walletModel.tokenItem.name, tokenId: walletModel.tokenItem.id)
    }

    func makeYieldStatusViewModel(state: YieldStatusViewModel.State, navigationAction: @escaping () -> Void) -> YieldStatusViewModel {
        YieldStatusViewModel(
            state: state,
            yieldInteractor: makeInteractor(),
            feeTokenItem: walletModel.feeTokenItem,
            token: walletModel.tokenItem,
            navigationAction: navigationAction
        )
    }

    func makeYieldAvailableNotificationViewModel(apy: Decimal, onButtonTap: @escaping (Decimal) -> Void) -> YieldAvailableNotificationViewModel {
        YieldAvailableNotificationViewModel(
            apy: apy,
            onButtonTap: onButtonTap
        )
    }

    func makeYieldPromoCoordinator(
        apy: Decimal,
        dismissAction: @escaping Action<YieldModulePromoCoordinator.DismissOptions?>
    ) -> YieldModulePromoCoordinator {
        let coordinator = YieldModulePromoCoordinator(dismissAction: dismissAction)
        let viewModel = makeYieldPromoViewModel(apy: apy, coordinator: coordinator)
        let options = YieldModulePromoCoordinator.Options(viewModel: viewModel)

        coordinator.start(with: options)
        return coordinator
    }

    func makeYieldActiveCoordinator(
        dismissAction: @escaping Action<YieldModuleActiveCoordinator.DismissOptions?>
    ) -> YieldModuleActiveCoordinator {
        let coordinator = YieldModuleActiveCoordinator(dismissAction: dismissAction)
        let viewModel = makeYieldModuleActiveViewModel(coordinator: coordinator)
        let options = YieldModuleActiveCoordinator.Options(viewModel: viewModel)

        coordinator.start(with: options)
        return coordinator
    }
}
