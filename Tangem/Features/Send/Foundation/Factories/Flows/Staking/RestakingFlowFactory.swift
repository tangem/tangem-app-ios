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
    let stakingableToken: SendStakingableToken
    let manager: any StakingManager
    let action: RestakingModel.Action

    var actionType: StakingAction.ActionType { action.displayType }

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var restakingModel = makeRestakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager(analyticsLogger: analyticsLogger)

    init(
        stakingableToken: SendStakingableToken,
        manager: any StakingManager,
        action: RestakingModel.Action
    ) {
        self.stakingableToken = stakingableToken
        self.manager = manager
        self.action = action
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
            sendSourceToken: stakingableToken,
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
    func make(router: any SendRoutable, coordinatorStateProvider: SendCoordinatorStateProvider) -> SendViewModel {
        let sendAmountCompactViewModel = SendAmountCompactViewModel(
            initialSourceToken: stakingableToken,
            actionType: actionType.sendFlowActionType,
            sourceTokenInput: restakingModel,
            sourceTokenAmountInput: restakingModel,
        )

        let sendAmountFinishViewModel = SendAmountFinishViewModel(
            flowActionType: actionType.sendFlowActionType,
            sourceTokenInput: restakingModel,
            sourceTokenAmountInput: restakingModel,
        )

        let sendFeeCompactViewModel = SendFeeCompactViewModel()
        let sendFeeFinishViewModel = SendFeeFinishViewModel()

        let targets = makeStakingTargetsStep()

        let summary = makeSendSummaryStep(
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingTargetsCompactViewModel: targets.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            stakingTargetsCompactViewModel: targets.compact,
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
        analyticsLogger.setup(stakingTargetsInput: restakingModel)

        let stepsManager = CommonRestakingStepsManager(
            targetsStep: targets.step,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider(),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo),
            actionType: actionType.sendFlowActionType
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
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: restakingModel,
                sourceTokenInput: restakingModel
            ),
            approveViewModelInputDataBuilder: EmptyApproveViewModelInputDataBuilder(),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: restakingModel
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - StakingValidatorsStepBuildable

extension RestakingFlowFactory: StakingTargetsStepBuildable {
    var stakingTargetsIO: StakingTargetsStepBuilder.IO {
        StakingTargetsStepBuilder.IO(input: restakingModel, output: restakingModel)
    }

    var stakingTargetsTypes: StakingTargetsStepBuilder.Types {
        StakingTargetsStepBuilder.Types(actionType: actionType.sendFlowActionType, currentTarget: restakingModel.target)
    }

    var stakingTargetsDependencies: StakingTargetsStepBuilder.Dependencies {
        StakingTargetsStepBuilder.Dependencies(
            manager: manager,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension RestakingFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: restakingModel, output: restakingModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        SendSummaryStepBuilder.Types(
            settings: .init(
                destinationEditableType: .editable,
                amountEditableType: .noEditable
            )
        )
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: restakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            sendWithSwapDescriptionBuilder: makeSendWithSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendFinishStepBuildable

extension RestakingFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: restakingModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
