//
//  NewSendFlowBaseBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NewSendFlowBaseFactory {
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem

    let builder: SendDependenciesBuilder
    let coordinatorSource: SendCoordinator.Source

    func build() -> (
        sendDestinationStepBuilder: SendNewDestinationStepBuilder,
        sendAmountStepBuilder: SendNewAmountStepBuilder,
        sendFeeStepBuilder: SendNewFeeStepBuilder,
        swapProvidersBuilder: SendSwapProvidersBuilder,
        sendSummaryStepBuilder: SendNewSummaryStepBuilder,
        sendFinishStepBuilder: SendNewFinishStepBuilder,
    ) {
        // Common
        let swapManager: SwapManager = builder.makeSwapManager()

        let analyticsLogger = builder.makeSendAnalyticsLogger(coordinatorSource: coordinatorSource)
        let sendModel = builder.makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger)

        analyticsLogger.setup(sendFeeInput: sendModel)
        analyticsLogger.setup(sendSourceTokenInput: sendModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendModel)

        let notificationManager = builder.makeSendNewNotificationManager(receiveTokenInput: sendModel)
        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        let customFeeService = builder.makeCustomFeeService(input: sendModel)
        let sendFeeProvider = builder.makeSendWithSwapFeeProvider(
            receiveTokenInput: sendModel,
            sendFeeProvider: builder.makeSendFeeProvider(input: sendModel),
            swapFeeProvider: builder.makeSwapFeeProvider(swapManager: swapManager)
        )

        let sendDestinationStepBuilder = SendNewDestinationStepBuilder(
            interactorDependenciesProvider: builder.makeSendNewDestinationInteractorDependenciesProvider(analyticsLogger: analyticsLogger),
            sendQRCodeService: builder.makeSendQRCodeService(),
            analyticsLogger: analyticsLogger
        )

        let sendAmountStepBuilder = SendNewAmountStepBuilder(
            sendAmountValidator: builder.makeSendSourceTokenAmountValidator(input: sendModel),
            amountModifier: .none,
            notificationService: notificationManager as? SendAmountNotificationService,
            analyticsLogger: analyticsLogger
        )

        let sendFeeStepBuilder = SendNewFeeStepBuilder(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: builder.isFeeApproximate(),
            feeProvider: sendFeeProvider,
            analyticsLogger: analyticsLogger,
            customFeeService: customFeeService,
            feeSelectorCustomFeeFieldsBuilder: builder.makeFeeSelectorCustomFeeFieldsBuilder(customFeeService: customFeeService)
        )

        let swapProvidersBuilder = SendSwapProvidersBuilder(
            tokenItem: tokenItem,
            expressProviderFormatter: builder.makeExpressProviderFormatter(),
            priceChangeFormatter: builder.makePriceChangeFormatter(),
            analyticsLogger: analyticsLogger
        )

        return (
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            swapProvidersBuilder: swapProvidersBuilder,
            sendSummaryStepBuilder: SendNewSummaryStepBuilder,
            sendFinishStepBuilder: SendNewFinishStepBuilder,
        )
    }
}

struct NewSendFlowBaseBuilder {
    let walletModel: any WalletModel
    let coordinatorSource: SendCoordinator.Source

    let sendSummaryStepBuilder: SendNewSummaryStepBuilder
    let sendFinishStepBuilder: SendNewFinishStepBuilder
    let builder: SendDependenciesBuilder

    let factory: NewSendFlowBaseFactory

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let swapManager: SwapManager = builder.makeSwapManager()

        let analyticsLogger = builder.makeSendAnalyticsLogger(coordinatorSource: coordinatorSource)
        let sendModel = builder.makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger)

        analyticsLogger.setup(sendFeeInput: sendModel)
        analyticsLogger.setup(sendSourceTokenInput: sendModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendModel)

        let notificationManager = builder.makeSendNewNotificationManager(receiveTokenInput: sendModel)
        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        let customFeeService = builder.makeCustomFeeService(input: sendModel)
        let sendFeeProvider = builder.makeSendWithSwapFeeProvider(
            receiveTokenInput: sendModel,
            sendFeeProvider: builder.makeSendFeeProvider(input: sendModel),
            swapFeeProvider: builder.makeSwapFeeProvider(swapManager: swapManager)
        )

        let (
            sendDestinationStepBuilder,
            sendAmountStepBuilder,
            sendFeeStepBuilder,
            swapProvidersBuilder,
            sendSummaryStepBuilder,
            sendFinishStepBuilder
        ) = factory.build()

        // Steps
        let amount = sendAmountStepBuilder.makeSendNewAmountStep(
            sourceIO: (input: sendModel, output: sendModel),
            sourceAmountIO: (input: sendModel, output: sendModel),
            receiveIO: (input: sendModel, output: sendModel),
            receiveAmountIO: (input: sendModel, output: sendModel),
            swapProvidersInput: sendModel
        )

        let destination = sendDestinationStepBuilder.makeSendDestinationStep(
            io: (input: sendModel, output: sendModel),
            receiveTokenInput: sendModel,
            router: router
        )

        let fee = sendFeeStepBuilder.makeSendFee(
            io: (input: sendModel, output: sendModel)
        )

        let providers = swapProvidersBuilder.makeSwapProviders(
            io: (input: sendModel, output: sendModel),
            receiveTokenInput: sendModel
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: sendModel, output: sendModel),
            receiveTokenAmountInput: sendModel,
            sendFeeProvider: sendFeeProvider,
            destinationEditableType: .editable,
            amountEditableType: .editable,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            nftAssetCompactViewModel: .none,
            stakingValidatorsCompactViewModel: nil,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: sendModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendAmountFinishViewModel: amount.finish,
            nftAssetCompactViewModel: .none,
            sendDestinationCompactViewModel: destination.compact,
            sendFeeFinishViewModel: fee.finish,
        )

        // We have to set dependencies here after all setups is completed
        sendModel.externalAmountUpdater = amount.amountUpdater
        sendModel.externalDestinationUpdater = destination.externalUpdater
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

        // We have to do it after sendModel fully setup
        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        let stepsManager = CommonNewSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary,
            finishStep: finish,
            feeSelector: fee.feeSelector,
            providersSelector: providers,
            summaryTitleProvider: builder.makeSendWithSwapSummaryTitleProvider(receiveTokenInput: sendModel)
        )

        summary.set(router: stepsManager)
        destination.step.set(stepRouter: stepsManager)

        let sendReceiveTokensListBuilder = builder.makeSendReceiveTokensListBuilder(
            sendSourceTokenInput: sendModel,
            receiveTokenOutput: sendModel,
            analyticsLogger: analyticsLogger,
        )

        let dataBuilder = builder.makeSendBaseDataBuilder(
            input: sendModel,
            sendReceiveTokensListBuilder: sendReceiveTokensListBuilder
        )

        let interactor = CommonSendBaseInteractor(input: sendModel, output: sendModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: dataBuilder,
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: builder.makeBlockchainSDKNotificationMapper(),
            tokenItem: walletModel.tokenItem,
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
