//
//  NewSellFlowBaseBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NewSellFlowBaseBuilder {
    let walletModel: any WalletModel
    let coordinatorSource: SendCoordinator.Source
    let sendFeeStepBuilder: SendNewFeeStepBuilder
    let sendSummaryStepBuilder: SendNewSummaryStepBuilder
    let sendFinishStepBuilder: SendNewFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(sellParameters: PredefinedSellParameters, router: SendRoutable) -> SendViewModel {
        let notificationManager = builder.makeSendNotificationManager()
        let analyticsLogger = builder.makeSendAnalyticsLogger(coordinatorSource: coordinatorSource)
        let predefinedValues = builder.mapToPredefinedValues(sellParameters: sellParameters)
        let swapManager = builder.makeSwapManager()
        let sendModel = builder.makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger, predefinedValues: predefinedValues)
        let sendFeeProvider = builder.makeSendFeeProvider(input: sendModel)
        let customFeeService = builder.makeCustomFeeService(input: sendModel)

        let sendDestinationCompactViewModel = SendNewDestinationCompactViewModel(
            input: sendModel
        )

        let sendAmountCompactViewModel = SendNewAmountCompactViewModel(
            sourceTokenInput: sendModel,
            sourceTokenAmountInput: sendModel,
            receiveTokenInput: sendModel,
            receiveTokenAmountInput: sendModel,
            swapProvidersInput: sendModel
        )

        let sendAmountFinishViewModel = SendNewAmountFinishViewModel(
            sourceTokenInput: sendModel,
            sourceTokenAmountInput: sendModel,
            receiveTokenInput: sendModel,
            receiveTokenAmountInput: sendModel,
            swapProvidersInput: sendModel
        )

        let fee = sendFeeStepBuilder.makeSendFee(
            io: (input: sendModel, output: sendModel),
            feeProvider: sendFeeProvider,
            analyticsLogger: analyticsLogger,
            customFeeService: customFeeService
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: sendModel, output: sendModel),
            receiveTokenAmountInput: sendModel,
            sendFeeProvider: sendFeeProvider,
            destinationEditableType: .disable,
            amountEditableType: .disable,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            nftAssetCompactViewModel: .none,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: sendModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: .none,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendFeeFinishViewModel: fee.finish
        )

        // We have to set dependencies here after all setups is completed
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

        // Update the fees in case we in the sell flow
        sendFeeProvider.updateFees()

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        analyticsLogger.setup(sendFeeInput: sendModel)
        analyticsLogger.setup(sendSourceTokenInput: sendModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendModel)

        // We have to do it after sendModel fully setup
        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        let stepsManager = CommonNewSellStepsManager(
            feeSelector: fee.feeSelector,
            summaryStep: summary,
            finishStep: finish
        )

        summary.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: sendModel, output: sendModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: builder.makeSendBaseDataBuilder(input: sendModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: builder.makeBlockchainSDKNotificationMapper(),
            tokenItem: walletModel.tokenItem,
            source: coordinatorSource,
            coordinator: router
        )

        stepsManager.set(output: viewModel)
        stepsManager.router = router

        sendModel.router = viewModel
        sendModel.alertPresenter = viewModel

        return viewModel
    }
}
