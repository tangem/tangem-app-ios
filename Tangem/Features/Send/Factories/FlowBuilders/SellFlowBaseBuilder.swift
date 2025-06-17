//
//  SellFlowBaseBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SellFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: any WalletModel
    let coordinatorSource: SendCoordinator.Source
    let sendDestinationStepBuilder: SendDestinationStepBuilder
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(sellParameters: PredefinedSellParameters, router: SendRoutable) -> SendViewModel {
        let flowKind = SendModel.PredefinedValues.FlowKind.sell

        let notificationManager = builder.makeSendNotificationManager()
        let sendModel = builder.makeSendModel(predefinedSellParameters: sellParameters)
        let sendFinishAnalyticsLogger = builder.makeSendFinishAnalyticsLogger(sendFeeInput: sendModel)

        let sendDestinationCompactViewModel = sendDestinationStepBuilder.makeSendDestinationCompactViewModel(
            input: sendModel
        )

        let sendAmountCompactViewModel = sendAmountStepBuilder.makeSendAmountCompactViewModel(
            input: sendModel
        )

        let fee = sendFeeStepBuilder.makeFeeSendStep(
            io: (input: sendModel, output: sendModel),
            notificationManager: notificationManager,
            router: router
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: sendModel, output: sendModel),
            actionType: .send,
            descriptionBuilder: builder.makeSendTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            destinationEditableType: .disable,
            amountEditableType: .disable,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact,
            flowKind: flowKind
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: sendModel,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: .none,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact,
            onrampStatusCompactViewModel: .none
        )

        // We have to set dependencies here after all setups is completed
        sendModel.sendFeeInteractor = fee.interactor
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            sendFeeInteractor: fee.interactor
        )

        // Update the fees in case we in the sell flow
        fee.interactor.updateFees()

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        // We have to do it after sendModel fully setup
        fee.compact.bind(input: sendModel)

        let stepsManager = CommonSellStepsManager(
            feeStep: fee.step,
            summaryStep: summary.step,
            finishStep: finish
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: sendModel, output: sendModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: builder.makeSendBaseDataBuilder(input: sendModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            source: coordinatorSource,
            coordinator: router
        )
        stepsManager.set(output: viewModel)

        fee.step.set(alertPresenter: viewModel)
        sendModel.router = viewModel

        return viewModel
    }
}
