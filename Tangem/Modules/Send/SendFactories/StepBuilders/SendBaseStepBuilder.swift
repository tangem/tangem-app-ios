//
//  SendBaseStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendBaseStepBuilder {
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendDestinationStepBuilder: SendDestinationStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendModulesStepsBuilder

    func makeSendViewModel(sendType: SendType, router: SendRoutable) -> SendViewModel {
        let notificationManager = builder.makeSendNotificationManager()
        let addressTextViewHeightModel: AddressTextViewHeightModel = .init()
        let sendTransactionSender = builder.makeSendTransactionSender()

        let fee = sendFeeStepBuilder.makeFeeSendStep(notificationManager: notificationManager, router: router)
        let amount = sendAmountStepBuilder.makeSendAmountStep(sendFeeInteractor: fee.interactor)
        let destination = sendDestinationStepBuilder.makeSendDestinationStep(
            sendAmountInteractor: amount.interactor,
            sendFeeInteractor: fee.interactor,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            sendTransactionSender: sendTransactionSender,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: sendType
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            sendFeeInteractor: fee.interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: sendType
        )

        let informationRelevanceService = builder.makeInformationRelevanceService(sendFeeInteractor: fee.interactor)

        let sendModel = builder.makeSendModel(
            sendAmountInteractor: amount.interactor,
            sendFeeInteractor: fee.interactor,
            informationRelevanceService: informationRelevanceService,
            sendTransactionSender: sendTransactionSender,
            type: sendType,
            router: router
        )

        notificationManager.setupManager(with: sendModel)
        notificationManager.setup(input: sendModel)

        destination.interactor.setup(input: sendModel, output: sendModel)
        amount.interactor.setup(input: sendModel, output: sendModel)
        fee.interactor.setup(input: sendModel, output: sendModel)

        summary.interactor.setup(input: sendModel, output: sendModel)
        summary.step.setup(sendDestinationInput: sendModel)
        summary.step.setup(sendAmountInput: sendModel)
        summary.step.setup(sendFeeInteractor: fee.interactor)

        finish.interactor.setup(input: sendModel, output: sendModel)
        finish.step.setup(sendDestinationInput: sendModel)
        finish.step.setup(sendAmountInput: sendModel)
        finish.step.setup(sendFeeInteractor: fee.interactor)
        finish.step.setup(sendFinishInput: sendModel)

        let stepsManager = CommonSendStepsManager(
            destinationStep: destination.step,
            amountStep: amount.step,
            feeStep: fee.step,
            summaryStep: summary.step,
            finishStep: finish.step
        )

        let interactor = CommonSendBaseInteractor(input: sendModel, output: sendModel, sendDestinationInput: sendModel)
        let viewModel = SendViewModel(interactor: interactor, stepsManager: stepsManager, router: router)

        stepsManager.setup(input: viewModel, output: viewModel)
        sendModel.delegate = viewModel
        return viewModel
    }
}
