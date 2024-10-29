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
    let walletModel: WalletModel
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let unstakingModel = builder.makeUnstakingModel(stakingManager: manager, action: action)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: unstakingModel, input: unstakingModel)
        notificationManager.setupManager(with: unstakingModel)

        let actionType = builder.sendFlowActionType(actionType: action.type)

        let io = (input: unstakingModel, output: unstakingModel)

        let amount = sendAmountStepBuilder.makeSendAmountStep(
            io: io,
            actionType: actionType,
            sendFeeLoader: unstakingModel,
            sendQRCodeService: .none,
            sendAmountValidator: builder.makeUnstakingSendAmountValidator(
                stakingManager: manager,
                stakedAmount: action.amount
            ),
            amountModifier: builder.makeStakingAmountModifier(),
            source: .staking
        )

        amount.interactor.externalUpdate(amount: action.amount)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: unstakingModel)
        sendFeeCompactViewModel.bind(input: unstakingModel)

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: io,
            actionType: actionType,
            descriptionBuilder: builder.makeStakingTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            editableType: .editable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: unstakingModel,
            actionType: actionType,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let stepsManager = CommonUnstakingStepsManager(
            amountStep: amount.step,
            summaryStep: summary.step,
            finishStep: finish,
            action: action
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: unstakingModel, output: unstakingModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeStakingBaseDataBuilder(input: unstakingModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        unstakingModel.router = viewModel

        return viewModel
    }
}
