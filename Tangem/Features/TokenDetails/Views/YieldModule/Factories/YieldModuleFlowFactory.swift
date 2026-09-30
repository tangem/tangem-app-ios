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
        isApyBoostPromo: Bool,
        dismissAction: @escaping Action<YieldModulePromoCoordinator.DismissOptions?>
    ) -> YieldModulePromoCoordinator

    func makeYieldActiveCoordinator(
        dismissAction: @escaping Action<YieldModuleActiveCoordinator.DismissOptions?>
    ) -> YieldModuleActiveCoordinator

    func makeYieldAvailableNotificationViewModel(
        apy: Decimal,
        style: YieldAvailableNotificationViewModel.Style,
        onLearnMoreTap: @escaping (Decimal) -> Void,
        onActivateTap: ((Decimal) -> Void)?
    ) -> YieldAvailableNotificationViewModel

    func makeYieldStatusViewModel(
        state: YieldStatusViewModel.State,
        navigationAction: @escaping () -> Void
    ) -> YieldStatusViewModel

    func makeYieldModuleBalanceInfoViewModel() -> YieldModuleBalanceInfoViewModel

    func makeYieldManagerInteractor() -> YieldManagerInteractor
}

final class CommonYieldModuleFlowFactory {
    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private let transactionDispatcher: any TransactionDispatcher
    private let yieldModuleManager: any YieldModuleManager

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        yieldModuleManager: YieldModuleManager,
        transactionDispatcher: any TransactionDispatcher
    ) {
        self.yieldModuleManager = yieldModuleManager
        self.transactionDispatcher = transactionDispatcher
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
    }

    // MARK: - View Models

    private func makeYieldPromoViewModel(
        apy: Decimal,
        isApyBoostPromo: Bool,
        coordinator: YieldModulePromoCoordinator
    ) -> YieldModulePromoViewModel {
        let interactor = makeInteractor()
        let startFlowFactory = makeStartFlowFactory(coordinator: coordinator, interactor: interactor)

        return YieldModulePromoViewModel(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo,
            yieldManagerInteractor: interactor,
            apy: apy,
            isApyBoostPromo: isApyBoostPromo,
            coordinator: coordinator,
            startFlowFactory: startFlowFactory,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }

    private func makeYieldPromoV2ViewModel(
        apy: Decimal,
        coordinator: YieldModulePromoCoordinator
    ) -> YieldModulePromoV2ViewModel {
        let interactor = makeInteractor()
        let startFlowFactory = makeStartFlowFactory(coordinator: coordinator, interactor: interactor)

        return YieldModulePromoV2ViewModel(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo,
            apy: apy,
            marketIncentive: yieldModuleManager.state?.marketInfo?.incentive,
            coordinator: coordinator,
            startFlowFactory: startFlowFactory,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }

    private func makeYieldModuleActiveViewModel(
        coordinator: YieldModuleActiveCoordinator,
        usesIncentiveDesign: Bool
    ) -> YieldModuleActiveViewModel {
        let interactor = makeInteractor()
        let claimInteractor = makeClaimInteractor()

        return YieldModuleActiveViewModel(
            walletModel: walletModel,
            coordinator: coordinator,
            transactionFlowFactory: makeTransactionFlowFactory(
                coordinator: coordinator,
                interactor: interactor,
                claimInteractor: claimInteractor
            ),
            yieldManagerInteractor: interactor,
            marketInfoPublisher: yieldModuleManager.marketInfoPublisher,
            claimInteractor: claimInteractor,
            notificationManager: YieldModuleNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem),
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId),
            usesIncentiveDesign: usesIncentiveDesign
        )
    }

    // MARK: - Factories

    private func makeStartFlowFactory(coordinator: YieldModulePromoCoordinator, interactor: YieldManagerInteractor) -> YieldStartFlowFactory {
        YieldStartFlowFactory(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            coordinator: coordinator,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId),
            tangemIconProvider: CommonTangemIconProvider(hasNFCInteraction: transactionDispatcher.hasNFCInteraction),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(dispatcher: transactionDispatcher)
        )
    }

    private func makeTransactionFlowFactory(
        coordinator: YieldModuleActiveCoordinator,
        interactor: YieldManagerInteractor,
        claimInteractor: YieldIncentivesClaimInteractor?
    ) -> YieldModuleTransactionFlowFactory {
        YieldModuleTransactionFlowFactory(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            claimInteractor: claimInteractor,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId),
            tangemIconProvider: CommonTangemIconProvider(hasNFCInteraction: transactionDispatcher.hasNFCInteraction),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(dispatcher: transactionDispatcher),
            coordinator: coordinator
        )
    }

    // MARK: - Interactor

    private func makeInteractor() -> YieldManagerInteractor {
        YieldManagerInteractor(
            transactionDispatcher: transactionDispatcher,
            manager: yieldModuleManager
        )
    }

    private func makeClaimInteractor() -> YieldIncentivesClaimInteractor? {
        guard FeatureProvider.isAvailable(.merklIncentives),
              let chainId = walletModel.tokenItem.blockchain.chainId else {
            return nil
        }

        let userAddress = walletModel.defaultAddressString

        return YieldIncentivesClaimInteractor(
            chainId: chainId,
            userAddress: userAddress,
            manager: yieldModuleManager,
            transactionDispatcher: transactionDispatcher,
            tracker: InjectedValues[\.yieldIncentivesClaimTrackerProvider].tracker(chainId: chainId, userAddress: userAddress)
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

    func makeYieldAvailableNotificationViewModel(
        apy: Decimal,
        style: YieldAvailableNotificationViewModel.Style,
        onLearnMoreTap: @escaping (Decimal) -> Void,
        onActivateTap: ((Decimal) -> Void)?
    ) -> YieldAvailableNotificationViewModel {
        YieldAvailableNotificationViewModel(
            apy: apy,
            style: style,
            onLearnMoreTap: onLearnMoreTap,
            onActivateTap: onActivateTap
        )
    }

    func makeYieldPromoCoordinator(
        apy: Decimal,
        isApyBoostPromo: Bool,
        dismissAction: @escaping Action<YieldModulePromoCoordinator.DismissOptions?>
    ) -> YieldModulePromoCoordinator {
        let coordinator = YieldModulePromoCoordinator(dismissAction: dismissAction)

        // The boost promo keeps the legacy screen: the boost takes precedence over a campaign pre-supply.
        let root: YieldModulePromoCoordinator.Root
        if FeatureProvider.isAvailable(.merklIncentives), !isApyBoostPromo {
            root = .v2(makeYieldPromoV2ViewModel(apy: apy, coordinator: coordinator))
        } else {
            root = .legacy(makeYieldPromoViewModel(apy: apy, isApyBoostPromo: isApyBoostPromo, coordinator: coordinator))
        }

        coordinator.start(with: YieldModulePromoCoordinator.Options(root: root))
        return coordinator
    }

    func makeYieldActiveCoordinator(
        dismissAction: @escaping Action<YieldModuleActiveCoordinator.DismissOptions?>
    ) -> YieldModuleActiveCoordinator {
        let coordinator = YieldModuleActiveCoordinator(dismissAction: dismissAction)
        let usesIncentiveDesign = FeatureProvider.isAvailable(.merklIncentives)
        let viewModel = makeYieldModuleActiveViewModel(coordinator: coordinator, usesIncentiveDesign: usesIncentiveDesign)
        let options = YieldModuleActiveCoordinator.Options(
            viewModel: viewModel,
            usesIncentiveDesign: usesIncentiveDesign
        )

        coordinator.start(with: options)
        return coordinator
    }

    func makeYieldManagerInteractor() -> YieldManagerInteractor {
        makeInteractor()
    }
}
