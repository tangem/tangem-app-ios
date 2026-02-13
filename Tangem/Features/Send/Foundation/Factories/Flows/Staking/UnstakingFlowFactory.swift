//
//  UnstakingFlowFactory 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemLocalization
import struct TangemUI.TokenIconInfo

class UnstakingFlowFactory: StakingFlowDependenciesFactory {
    let sourceToken: SendSourceToken
    let manager: any StakingManager
    let action: RestakingModel.Action
    let baseDataBuilderFactory: SendBaseDataBuilderFactory

    var actionType: StakingAction.ActionType { action.displayType }

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var unstakingModel = makeUnstakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager(analyticsLogger: analyticsLogger)

    init(
        sourceToken: SendSourceToken,
        manager: any StakingManager,
        action: RestakingModel.Action,
        baseDataBuilderFactory: SendBaseDataBuilderFactory,
    ) {
        self.sourceToken = sourceToken
        self.manager = manager
        self.action = action
        self.baseDataBuilderFactory = baseDataBuilderFactory
    }
}

// MARK: - Model

extension UnstakingFlowFactory {
    func makeUnstakingModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger
    ) -> UnstakingModel {
        UnstakingModel(
            stakingManager: stakingManager,
            sendSourceToken: sourceToken,
            analyticsLogger: analyticsLogger,
            action: action,
        )
    }
}

// MARK: - Unstaking related

extension UnstakingFlowFactory {
    private var amount: SendAmount {
        let fiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(action.amount, currencyId: $0)
        }
        return .init(type: .typical(crypto: action.amount, fiat: fiat))
    }
}

// MARK: - SendGenericFlowFactory

extension UnstakingFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let isPartialUnstakeAllowed = unstakingModel.isPartialUnstakeAllowed

        let amount = makeSendAmountStep()
        amount.amountUpdater.externalUpdate(amount: action.amount)

        let sendFeeCompactViewModel = SendFeeCompactViewModel()
        let sendFeeFinishViewModel = SendFeeFinishViewModel()

        let summary = makeSendSummaryStep(
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: unstakingModel)
        sendFeeFinishViewModel.bind(input: unstakingModel)

        // Notifications setup
        notificationManager.setup(provider: unstakingModel, input: unstakingModel)
        notificationManager.setupManager(with: unstakingModel)

        // Analytics
        analyticsLogger.setup(stakingTargetsInput: unstakingModel)

        let stepsManager = CommonUnstakingStepsManager(
            amountStep: amount.step,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider(),
            action: action,
            isPartialUnstakeAllowed: isPartialUnstakeAllowed
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        summary.set(router: stepsManager)
        unstakingModel.router = viewModel

        if !isPartialUnstakeAllowed {
            unstakingModel.updateFees()
        }

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension UnstakingFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: unstakingModel, output: unstakingModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeStakingAlertBuilder(),
            dataBuilder: makeStakingBaseDataBuilder(input: unstakingModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper(),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - SendAmountStepBuildable

extension UnstakingFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(
            sourceIO: (input: unstakingModel, output: unstakingModel),
            sourceAmountIO: (input: unstakingModel, output: unstakingModel)
        )
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendAmountValidator: UnstakingAmountValidator(
                tokenItem: tokenItem,
                stakedAmount: action.amount,
                stakingManagerStatePublisher: manager.statePublisher
            ),
            amountModifier: .none,
            notificationService: .none,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension UnstakingFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: unstakingModel, output: unstakingModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        SendSummaryStepBuilder.Types(
            settings: .init(
                destinationEditableType: unstakingModel.isPartialUnstakeAllowed ? .editable : .noEditable,
                amountEditableType: unstakingModel.isPartialUnstakeAllowed ? .editable : .noEditable,
            )
        )
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: unstakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendFinishStepBuildable

extension UnstakingFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: unstakingModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
