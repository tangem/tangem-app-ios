//
//  RestakingFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import struct TangemUI.TokenIconInfo

class RestakingFlowFactory: StakingFlowDependenciesFactory {
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
    lazy var restakingModel = makeRestakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager()

    init(
        userWalletInfo: UserWalletInfo,
        manager: any StakingManager,
        action: RestakingModel.Action,
        walletModel: any WalletModel,
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

extension RestakingFlowFactory {
    func makeRestakingModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger
    ) -> RestakingModel {
        RestakingModel(
            stakingManager: stakingManager,
            action: action,
            sendSourceToken: makeSourceToken(),
            transactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            sendAmountValidator: RestakingAmountValidator(
                tokenItem: tokenItem,
                action: actionType,
                stakingManagerStatePublisher: manager.statePublisher
            ),
            analyticsLogger: analyticsLogger,
        )
    }
}

// MARK: - SendGenericFlowFactory

extension RestakingFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let sendAmountCompactViewModel = SendNewAmountCompactViewModel(
            sourceTokenInput: restakingModel,
            sourceTokenAmountInput: restakingModel,
        )

        let sendAmountFinishViewModel = SendNewAmountFinishViewModel(
            sourceTokenInput: restakingModel,
            sourceTokenAmountInput: restakingModel,
        )

        let sendFeeCompactViewModel = SendNewFeeCompactViewModel(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let sendFeeFinishViewModel = SendFeeFinishViewModel(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let validators = makeStakingValidatorsStep()

        let summary = makeSendNewSummaryStep(
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: restakingModel)
        sendFeeFinishViewModel.bind(input: restakingModel)

        // Notifications setup
        notificationManager.setup(provider: restakingModel, input: restakingModel)
        notificationManager.setupManager(with: restakingModel)

        // Analytics
        analyticsLogger.setup(stakingValidatorsInput: restakingModel)

        let stepsManager = CommonRestakingStepsManager(
            validatorsStep: validators.step,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider(),
            actionType: sendFlowActionType()
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        summary.set(router: stepsManager)
        restakingModel.router = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension RestakingFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: restakingModel, output: restakingModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeStakingAlertBuilder(),
            dataBuilder: makeStakingBaseDataBuilder(input: restakingModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper()
        )
    }
}

// MARK: - StakingValidatorsStepBuildable

extension RestakingFlowFactory: StakingValidatorsStepBuildable {
    var stakingValidatorsIO: StakingValidatorsStepBuilder.IO {
        StakingValidatorsStepBuilder.IO(input: restakingModel, output: restakingModel)
    }

    var stakingValidatorsTypes: StakingValidatorsStepBuilder.Types {
        StakingValidatorsStepBuilder.Types(actionType: sendFlowActionType(), currentValidator: restakingModel.validator)
    }

    var stakingValidatorsDependencies: StakingValidatorsStepBuilder.Dependencies {
        StakingValidatorsStepBuilder.Dependencies(
            manager: manager,
            sendFeeProvider: restakingModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendNewSummaryStepBuildable

extension RestakingFlowFactory: SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder.IO {
        SendNewSummaryStepBuilder.IO(input: restakingModel, output: restakingModel)
    }

    var newSummaryTypes: SendNewSummaryStepBuilder.Types {
        SendNewSummaryStepBuilder.Types(
            settings: .init(
                destinationEditableType: .editable,
                amountEditableType: .noEditable
            )
        )
    }

    var newSummaryDependencies: SendNewSummaryStepBuilder.Dependencies {
        SendNewSummaryStepBuilder.Dependencies(
            sendFeeProvider: restakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendNewFinishStepBuildable

extension RestakingFlowFactory: SendNewFinishStepBuildable {
    var newFinishIO: SendNewFinishStepBuilder.IO {
        SendNewFinishStepBuilder.IO(input: restakingModel)
    }

    var newFinishTypes: SendNewFinishStepBuilder.Types {
        SendNewFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var newFinishDependencies: SendNewFinishStepBuilder.Dependencies {
        SendNewFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
