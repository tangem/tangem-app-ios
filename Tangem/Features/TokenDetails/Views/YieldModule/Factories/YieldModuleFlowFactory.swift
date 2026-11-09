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
        let gaslessFeeService = makeGaslessFeeService(transactionReleasesSourceToken: false)
        let interactor = makeInteractor(gaslessFeeService: gaslessFeeService)
        let startFlowFactory = makeStartFlowFactory(coordinator: coordinator, interactor: interactor, gaslessFeeService: gaslessFeeService)

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
        let gaslessFeeService = makeGaslessFeeService(transactionReleasesSourceToken: false)
        let interactor = makeInteractor(gaslessFeeService: gaslessFeeService)
        let startFlowFactory = makeStartFlowFactory(coordinator: coordinator, interactor: interactor, gaslessFeeService: gaslessFeeService)

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

    private func makeYieldModuleActiveViewModel(coordinator: YieldModuleActiveCoordinator) -> YieldModuleActiveViewModel {
        let claimInteractor = makeClaimInteractor()
        let gaslessFeeService = makeGaslessFeeService(transactionReleasesSourceToken: true)
        let interactor = makeInteractor(claimInteractor: claimInteractor, gaslessFeeService: gaslessFeeService)

        return YieldModuleActiveViewModel(
            walletModel: walletModel,
            coordinator: coordinator,
            transactionFlowFactory: makeTransactionFlowFactory(
                coordinator: coordinator,
                interactor: interactor,
                claimInteractor: claimInteractor,
                gaslessFeeService: gaslessFeeService
            ),
            yieldManagerInteractor: interactor,
            marketInfoPublisher: yieldModuleManager.marketInfoPublisher,
            claimInteractor: claimInteractor,
            notificationManager: YieldModuleNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem),
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )
    }

    // MARK: - Factories

    private func makeStartFlowFactory(
        coordinator: YieldModulePromoCoordinator,
        interactor: YieldManagerInteractor,
        gaslessFeeService: YieldGaslessFeeService?
    ) -> YieldStartFlowFactory {
        YieldStartFlowFactory(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            gaslessFeeService: gaslessFeeService,
            coordinator: coordinator,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId),
            signingActionButtonType: SigningActionButtonViewTypeBuilder().build(userWalletInfo: userWalletInfo)
        )
    }

    private func makeTransactionFlowFactory(
        coordinator: YieldModuleActiveCoordinator,
        interactor: YieldManagerInteractor,
        claimInteractor: YieldIncentivesClaimInteractor?,
        gaslessFeeService: YieldGaslessFeeService?
    ) -> YieldModuleTransactionFlowFactory {
        YieldModuleTransactionFlowFactory(
            walletModel: walletModel,
            yieldManagerInteractor: interactor,
            claimInteractor: claimInteractor,
            gaslessFeeService: gaslessFeeService,
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId),
            signingActionButtonType: SigningActionButtonViewTypeBuilder().build(userWalletInfo: userWalletInfo),
            coordinator: coordinator
        )
    }

    // MARK: - Interactor

    private func makeInteractor(
        claimInteractor: YieldIncentivesClaimInteractor? = nil,
        gaslessFeeService: YieldGaslessFeeService? = nil
    ) -> YieldManagerInteractor {
        YieldManagerInteractor(
            transactionDispatcher: transactionDispatcher,
            manager: yieldModuleManager,
            claimInteractor: claimInteractor,
            gaslessFeeService: gaslessFeeService
        )
    }

    private func makeGaslessFeeService(transactionReleasesSourceToken: Bool) -> YieldGaslessFeeService? {
        guard FeatureProvider.isAvailable(.yieldModeGasless),
              walletModel.tokenItem.blockchain.isGaslessTransactionSupported,
              !walletModel.isDemo,
              !walletModel.isJointAccountParticipant else {
            return nil
        }

        let signer = userWalletInfo.signerFactory.makeSigner()
        let transactionSender = YieldGaslessTransactionDispatcher(
            walletModel: walletModel,
            gaslessTransactionSender: GaslessTransactionSender(
                walletModel: walletModel,
                transactionSigner: signer,
                gaslessTransactionBuilder: GaslessTransactionBuilder(walletModel: walletModel, signer: signer)
            ),
            logger: CommonYieldAnalyticsLogger(tokenItem: walletModel.tokenItem, userWalletId: walletModel.userWalletId)
        )

        let tokenFeeProvidersManagerProvider = WalletModelTokenFeeProvidersManagerProvider(
            walletModel: walletModel,
            supportingOptions: .exactly([.market]),
            transactionReleasesSourceToken: transactionReleasesSourceToken,
            providerSwitching: .untilUserSelection
        )

        return YieldGaslessFeeService(
            coinFeeTokenItem: walletModel.feeTokenItem,
            transactionSender: transactionSender,
            makeTokenFeeProvidersManager: tokenFeeProvidersManagerProvider.makeTokenFeeProvidersManager
        )
    }

    private func makeClaimInteractor() -> YieldIncentivesClaimInteractor? {
        guard let chainId = walletModel.tokenItem.blockchain.chainId else {
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
    func makeYieldPromoCoordinator(
        apy: Decimal,
        isApyBoostPromo: Bool,
        dismissAction: @escaping Action<YieldModulePromoCoordinator.DismissOptions?>
    ) -> YieldModulePromoCoordinator {
        let coordinator = YieldModulePromoCoordinator(dismissAction: dismissAction)

        // The boost promo keeps the legacy screen: the boost takes precedence over a campaign pre-supply.
        let root: YieldModulePromoCoordinator.Root
        if !isApyBoostPromo {
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
        let viewModel = makeYieldModuleActiveViewModel(coordinator: coordinator)
        let options = YieldModuleActiveCoordinator.Options(viewModel: viewModel)

        coordinator.start(with: options)
        return coordinator
    }

    func makeYieldManagerInteractor() -> YieldManagerInteractor {
        makeInteractor()
    }
}
