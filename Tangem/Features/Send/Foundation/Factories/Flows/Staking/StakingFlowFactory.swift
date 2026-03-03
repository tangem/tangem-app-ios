//
//  StakingFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import struct TangemUI.TokenIconInfo

class StakingFlowFactory: StakingFlowDependenciesFactory {
    let stakingableToken: SendStakingableToken
    let manager: any StakingManager
    let walletModelDependenciesProvider: WalletModelDependenciesProvider

    var actionType: StakingAction.ActionType { .stake }

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var stakingModel = makeStakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager(analyticsLogger: analyticsLogger)

    init(
        stakingableToken: SendStakingableToken,
        manager: any StakingManager,
        walletModelDependenciesProvider: WalletModelDependenciesProvider
    ) {
        self.stakingableToken = stakingableToken
        self.manager = manager
        self.walletModelDependenciesProvider = walletModelDependenciesProvider
    }
}

// MARK: - Management Model

extension StakingFlowFactory {
    func makeStakingModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger
    ) -> StakingModel {
        StakingModel(
            stakingManager: stakingManager,
            sendSourceToken: stakingableToken,
            feeIncludedCalculator: makeStakingFeeIncludedCalculator(),
            analyticsLogger: analyticsLogger,
            accountInitializationService: walletModelDependenciesProvider.accountInitializationService,
            minimalBalanceProvider: walletModelDependenciesProvider.minimalBalanceProvider,
        )
    }
}

// MARK: - SendGenericFlowFactory

extension StakingFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let amount = makeSendAmountStep()
        let targets = makeStakingTargetsStep()

        let sendFeeCompactViewModel = SendFeeCompactViewModel()
        let sendFeeFinishViewModel = SendFeeFinishViewModel()

        let summary = makeSendSummaryStep(
            sendAmountCompactViewModel: amount.compact,
            stakingTargetsCompactViewModel: targets.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            stakingTargetsCompactViewModel: targets.compact,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: stakingModel)
        sendFeeFinishViewModel.bind(input: stakingModel)

        // Notifications setup
        notificationManager.setup(provider: stakingModel, input: stakingModel)
        notificationManager.setupManager(with: stakingModel)

        // Analytics
        analyticsLogger.setup(stakingTargetsInput: stakingModel)

        let stepsManager = CommonStakingStepsManager(
            provider: stakingModel,
            amountStep: amount.step,
            targetsStep: targets.step,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider(),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo)
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)
        summary.set(router: stepsManager)

        stakingModel.router = viewModel
        stakingModel.amountExternalUpdater = amount.amountUpdater

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension StakingFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: stakingModel, output: stakingModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeStakingAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: stakingModel,
                sourceTokenInput: stakingModel
            ),
            approveViewModelInputDataBuilder: CommonStakingApproveViewModelInputDataBuilder(
                sourceToken: stakingableToken,
                approveDataInput: stakingModel,
                tokenFeeManagerProviding: stakingModel
            ),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: stakingModel
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - SendAmountStepBuildable

extension StakingFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(
            sourceIO: (input: stakingModel, output: stakingModel),
            sourceAmountIO: (input: stakingModel, output: stakingModel)
        )
    }

    var amountTypes: SendAmountStepBuilder.Types {
        .init(
            initialSourceToken: stakingableToken,
            flowActionType: actionType.sendFlowActionType
        )
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendAmountValidator: StakingAmountValidator(
                tokenItem: tokenItem,
                validator: stakingableToken.transactionValidator,
                stakingManagerStatePublisher: manager.statePublisher
            ),
            amountModifier: StakingAmountModifier(tokenItem: tokenItem, actionType: actionType.sendFlowActionType),
            notificationService: .none,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - StakingValidatorsStepBuildable

extension StakingFlowFactory: StakingTargetsStepBuildable {
    var stakingTargetsIO: StakingTargetsStepBuilder.IO {
        StakingTargetsStepBuilder.IO(input: stakingModel, output: stakingModel)
    }

    var stakingTargetsTypes: StakingTargetsStepBuilder.Types {
        StakingTargetsStepBuilder.Types(actionType: actionType.sendFlowActionType, currentTarget: stakingModel.target)
    }

    var stakingTargetsDependencies: StakingTargetsStepBuilder.Dependencies {
        StakingTargetsStepBuilder.Dependencies(
            manager: manager,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension StakingFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: stakingModel, output: stakingModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        SendSummaryStepBuilder.Types(
            settings: .init(destinationEditableType: .editable, amountEditableType: .editable)
        )
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: stakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            sendWithSwapDescriptionBuilder: makeSendWithSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendFinishStepBuildable

extension StakingFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: stakingModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
