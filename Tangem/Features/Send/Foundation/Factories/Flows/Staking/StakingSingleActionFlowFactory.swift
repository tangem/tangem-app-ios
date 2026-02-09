//
//  StakingSingleActionFlowFactory 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import struct TangemUI.TokenIconInfo

class StakingSingleActionFlowFactory: StakingFlowDependenciesFactory {
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let userWalletInfo: UserWalletInfo

    let manager: any StakingManager
    let action: RestakingModel.Action
    var actionType: StakingAction.ActionType { action.displayType }

    let tokenFeeProvidersManager: TokenFeeProvidersManager
    let tokenHeaderProvider: SendGenericTokenHeaderProvider
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let transactionDispatcherProvider: any TransactionDispatcherProvider
    /// Staking doesn't support account-based analytics
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? = nil

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var actionModel = makeStakingSingleActionModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager(analyticsLogger: analyticsLogger)

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        manager: any StakingManager,
        action: StakingSingleActionModel.Action,
    ) {
        self.userWalletInfo = userWalletInfo
        self.manager = manager
        self.action = action

        tokenHeaderProvider = SendTokenHeaderProvider(
            userWalletInfo: userWalletInfo,
            account: walletModel.account,
            flowActionType: action.displayType.sendFlowActionType
        )
        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )

        tokenFeeProvidersManager = TokenFeeProvidersManagerBuilder(walletModel: walletModel).makeTokenFeeProvidersManager()
        walletModelDependenciesProvider = walletModel
        availableBalanceProvider = walletModel.availableBalanceProvider
        fiatAvailableBalanceProvider = walletModel.fiatAvailableBalanceProvider
        transactionDispatcherProvider = WalletModelTransactionDispatcherProvider(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )
        baseDataBuilderFactory = SendBaseDataBuilderFactory(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo
        )
    }
}

// MARK: - Model

extension StakingSingleActionFlowFactory {
    func makeStakingSingleActionModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger
    ) -> StakingSingleActionModel {
        StakingSingleActionModel(
            stakingManager: stakingManager,
            sendSourceToken: makeSourceToken(),
            analyticsLogger: analyticsLogger,
            action: action,
        )
    }
}

// MARK: - SendGenericFlowFactory

extension StakingSingleActionFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let sendAmountCompactViewModel = SendAmountCompactViewModel(
            sourceTokenInput: actionModel,
            sourceTokenAmountInput: actionModel
        )

        let sendAmountFinishViewModel = SendAmountFinishViewModel(
            sourceTokenInput: actionModel,
            sourceTokenAmountInput: actionModel
        )

        let sendFeeCompactViewModel = SendFeeCompactViewModel()
        let sendFeeFinishViewModel = SendFeeFinishViewModel()

        let summary = makeSendSummaryStep(
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: actionModel)
        sendFeeFinishViewModel.bind(input: actionModel)

        // Notifications setup
        notificationManager.setup(provider: actionModel, input: actionModel)
        notificationManager.setupManager(with: actionModel)

        // Analytics
        analyticsLogger.setup(stakingTargetsInput: actionModel)

        let stepsManager = CommonStakingSingleActionStepsManager(
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider(),
            action: action
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        actionModel.router = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension StakingSingleActionFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: actionModel, output: actionModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeStakingAlertBuilder(),
            dataBuilder: makeStakingBaseDataBuilder(input: actionModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper(),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension StakingSingleActionFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: actionModel, output: actionModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        SendSummaryStepBuilder.Types(
            settings: .init(
                destinationEditableType: .noEditable,
                amountEditableType: .noEditable,
            )
        )
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: actionModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendFinishStepBuildable

extension StakingSingleActionFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: actionModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
