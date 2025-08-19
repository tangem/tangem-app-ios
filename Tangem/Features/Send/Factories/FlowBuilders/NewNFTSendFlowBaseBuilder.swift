//
//  NewNFTSendFlowBaseBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NewNFTSendFlowBaseBuilder {
    let walletModel: any WalletModel
    let coordinatorSource: SendCoordinator.Source
    let nftAssetStepBuilder: NFTAssetStepBuilder
    let sendDestinationStepBuilder: SendNewDestinationStepBuilder
    let sendFeeStepBuilder: SendNewFeeStepBuilder
    let sendSummaryStepBuilder: SendNewSummaryStepBuilder
    let sendFinishStepBuilder: SendNewFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let notificationManager = builder.makeSendNotificationManager()
        let analyticsLogger = builder.makeSendAnalyticsLogger(coordinatorSource: coordinatorSource)
        let sendQRCodeService = builder.makeSendQRCodeService()
        let swapManager = builder.makeSwapManager()
        let predefinedValues = builder.makePredefinedNFTValues()
        let sendModel = builder.makeSendWithSwapModel(
            swapManager: swapManager,
            analyticsLogger: analyticsLogger,
            predefinedValues: predefinedValues
        )
        let sendFeeProvider = builder.makeSendFeeProvider(input: sendModel)
        let customFeeService = builder.makeCustomFeeService(input: sendModel)
        let nftAssetCompactViewModel = nftAssetStepBuilder.makeNFTAssetCompactViewModel()

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

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: sendModel, output: sendModel),
            receiveTokenAmountInput: sendModel,
            sendFeeProvider: sendFeeProvider,
            destinationEditableType: .editable,
            // Amount is fixed for NFTs
            amountEditableType: .noEditable,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: .none,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: sendModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendAmountFinishViewModel: .none,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: destination.compact,
            sendFeeFinishViewModel: fee.finish
        )

        // We have to set dependencies here after all setups is completed
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        analyticsLogger.setup(sendFeeInput: sendModel)

        // We have to do it after sendModel fully setup
        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        let stepsManager = NewNFTSendStepsManager(
            destinationStep: destination.step,
            feeSelector: fee.feeSelector,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: builder.makeSendSummaryTitleProvider()
        )

        summary.set(router: stepsManager)
        destination.step.set(stepRouter: stepsManager)

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

        return viewModel
    }
}
