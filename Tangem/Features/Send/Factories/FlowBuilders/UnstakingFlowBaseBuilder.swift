//
//  UnstakingFlowBaseBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct UnstakingFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: any WalletModel
    let source: SendCoordinator.Source
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let actionType = builder.sendFlowActionType(actionType: action.displayType)
        let notificationManager = builder.makeStakingNotificationManager()
        let analyticsLogger = builder.makeStakingSendAnalyticsLogger(actionType: actionType)
        let unstakingModel = builder.makeUnstakingModel(stakingManager: manager, analyticsLogger: analyticsLogger, action: action)

        notificationManager.setup(provider: unstakingModel, input: unstakingModel)
        notificationManager.setupManager(with: unstakingModel)
        analyticsLogger.setup(stakingValidatorsInput: unstakingModel)

        let io = (input: unstakingModel, output: unstakingModel)

        let amount = sendAmountStepBuilder.makeSendAmountStep(
            io: io,
            actionType: actionType,
            sendFeeProvider: unstakingModel,
            sendQRCodeService: .none,
            sendAmountValidator: builder.makeUnstakingSendAmountValidator(
                stakingManager: manager,
                stakedAmount: action.amount
            ),
            amountModifier: builder.makeStakingAmountModifier(actionType: actionType),
            analyticsLogger: analyticsLogger
        )

        amount.interactor.externalUpdate(amount: action.amount)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: unstakingModel)
        sendFeeCompactViewModel.bind(input: unstakingModel)

        let isPartialUnstakeAllowed = unstakingModel.isPartialUnstakeAllowed

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: io,
            actionType: actionType,
            notificationManager: notificationManager,
            destinationEditableType: isPartialUnstakeAllowed ? .editable : .noEditable,
            amountEditableType: isPartialUnstakeAllowed ? .editable : .noEditable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            analyticsLogger: analyticsLogger
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: unstakingModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: amount.compact,
            onrampAmountCompactViewModel: .none,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: .none
        )

        let stepsManager = CommonUnstakingStepsManager(
            amountStep: amount.step,
            summaryStep: summary.step,
            finishStep: finish,
            action: action,
            isPartialUnstakeAllowed: isPartialUnstakeAllowed
        )

        summary.step.set(router: stepsManager)

        if !isPartialUnstakeAllowed {
            unstakingModel.updateFees()
        }

        let interactor = CommonSendBaseInteractor(input: unstakingModel, output: unstakingModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeStakingBaseDataBuilder(input: unstakingModel),
            analyticsLogger: analyticsLogger,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            source: source,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        unstakingModel.router = viewModel

        return viewModel
    }
}
