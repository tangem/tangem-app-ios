//
//  NFTSendFlowBaseBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NFTSendFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: any WalletModel
    let coordinatorSource: SendCoordinator.Source
    let sendAmountStepBuilder: NFTSendAmountStepBuilder
    let sendDestinationStepBuilder: SendDestinationStepBuilder
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

        let amount = sendAmountStepBuilder.makeSendAmountStep(
            io: (input: sendModel, output: sendModel),
            actionType: .send,
            sendFeeLoader: fee.interactor,
            sendQRCodeService: sendQRCodeService,
            sendAmountValidator: builder.makeNFTSendAmountValidator(),
            amountModifier: builder.makeNFTSendAmountModifier()
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
            descriptionBuilder: builder.makeNFTSendTransactionSummaryDescriptionBuilder(),
            notificationManager: notificationManager,
            destinationEditableType: .editable,
            amountEditableType: .noEditable, // Amount is fixed for NFTs
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact,
            flowKind: .send
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

        let stepsManager = NFTSendStepsManager(
            destinationStep: destination.step,
            feeStep: fee.step,
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
            source: coordinatorSource,
            coordinator: router
        )

        stepsManager.set(output: viewModel)
        fee.step.set(alertPresenter: viewModel)
        sendModel.router = viewModel

        return viewModel
    }
}
