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

    func makeSendViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let restakingModel = builder.makeRestakingModel(stakingManager: manager, action: action)
        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: restakingModel, input: restakingModel)
        notificationManager.setupManager(with: restakingModel)

        let sendFeeCompactViewModel = sendFeeStepBuilder.makeSendFeeCompactViewModel(input: restakingModel)
        sendFeeCompactViewModel.bind(input: restakingModel)

        let actionType = builder.sendFlowActionType(actionType: action.type)
        let sendFinishAnalyticsLogger = builder.makeStakingFinishAnalyticsLogger(
            actionType: actionType,
            stakingValidatorsInput: restakingModel
        )

        let validators = stakingValidatorsStepBuilder.makeRestakingValidatorsStep(
            io: (input: restakingModel, output: restakingModel),
            manager: manager,
            currentValidator: action.validatorInfo,
            actionType: actionType,
            sendFeeLoader: restakingModel
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
            editableType: .noEditable,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: validatorsCompact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: restakingModel,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
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
