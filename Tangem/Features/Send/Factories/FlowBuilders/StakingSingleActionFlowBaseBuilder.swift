//
//  StakingSingleActionFlowBaseBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct StakingSingleActionFlowBaseBuilder {
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
        let analyticsLogger = builder.makeStakingSendAnalyticsLogger(actionType: actionType)
        let actionModel = builder.makeStakingSingleActionModel(
            stakingManager: manager,
            analyticsLogger: analyticsLogger,
            action: action
        )
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: actionModel, input: actionModel)
        notificationManager.setupManager(with: actionModel)

        analyticsLogger.setup(stakingValidatorsInput: actionModel)

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(input: actionModel)
        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: actionModel)
        sendFeeCompactViewModel.bind(input: actionModel)

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: actionModel, output: actionModel),
            actionType: actionType,
            descriptionBuilder: builder.makeStakingTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            destinationEditableType: .noEditable,
            amountEditableType: .noEditable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            analyticsLogger: analyticsLogger
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: actionModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: .none,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: .none
        )

        let stepsManager = CommonStakingSingleActionStepsManager(
            summaryStep: summary.step,
            finishStep: finish,
            action: action
        )

        let interactor = CommonSendBaseInteractor(input: actionModel, output: actionModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeStakingBaseDataBuilder(input: actionModel),
            analyticsLogger: analyticsLogger,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            source: source,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        actionModel.router = viewModel

        return viewModel
    }
}
