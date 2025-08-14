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
        let analyticsLogger = builder.makeSendAnalyticsLogger(coordinatorSource: coordinatorSource)
        let sendQRCodeService = builder.makeSendQRCodeService()
        let sendModel = builder.makeSendModel(analyticsLogger: analyticsLogger)
        let sendFeeProvider = builder.makeSendFeeProvider(input: sendModel)
        let customFeeService = builder.makeCustomFeeService(input: sendModel)

        let fee = sendFeeStepBuilder.makeFeeSendStep(
            io: (input: sendModel, output: sendModel),
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendFeeProvider: sendFeeProvider,
            customFeeService: customFeeService,
            router: router
        )

        let amount = sendAmountStepBuilder.makeSendAmountStep(
            io: (input: sendModel, output: sendModel),
            actionType: .send,
            sendQRCodeService: sendQRCodeService,
            sendAmountValidator: builder.makeNFTSendAmountValidator(),
            analyticsLogger: analyticsLogger,
            amountModifier: builder.makeNFTSendAmountModifier()
        )

        let destination = sendDestinationStepBuilder.makeSendDestinationStep(
            io: (input: sendModel, output: sendModel),
            sendFeeProvider: sendFeeProvider,
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            router: router
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: sendModel, output: sendModel),
            actionType: .send,
            notificationManager: notificationManager,
            destinationEditableType: .editable,
            amountEditableType: .noEditable, // Amount is fixed for NFTs
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact,
            analyticsLogger: analyticsLogger
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: sendModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            onrampAmountCompactViewModel: .none,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact,
            onrampStatusCompactViewModel: .none
        )

        // We have to set dependencies here after all setups is completed
        sendModel.sendAmountInteractor = amount.interactor
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        analyticsLogger.setup(sendFeeInput: sendModel)

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
            analyticsLogger: analyticsLogger,
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
