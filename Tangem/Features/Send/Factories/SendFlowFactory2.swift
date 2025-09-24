//
//  SendFlowFactory2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

class SendFlowFactory2 {
    private let walletModel: any WalletModel
    private let router: any SendRoutable

    private let builder: SendDependenciesBuilder

    // Sharing

    lazy var sendQRCodeService = builder.makeSendQRCodeService()
    lazy var swapManager: SwapManager = builder.makeSwapManager()
    lazy var analyticsLogger = builder.makeSendAnalyticsLogger(sendType: .send)
    lazy var sendModel = builder.makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = builder.makeSendNewNotificationManager(receiveTokenInput: sendModel)
    lazy var sendFeeProvider = builder.makeSendWithSwapFeeProvider(
        receiveTokenInput: sendModel,
        sendFeeProvider: builder.makeSendFeeProvider(input: sendModel),
        swapFeeProvider: builder.makeSwapFeeProvider(swapManager: swapManager)
    )
    lazy var customFeeService = builder.makeCustomFeeService(input: sendModel)

    init(walletModel: any WalletModel, router: any SendRoutable, input: SendDependenciesBuilder.Input) {
        self.walletModel = walletModel
        self.router = router

        builder = .init(input: input)
    }

    func make() -> SendViewModel {
        let sendFeeStepBuilder = SendNewFeeStepBuilder(feeTokenItem: walletModel.feeTokenItem, builder: builder)
        let swapProvidersBuilder = SendSwapProvidersBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        let sendSummaryStepBuilder = SendNewSummaryStepBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        let sendFinishStepBuilder = SendNewFinishStepBuilder(tokenItem: walletModel.tokenItem, coordinator: router)

//        let sendQRCodeService = builder.makeSendQRCodeService()
//        let swapManager: SwapManager = builder.makeSwapManager()
//        let analyticsLogger = builder.makeSendAnalyticsLogger(sendType: .send)
//        let sendModel = builder.makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger)
//        let notificationManager = builder.makeSendNewNotificationManager(receiveTokenInput: sendModel)
//        let customFeeService = builder.makeCustomFeeService(input: sendModel)

//        let sendFeeProvider = builder.makeSendWithSwapFeeProvider(
//            receiveTokenInput: sendModel,
//            sendFeeProvider: builder.makeSendFeeProvider(input: sendModel),
//            swapFeeProvider: builder.makeSwapFeeProvider(swapManager: swapManager)
//        )

        let amount = makeSendAmountStep()
        let destination = makeSendDestinationStep()
        let fee = makeSendFeeStep()

        let providers = swapProvidersBuilder.makeSwapProviders(
            io: (input: sendModel, output: sendModel),
            receiveTokenInput: sendModel,
            analyticsLogger: analyticsLogger
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

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        analyticsLogger.setup(sendFeeInput: sendModel)
        analyticsLogger.setup(sendSourceTokenInput: sendModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendModel)

        // We have to do it after sendModel fully setup
        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        let stepsManager = CommonSendStepsManager(
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
            source: .main,
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

    func makeSendAmountStep() -> SendNewAmountStepBuilder.ReturnValue {
        let io = SendNewAmountStepBuilder2.IO(
            sourceIO: (input: sendModel, output: sendModel),
            sourceAmountIO: (input: sendModel, output: sendModel),
            receiveIO: (input: sendModel, output: sendModel),
            receiveAmountIO: (input: sendModel, output: sendModel),
            swapProvidersInput: sendModel,
        )

        let dependencies = SendNewAmountStepBuilder2.Dependencies(
            sendAmountValidator: builder.makeSendSourceTokenAmountValidator(input: sendModel),
            amountModifier: .none,
            notificationService: notificationManager as? SendAmountNotificationService,
            analyticsLogger: analyticsLogger
        )

        return SendNewAmountStepBuilder2.make(io: io, dependencies: dependencies)
    }

    func makeSendDestinationStep() -> SendDestinationStepBuilder2.ReturnValue {
        let io = SendDestinationStepBuilder2.IO(input: sendModel, output: sendModel, receiveTokenInput: sendModel)

        let dependencies = SendDestinationStepBuilder2.Dependencies(
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            destinationInteractorDependenciesProvider: builder.makeSendDestinationInteractorDependenciesProvider(
                analyticsLogger: analyticsLogger
            ),
        )

        return SendDestinationStepBuilder2.make(io: io, dependencies: dependencies, router: router)
    }

    func makeSendFeeStep() -> SendNewFeeStepBuilder2.ReturnValue {
        let io = SendNewFeeStepBuilder2.IO(input: sendModel, output: sendModel)
        let types = SendNewFeeStepBuilder2.Types(feeTokenItem: walletModel.feeTokenItem, isFeeApproximate: builder.isFeeApproximate())
        let dependencies = SendNewFeeStepBuilder2.Dependencies(
            feeProvider: sendFeeProvider,
            analyticsLogger: analyticsLogger,
            customFeeService: customFeeService
        )

        return SendNewFeeStepBuilder2.make(io: io, types: types, dependencies: dependencies, router: router)
    }
}
