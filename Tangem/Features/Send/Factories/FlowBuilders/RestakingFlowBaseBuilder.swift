//
//  RestakingFlowBaseBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct RestakingFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: any WalletModel
    let source: SendCoordinator.Source
    let stakingValidatorsStepBuilder: StakingValidatorsStepBuilder
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: some StakingManager, action: RestakingModel.Action? = nil, router: SendRoutable) -> SendViewModel {
        // no pending action == full balance staking
        let action = action ?? builder.makeStakeAction()
        let actionType = builder.sendFlowActionType(actionType: action.displayType)
        let analyticsLogger = builder.makeStakingSendAnalyticsLogger(actionType: actionType)

        let restakingModel = builder.makeRestakingModel(stakingManager: manager, analyticsLogger: analyticsLogger, action: action)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: restakingModel, input: restakingModel)
        notificationManager.setupManager(with: restakingModel)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: restakingModel)
        sendFeeCompactViewModel.bind(input: restakingModel)

        let validators = stakingValidatorsStepBuilder.makeRestakingValidatorsStep(
            io: (input: restakingModel, output: restakingModel),
            manager: manager,
            currentValidator: action.validatorInfo,
            actionType: actionType,
            sendFeeProvider: restakingModel,
            analyticsLogger: analyticsLogger
        )

        let validatorsCompact = stakingValidatorsStepBuilder.makeStakingValidatorsCompactViewModel(
            io: (input: restakingModel, output: restakingModel)
        )

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(input: restakingModel)

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: restakingModel, output: restakingModel),
            actionType: actionType,
            descriptionBuilder: builder.makeStakingTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            destinationEditableType: .noEditable,
            amountEditableType: .noEditable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: validatorsCompact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            analyticsLogger: analyticsLogger
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: restakingModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: .none,
            stakingValidatorsCompactViewModel: validatorsCompact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: .none
        )

        let stepsManager = CommonRestakingStepsManager(
            validatorsStep: validators,
            summaryStep: summary.step,
            finishStep: finish,
            actionType: actionType
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: restakingModel, output: restakingModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeStakingBaseDataBuilder(input: restakingModel),
            analyticsLogger: analyticsLogger,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            source: source,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        restakingModel.router = viewModel

        return viewModel
    }
}
