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

    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let walletModelBalancesProvider: WalletModelBalancesProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var actionModel = makeStakingSingleActionModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager()

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        manager: any StakingManager,
        action: StakingSingleActionModel.Action,
    ) {
        self.userWalletInfo = userWalletInfo
        self.manager = manager
        self.action = action

        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )
        walletModelDependenciesProvider = walletModel
        walletModelBalancesProvider = walletModel
        transactionDispatcherFactory = TransactionDispatcherFactory(
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
            transactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            analyticsLogger: analyticsLogger,
            action: action,
        )
    }
}

// MARK: - SendGenericFlowFactory

extension StakingSingleActionFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let sendAmountCompactViewModel = SendNewAmountCompactViewModel(
            sourceTokenInput: actionModel,
            sourceTokenAmountInput: actionModel
        )

        let sendNewAmountFinishViewModel = SendNewAmountFinishViewModel(
            sourceTokenInput: actionModel,
            sourceTokenAmountInput: actionModel
        )

        let sendFeeCompactViewModel = SendNewFeeCompactViewModel(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let sendFeeFinishViewModel = SendFeeFinishViewModel(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let summary = makeSendNewSummaryStep(
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: sendNewAmountFinishViewModel,
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
        analyticsLogger.setup(stakingValidatorsInput: actionModel)

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
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper()
        )
    }
}

// MARK: - SendNewSummaryStepBuildable

extension StakingSingleActionFlowFactory: SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder.IO {
        SendNewSummaryStepBuilder.IO(input: actionModel, output: actionModel)
    }

    var newSummaryTypes: SendNewSummaryStepBuilder.Types {
        SendNewSummaryStepBuilder.Types(
            settings: .init(
                destinationEditableType: .noEditable,
                amountEditableType: .noEditable,
            )
        )
    }

    var newSummaryDependencies: SendNewSummaryStepBuilder.Dependencies {
        SendNewSummaryStepBuilder.Dependencies(
            sendFeeProvider: actionModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendNewFinishStepBuildable

extension StakingSingleActionFlowFactory: SendNewFinishStepBuildable {
    var newFinishIO: SendNewFinishStepBuilder.IO {
        SendNewFinishStepBuilder.IO(input: actionModel)
    }

    var newFinishTypes: SendNewFinishStepBuilder.Types {
        SendNewFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var newFinishDependencies: SendNewFinishStepBuilder.Dependencies {
        SendNewFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
