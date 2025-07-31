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
    let coordinatorSource: SendCoordinator.Source
    let sendAmountStepBuilder: SendNewAmountStepBuilder
    let sendDestinationStepBuilder: SendNewDestinationStepBuilder
    let sendFeeStepBuilder: SendNewFeeStepBuilder
    let swapProvidersBuilder: SendSwapProvidersBuilder
    let sendSummaryStepBuilder: SendNewSummaryStepBuilder
    let sendFinishStepBuilder: SendNewFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let sendQRCodeService = builder.makeSendQRCodeService()
        let swapManager: SwapManager = builder.makeSwapManager()
        let analyticsLogger = builder.makeSendAnalyticsLogger(coordinatorSource: coordinatorSource)
        let sendModel = builder.makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger)
        let notificationManager = builder.makeSendNewNotificationManager(receiveTokenInput: sendModel)
        let customFeeService = builder.makeCustomFeeService(input: sendModel)

        let sendFeeProvider = builder.makeSendWithSwapFeeProvider(
            receiveTokenInput: sendModel,
            sendFeeProvider: builder.makeSendFeeProvider(input: sendModel),
            swapFeeProvider: builder.makeSwapFeeProvider(swapManager: swapManager)
        )

        let amount = sendAmountStepBuilder.makeSendNewAmountStep(
            sourceIO: (input: sendModel, output: sendModel),
            sourceAmountIO: (input: sendModel, output: sendModel),
            receiveIO: (input: sendModel, output: sendModel),
            receiveAmountIO: (input: sendModel, output: sendModel),
            swapProvidersInput: sendModel,
            actionType: .send,
            sendAmountValidator: builder.makeSendSourceTokenAmountValidator(input: sendModel),
            amountModifier: .none,
            notificationService: notificationManager as? SendAmountNotificationService,
            analyticsLogger: analyticsLogger
        )

        let destination = sendDestinationStepBuilder.makeSendDestinationStep(
            io: (input: sendModel, output: sendModel),
            receiveTokenInput: sendModel,
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            router: router
        )

        let fee = sendFeeStepBuilder.makeSendFee(
            io: (input: sendModel, output: sendModel),
            feeProvider: sendFeeProvider,
            analyticsLogger: analyticsLogger,
            customFeeService: customFeeService
        )

        let providers = swapProvidersBuilder.makeSwapProviders(
            io: (input: sendModel, output: sendModel),
            receiveTokenInput: sendModel,
            analyticsLogger: analyticsLogger
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: sendModel, output: sendModel),
            receiveTokenInput: sendModel,
            sendFeeProvider: sendFeeProvider,
            destinationEditableType: .editable,
            amountEditableType: .editable,
            notificationManager: notificationManager,
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: sendModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendAmountFinishViewModel: amount.finish,
            sendDestinationCompactViewModel: destination.compact,
            sendFeeCompactViewModel: fee.finish,
        )

        // We have to set dependencies here after all setups is completed
        sendModel.externalAmountUpdater = amount.amountUpdater
        sendModel.externalDestinationUpdater = destination.externalUpdater
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        // We have to do it after sendModel fully setup
        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        let stepsManager = CommonNewSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary,
            finishStep: finish,
            feeSelector: fee.feeSelector,
            providersSelector: providers
        )

        summary.set(router: stepsManager)
        destination.step.set(stepRouter: stepsManager)

        let sendReceiveTokensListBuilder = builder.makeSendReceiveTokensListBuilder(
            sendSourceTokenInput: sendModel,
            receiveTokenOutput: sendModel
        )

        let dataBuilder = builder.makeSendBaseDataBuilder(
            input: sendModel,
            sendReceiveTokensListBuilder: sendReceiveTokensListBuilder
        )

        let interactor = CommonSendBaseInteractor(input: sendModel, output: sendModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: dataBuilder,
            analyticsLogger: analyticsLogger,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            source: coordinatorSource,
            coordinator: router
        )

        stepsManager.set(output: viewModel)
        stepsManager.router = router

        sendModel.router = viewModel
        sendModel.alertPresenter = viewModel

        // [REDACTED_TODO_COMMENT]
        // fee.step.set(alertPresenter: viewModel)
        amount.step.set(router: viewModel)

        return viewModel
    }
}
