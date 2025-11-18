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
            transactionCreator: walletModelDependenciesProvider.transactionCreator,
            transactionValidator: walletModelDependenciesProvider.transactionValidator,
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
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            tokenIconInfo: tokenIconInfo
        )
    }
}

// MARK: - SendGenericFlowFactory

extension StakingFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let sendFeeCompactViewModel = SendFeeCompactViewModel(
            input: stakingModel,
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let amount = makeSendAmountStep()

        stakingModel.onAmountUpdate = { [interactor = amount.interactor] newAmount in
            interactor.externalUpdate(amount: newAmount)
        }

        let validators = makeStakingValidatorsStep()

        let summary = makeSendSummaryStep(
            stakingValidatorsCompactViewModel: validators.compact,
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: stakingModel)

        // Notifications setup
        notificationManager.setup(provider: stakingModel, input: stakingModel)
        notificationManager.setupManager(with: stakingModel)

        // Analytics
        analyticsLogger.setup(stakingValidatorsInput: stakingModel)

        let stepsManager = CommonStakingStepsManager(
            provider: stakingModel,
            amountStep: amount.step,
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider()
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        summary.step.set(router: stepsManager)
        stakingModel.router = viewModel

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

// MARK: - SendAmountStepBuildable

extension StakingFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(input: stakingModel, output: stakingModel)
    }

    var amountTypes: SendAmountStepBuilder.Types {
        SendAmountStepBuilder.Types(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            maxAmount: maxAmount(),
            settings: makeSendAmountViewModelSettings()
        )
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendFeeProvider: stakingModel,
            sendQRCodeService: .none,
            sendAmountValidator: StakingAmountValidator(
                tokenItem: tokenItem,
                validator: walletModelDependenciesProvider.transactionValidator,
                stakingManagerStatePublisher: manager.statePublisher
            ),
            amountModifier: StakingAmountModifier(tokenItem: tokenItem, actionType: sendFlowActionType()),
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

// MARK: - SendSummaryStepBuildable

extension StakingFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: stakingModel, output: stakingModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        SendSummaryStepBuilder.Types(
            settings: .init(
                tokenItem: tokenItem,
                destinationEditableType: .editable,
                amountEditableType: .editable,
                actionType: sendFlowActionType()
            )
        )
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: stakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
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
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
