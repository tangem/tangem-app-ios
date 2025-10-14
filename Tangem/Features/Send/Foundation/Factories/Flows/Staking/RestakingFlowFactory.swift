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
            transactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            transactionValidator: walletModelDependenciesProvider.transactionValidator,
            sendAmountValidator: RestakingAmountValidator(
                tokenItem: tokenItem,
                action: actionType,
                stakingManagerStatePublisher: manager.statePublisher
            ),
            analyticsLogger: analyticsLogger,
            action: action,
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem
        )
    }
}

// MARK: - SendGenericFlowFactory

extension RestakingFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let sendFeeCompactViewModel = SendFeeCompactViewModel(
            input: restakingModel,
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let sendAmountCompactViewModel = SendAmountCompactViewModel(
            conventViewModel: SendAmountCompactContentViewModel(
                input: restakingModel,
                tokenIconInfo: tokenIconInfo,
                tokenItem: tokenItem
            )
        )

        let validators = makeStakingValidatorsStep()

        let summary = makeSendSummaryStep(
            stakingValidatorsCompactViewModel: validators.compact,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: restakingModel)

        // Notifications setup
        notificationManager.setup(provider: restakingModel, input: restakingModel)
        notificationManager.setupManager(with: restakingModel)

        // Analytics
        analyticsLogger.setup(stakingValidatorsInput: restakingModel)

        let stepsManager = CommonRestakingStepsManager(
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider(),
            actionType: sendFlowActionType()
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        summary.step.set(router: stepsManager)
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

// MARK: - SendSummaryStepBuildable

extension RestakingFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: restakingModel, output: restakingModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        SendSummaryStepBuilder.Types(
            settings: .init(
                tokenItem: tokenItem,
                destinationEditableType: .editable,
                amountEditableType: .noEditable,
                actionType: sendFlowActionType()
            )
        )
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: restakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
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
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
