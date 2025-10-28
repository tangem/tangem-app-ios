//
//  YieldModuleFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class YieldModuleFlowFactory {
    private let apy: Decimal

    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private let yieldModuleManager: any YieldModuleManager
    private let transactionDispatcher: any TransactionDispatcher
    private let yieldPromoCoordinator: YieldModulePromoCoordinator
    private let feeCurrencyNavigator: (any FeeCurrencyNavigating)?
    private let yieldModuleNotificationInteractor = YieldModuleNoticeInteractor()

    // MARK: - Init

    init?(
        walletModel: any WalletModel,
        apy: Decimal = .zero,
        signer: any TangemSigner,
        feeCurrencyNavigator: (any FeeCurrencyNavigating)?,
        dismissAction: @escaping Action<Void>
    ) {
        guard let manager = walletModel.yieldModuleManager,
              let dispatcher = TransactionDispatcherFactory(walletModel: walletModel, signer: signer).makeYieldModuleDispatcher()
        else {
            return nil
        }

        yieldModuleManager = manager
        transactionDispatcher = dispatcher
        yieldPromoCoordinator = YieldModulePromoCoordinator(dismissAction: dismissAction)

        self.walletModel = walletModel
        self.apy = apy
        self.feeCurrencyNavigator = feeCurrencyNavigator
    }

    // MARK: - Public Implementation

    func getYieldPromoCoordinator() -> YieldModulePromoCoordinator {
        let viewModel = makeYieldPromoViewModel()
        let options = YieldModulePromoCoordinator.Options(viewModel: viewModel, feeCurrencyNavigator: feeCurrencyNavigator)

        yieldPromoCoordinator.start(with: options)
        return yieldPromoCoordinator
    }

    func makeYieldInfoViewModel() -> YieldModuleInfoViewModel? {
        return YieldModuleInfoViewModel(
            walletModel: walletModel,
            feeCurrencyNavigator: feeCurrencyNavigator,
            yieldManagerInteractor: makeInteractor(),
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem)
        )
    }

    // MARK: - Private Implementation

    private func makeYieldPromoViewModel() -> YieldModulePromoViewModel {
        let interactor = makeInteractor()
        let startFlowFactory = makeStartFlowFactory(interactor: interactor)

        return YieldModulePromoViewModel(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            apy: apy,
            coordinator: yieldPromoCoordinator,
            startFlowFactory: startFlowFactory,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem)
        )
    }

    private func makeYieldPromoViewModel(coordinator: YieldModulePromoCoordinator) -> YieldModulePromoViewModel {
        let interactor = makeInteractor()
        let startFlowFactory = makeStartFlowFactory(interactor: interactor)

        return YieldModulePromoViewModel(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            apy: apy,
            coordinator: coordinator,
            startFlowFactory: startFlowFactory,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem)
        )
    }

    private func makeInteractor() -> YieldManagerInteractor {
        YieldManagerInteractor(
            transactionDispatcher: transactionDispatcher,
            manager: yieldModuleManager,
            yieldModuleNotificationInteractor: yieldModuleNotificationInteractor
        )
    }

    private func makeStartFlowFactory(interactor: YieldManagerInteractor) -> YieldStartFlowFactory {
        YieldStartFlowFactory(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            coordinator: yieldPromoCoordinator,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem)
        )
    }
}
