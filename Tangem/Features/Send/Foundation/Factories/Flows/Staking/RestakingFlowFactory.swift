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
    lazy var restakingModel = makeRestakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager(analyticsLogger: analyticsLogger)

    init(
        userWalletInfo: UserWalletInfo,
        manager: any StakingManager,
        action: RestakingModel.Action,
        walletModel: any WalletModel,
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

extension RestakingFlowFactory {
    func makeRestakingModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger
    ) -> RestakingModel {
        RestakingModel(
            stakingManager: stakingManager,
            action: action,
            sendSourceToken: makeSourceToken(),
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
        let sendAmountCompactViewModel = SendAmountCompactViewModel(
            sourceTokenInput: restakingModel,
            sourceTokenAmountInput: restakingModel,
        )

        let sendAmountFinishViewModel = SendAmountFinishViewModel(
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
            dataBuilder: makeStakingBaseDataBuilder(input: restakingModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper(),
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
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
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
