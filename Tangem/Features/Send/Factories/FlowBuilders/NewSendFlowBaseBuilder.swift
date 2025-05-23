//
//  NewSendFlowBaseBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NewSendFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: any WalletModel
    let source: SendCoordinator.Source
    let sendAmountStepBuilder: SendNewAmountStepBuilder
    let sendDestinationStepBuilder: SendNewDestinationStepBuilder
    let sendFeeStepBuilder: SendFeeStepBuilder
    let sendSummaryStepBuilder: SendSummaryStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let notificationManager = builder.makeSendNotificationManager()
        let sendQRCodeService = builder.makeSendQRCodeService()
        let sendModel = builder.makeSendModel()
        let sendFinishAnalyticsLogger = builder.makeSendFinishAnalyticsLogger(sendFeeInput: sendModel)

        let fee = sendFeeStepBuilder.makeFeeSendStep(
            io: (input: sendModel, output: sendModel),
            notificationManager: notificationManager,
            router: router
        )

        let amount = sendAmountStepBuilder.makeSendNewAmountStep(
            io: (input: sendModel, output: sendModel),
            actionType: .send,
            sendFeeLoader: fee.interactor,
            sendAmountValidator: builder.makeSendAmountValidator(),
            amountModifier: .none,
            source: .send
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
            descriptionBuilder: builder.makeSendTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            destinationEditableType: .editable,
            amountEditableType: .editable,
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: sendModel,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            onrampAmountCompactViewModel: .none,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact,
            onrampStatusCompactViewModel: .none
        )

        // We have to set dependencies here after all setups is completed
        sendModel.sendAmountInteractor = amount.interactor
        sendModel.sendFeeInteractor = fee.interactor
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            sendFeeInteractor: fee.interactor
        )

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        // We have to do it after sendModel fully setup
        fee.compact.bind(input: sendModel)

        let stepsManager = CommonNewSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary.step,
            finishStep: finish
        )

        summary.step.set(router: stepsManager)
        destination.step.set(stepRouter: stepsManager)

        let interactor = CommonSendBaseInteractor(input: sendModel, output: sendModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: builder.makeSendBaseDataBuilder(input: sendModel),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            source: source,
            coordinator: router
        )

        stepsManager.set(output: viewModel)
        fee.step.set(alertPresenter: viewModel)
        sendModel.router = viewModel

        return viewModel
    }
}
