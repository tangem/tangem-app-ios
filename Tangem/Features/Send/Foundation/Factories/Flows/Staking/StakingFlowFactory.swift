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

    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let walletModelBalancesProvider: WalletModelBalancesProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory

    var actionType: StakingAction.ActionType { .stake }

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var stakingModel = makeStakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager()

    init(
        userWalletInfo: UserWalletInfo,
        manager: any StakingManager,
        walletModel: any WalletModel,
    ) {
        self.userWalletInfo = userWalletInfo
        self.manager = manager

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
        walletModelDependenciesProvider = walletModel
        walletModelBalancesProvider = walletModel
        transactionDispatcherFactory = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletInfo.signer
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
            stakingTransactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            transactionDispatcher: transactionDispatcherFactory.makeSendDispatcher(),
            allowanceService: CommonAllowanceService(
                tokenItem: tokenItem,
                allowanceChecker: .init(
                    blockchain: tokenItem.blockchain,
                    amountType: tokenItem.amountType,
                    walletAddress: defaultAddressString,
                    ethereumNetworkProvider: walletModelDependenciesProvider.ethereumNetworkProvider,
                    ethereumTransactionDataBuilder: walletModelDependenciesProvider.ethereumTransactionDataBuilder
                )
            ),
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
        let validators = makeStakingValidatorsStep()

        let sendFeeCompactViewModel = SendNewFeeCompactViewModel(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let sendFeeFinishViewModel = SendFeeFinishViewModel(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let summary = makeSendNewSummaryStep(
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            stakingValidatorsCompactViewModel: validators.compact,
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
        analyticsLogger.setup(stakingValidatorsInput: stakingModel)

        let stepsManager = CommonStakingStepsManager(
            provider: stakingModel,
            amountStep: amount.step,
            validatorsStep: validators.step,
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
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper()
        )
    }
}

// MARK: - SendNewAmountStepBuildable

extension StakingFlowFactory: SendNewAmountStepBuildable {
    var newAmountIO: SendNewAmountStepBuilder.IO {
        SendNewAmountStepBuilder.IO(
            sourceIO: (input: stakingModel, output: stakingModel),
            sourceAmountIO: (input: stakingModel, output: stakingModel)
        )
    }

    var newAmountDependencies: SendNewAmountStepBuilder.Dependencies {
        SendNewAmountStepBuilder.Dependencies(
            sendAmountValidator: StakingAmountValidator(
                tokenItem: tokenItem,
                validator: walletModelDependenciesProvider.transactionValidator,
                stakingManagerStatePublisher: manager.statePublisher
            ),
            amountModifier: StakingAmountModifier(tokenItem: tokenItem, actionType: sendFlowActionType()),
            notificationService: .none,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - StakingValidatorsStepBuildable

extension StakingFlowFactory: StakingValidatorsStepBuildable {
    var stakingValidatorsIO: StakingValidatorsStepBuilder.IO {
        StakingValidatorsStepBuilder.IO(input: stakingModel, output: stakingModel)
    }

    var stakingValidatorsTypes: StakingValidatorsStepBuilder.Types {
        StakingValidatorsStepBuilder.Types(actionType: sendFlowActionType(), currentValidator: stakingModel.validator)
    }

    var stakingValidatorsDependencies: StakingValidatorsStepBuilder.Dependencies {
        StakingValidatorsStepBuilder.Dependencies(
            manager: manager,
            sendFeeProvider: stakingModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendNewSummaryStepBuildable

extension StakingFlowFactory: SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder.IO {
        SendNewSummaryStepBuilder.IO(input: stakingModel, output: stakingModel)
    }

    var newSummaryTypes: SendNewSummaryStepBuilder.Types {
        SendNewSummaryStepBuilder.Types(
            settings: .init(destinationEditableType: .editable, amountEditableType: .editable)
        )
    }

    var newSummaryDependencies: SendNewSummaryStepBuilder.Dependencies {
        SendNewSummaryStepBuilder.Dependencies(
            sendFeeProvider: stakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendNewFinishStepBuildable

extension StakingFlowFactory: SendNewFinishStepBuildable {
    var newFinishIO: SendNewFinishStepBuilder.IO {
        SendNewFinishStepBuilder.IO(input: stakingModel)
    }

    var newFinishTypes: SendNewFinishStepBuilder.Types {
        SendNewFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var newFinishDependencies: SendNewFinishStepBuilder.Dependencies {
        SendNewFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
