//
//  SendFlowBaseBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let sendAmountStepBuilder: SendAmountStepBuilder
    let sendDestinationStepBuilder: SendDestinationStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let notificationManager = builder.makeSendNotificationManager()
        let sendTransactionDispatcher = builder.makeSendTransactionDispatcher()
        let sendQRCodeService = builder.makeSendQRCodeService()

        let sendModel = builder.makeSendModel(sendTransactionDispatcher: sendTransactionDispatcher)

        let fee = sendFeeStepBuilder.makeFeeSendStep(
            io: (input: sendModel, output: sendModel),
            notificationManager: notificationManager,
            router: router
        )

        let amount = sendAmountStepBuilder.makeSendAmountStep(
            io: (input: sendModel, output: sendModel),
            sendFeeLoader: fee.interactor,
            sendQRCodeService: sendQRCodeService
        )

        let destination = sendDestinationStepBuilder.makeSendDestinationStep(
            io: (input: sendModel, output: sendModel),
            sendFeeInteractor: fee.interactor,
            sendQRCodeService: sendQRCodeService,
            router: router
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: sendModel, output: sendModel),
            actionType: .send,
            sendTransactionDispatcher: sendTransactionDispatcher,
            notificationManager: notificationManager,
            editableType: .editable,
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: sendModel,
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact
        )

        // We have to set dependicies here after all setups is completed
        sendModel.sendAmountInteractor = amount.interactor
        sendModel.sendFeeInteractor = fee.interactor
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            sendFeeInteractor: fee.interactor
        )

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        // We have to do it after sendModel fully setup
        fee.compact.bind(input: sendModel)

        let stepsManager = CommonSendStepsManager(
            destinationStep: destination.step,
            amountStep: amount.step,
            feeStep: fee.step,
            summaryStep: summary.step,
            finishStep: finish
        )

        summary.step.set(router: stepsManager)
        destination.step.set(stepRouter: stepsManager)

        let interactor = CommonSendBaseInteractor(input: sendModel, output: sendModel, walletModel: walletModel, emailDataProvider: userWalletModel)
        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            feeTokenItem: walletModel.feeTokenItem,
            coordinator: router
        )

        stepsManager.set(output: viewModel)
        fee.step.set(alertPresenter: viewModel)
        sendModel.router = viewModel

        return viewModel
    }
}
