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
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let defaultAddressString: String
    let userWalletInfo: UserWalletInfo
    let manager: any StakingManager

    let tokenFeeProvidersManager: TokenFeeProvidersManager
    let tokenHeaderProvider: SendGenericTokenHeaderProvider
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let transactionDispatcherProvider: any TransactionDispatcherProvider
    let allowanceServiceFactory: AllowanceServiceFactory
    /// Staking doesn't support account-based analytics
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? = nil

    var actionType: StakingAction.ActionType { .stake }

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var stakingModel = makeStakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager(analyticsLogger: analyticsLogger)

    init(
        userWalletInfo: UserWalletInfo,
        manager: any StakingManager,
        walletModel: any WalletModel,
    ) {
        self.userWalletInfo = userWalletInfo
        self.manager = manager

        tokenHeaderProvider = SendTokenHeaderProvider(
            userWalletInfo: userWalletInfo,
            account: walletModel.account,
            flowActionType: .stake
        )
        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )
        defaultAddressString = walletModel.defaultAddressString
        baseDataBuilderFactory = SendBaseDataBuilderFactory(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo
        )
        tokenFeeProvidersManager = TokenFeeProvidersManagerBuilder(walletModel: walletModel).makeTokenFeeProvidersManager()
        walletModelDependenciesProvider = walletModel
        availableBalanceProvider = walletModel.availableBalanceProvider
        fiatAvailableBalanceProvider = walletModel.fiatAvailableBalanceProvider
        transactionDispatcherProvider = WalletModelTransactionDispatcherProvider(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )
        allowanceServiceFactory = AllowanceServiceFactory(
            walletModel: walletModel,
            transactionDispatcherProvider: transactionDispatcherProvider
        )
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
            sendSourceToken: makeSourceToken(),
            feeIncludedCalculator: makeStakingFeeIncludedCalculator(),
            allowanceService: allowanceServiceFactory.makeAllowanceService(),
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
            summaryTitleProvider: makeStakingSummaryTitleProvider()
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
            dataBuilder: makeStakingBaseDataBuilder(input: stakingModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper(),
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

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendAmountValidator: StakingAmountValidator(
                tokenItem: tokenItem,
                validator: walletModelDependenciesProvider.transactionValidator,
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
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
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
