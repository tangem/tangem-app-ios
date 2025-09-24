//
//  StakingFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingFlowFactory2 {
    private let walletModel: any WalletModel
    private let manager: any StakingManager
    private let router: any SendRoutable

    private let builder: SendDependenciesBuilder

    // Sharing

//    lazy var sendQRCodeService = builder.makeSendQRCodeService()
//    lazy var swapManager: SwapManager = builder.makeSwapManager()
    lazy var analyticsLogger = builder.makeStakingSendAnalyticsLogger(actionType: .stake)
    lazy var stakingModel = builder.makeStakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = builder.makeStakingNotificationManager()
//    lazy var sendFeeProvider = builder.makeSendWithSwapFeeProvider(
//        receiveTokenInput: sendModel,
//        sendFeeProvider: builder.makeSendFeeProvider(input: sendModel),
//        swapFeeProvider: builder.makeSwapFeeProvider(swapManager: swapManager)
//    )
//    lazy var customFeeService = builder.makeCustomFeeService(input: sendModel)

    init(walletModel: any WalletModel, router: any SendRoutable, input: SendDependenciesBuilder.Input) {
        self.walletModel = walletModel
        self.router = router

        builder = .init(input: input)
    }

    func make() -> SendViewModel {
//        let analyticsLogger = builder.makeStakingSendAnalyticsLogger(actionType: .stake)
//        let stakingModel = builder.makeStakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
//        let notificationManager = builder.makeStakingNotificationManager()
        notificationManager.setup(provider: stakingModel, input: stakingModel)
        notificationManager.setupManager(with: stakingModel)

        let sendFeeCompactViewModel = SendNewFeeStepBuilder2.makeSendNewFeeCompactViewModel(
            input: stakingModel,
            types: .init(feeTokenItem: walletModel.feeTokenItem, isFeeApproximate: builder.isFeeApproximate())
        )
        sendFeeCompactViewModel.bind(input: stakingModel)

        let amount = makeSendAmountStep() sendAmountStepBuilder.makeSendAmountStep(
            io: (input: stakingModel, output: stakingModel),
            actionType: .stake,
            sendFeeProvider: stakingModel,
            sendQRCodeService: .none,
            sendAmountValidator: builder.makeStakingSendAmountValidator(stakingManager: manager),
            amountModifier: builder.makeStakingAmountModifier(actionType: .stake),
            analyticsLogger: analyticsLogger
        )

        let validators = stakingValidatorsStepBuilder.makeStakingValidatorsStep(
            io: (input: stakingModel, output: stakingModel),
            manager: manager,
            actionType: .stake,
            sendFeeProvider: stakingModel,
            analyticsLogger: analyticsLogger
        )

        let summary = sendSummaryStepBuilder.makeSendSummaryStep(
            io: (input: stakingModel, output: stakingModel),
            actionType: .stake,
            notificationManager: notificationManager,
            destinationEditableType: .editable,
            amountEditableType: .editable,
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            analyticsLogger: analyticsLogger
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: stakingModel,
            sendFinishAnalyticsLogger: analyticsLogger,
            sendAmountCompactViewModel: amount.compact,
            onrampAmountCompactViewModel: .none,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: .none
        )

        let stepsManager = CommonStakingStepsManager(
            provider: stakingModel,
            amountStep: amount.step,
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish,
            summaryTitleProvider: builder.makeStakingSummaryTitleProvider(actionType: .stake)
        )

        summary.step.set(router: stepsManager)

        let interactor = CommonSendBaseInteractor(input: stakingModel, output: stakingModel)

        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeStakingBaseDataBuilder(input: stakingModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: builder.makeBlockchainSDKNotificationMapper(),
            tokenItem: walletModel.tokenItem,
            source: source,
            coordinator: router
        )
        stepsManager.set(output: viewModel)
        stakingModel.router = viewModel

        return viewModel
    }

    func make() -> SendViewModel {
        //        let sendFeeStepBuilder = SendNewFeeStepBuilder(feeTokenItem: walletModel.feeTokenItem, builder: builder)
        //        let swapProvidersBuilder = SendSwapProvidersBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        //        let sendSummaryStepBuilder = SendNewSummaryStepBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        //        let sendFinishStepBuilder = SendNewFinishStepBuilder(tokenItem: walletModel.tokenItem, coordinator: router)

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
        let providers = makeSwapProviders()

        let summary = makeSendSummaryStep(
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendDestinationCompactViewModel: destination.compact,
            sendFeeFinishViewModel: fee.finish,
        )

        // Model setup

        // We have to set dependencies here after all setups is completed
        sendModel.externalAmountUpdater = amount.amountUpdater
        sendModel.externalDestinationUpdater = destination.externalUpdater
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = builder.makeInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

        // Steps setup

        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        // Notifications setup

        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        // Logger setup

        analyticsLogger.setup(sendFeeInput: sendModel)
        analyticsLogger.setup(sendSourceTokenInput: sendModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendModel)

        let stepsManager = CommonSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary,
            finishStep: finish,
            feeSelector: fee.feeSelector,
            providersSelector: providers,
            summaryTitleProvider: builder.makeSendWithSwapSummaryTitleProvider(receiveTokenInput: sendModel)
        )

        let dataBuilder = builder.makeSendBaseDataBuilder(
            input: sendModel,
            sendReceiveTokensListBuilder: builder.makeSendReceiveTokensListBuilder(
                sendSourceTokenInput: sendModel,
                receiveTokenOutput: sendModel,
                analyticsLogger: analyticsLogger,
            )
        )

        let navigationRouter = SendNavigationRouter(
            stepsManager: stepsManager,
            sendBaseDataBuilder: dataBuilder,
            feeSelector: fee.feeSelector,
            providersSelector: providers,
            router: router
        )

        amount.step.set(router: navigationRouter)
        destination.step.set(stepRouter: navigationRouter)
        summary.set(router: navigationRouter)

        let viewModel = makeSendViewModel(stepsManager: stepsManager)

        sendModel.router = navigationRouter
        sendModel.alertPresenter = viewModel

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

    func makeSwapProviders() -> SendSwapProvidersBuilder2.ReturnValue {
        let io = SendSwapProvidersBuilder2.IO(input: sendModel, output: sendModel, receiveTokenInput: sendModel)
        let types = SendSwapProvidersBuilder2.Types(tokenItem: walletModel.tokenItem)
        let dependencies = SendSwapProvidersBuilder2.Dependencies(
            analyticsLogger: analyticsLogger,
            expressProviderFormatter: .init(balanceFormatter: .init()),
            priceChangeFormatter: .init(percentFormatter: .init())
        )

        return SendSwapProvidersBuilder2.make(
            io: .init(input: sendModel, output: sendModel, receiveTokenInput: sendModel),
            types: .init(tokenItem: walletModel.tokenItem),
            dependencies: .init(
                analyticsLogger: analyticsLogger,
                expressProviderFormatter: .init(balanceFormatter: .init()),
                priceChangeFormatter: .init(percentFormatter: .init())
            )
        )
    }

    func makeSendSummaryStep(
        sendDestinationCompactViewModel: SendDestinationCompactViewModel,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel
    ) -> SendNewSummaryStepBuilder2.ReturnValue {
        let io = SendNewSummaryStepBuilder2.IO(input: sendModel, output: sendModel, receiveTokenAmountInput: sendModel)

        let dependencies = SendNewSummaryStepBuilder2.Dependencies(
            sendFeeProvider: sendFeeProvider,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: builder.makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: builder.makeSwapTransactionSummaryDescriptionBuilder()
        )

        return SendNewSummaryStepBuilder2.make(
            io: io,
            dependencies: dependencies,
            destinationEditableType: .editable,
            amountEditableType: .editable,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            nftAssetCompactViewModel: .none,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )
    }

    func makeSendFinishStep(
        sendAmountFinishViewModel: SendNewAmountFinishViewModel,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel,
        sendFeeFinishViewModel: SendFeeFinishViewModel
    ) -> SendNewFinishStepBuilder2.ReturnValue {
        let io = SendNewFinishStepBuilder2.IO(input: sendModel)
        let types = SendNewFinishStepBuilder2.Types(tokenItem: walletModel.tokenItem)

        let dependencies = SendNewFinishStepBuilder2.Dependencies(
            analyticsLogger: analyticsLogger,
        )

        return SendNewFinishStepBuilder2.make(
            io: io,
            types: types,
            dependencies: dependencies,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: .none,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            router: router
        )
    }

    func makeSendViewModel(
        stepsManager: any SendStepsManager,
    ) -> SendViewModelBuilder.ReturnValue {
        let io = SendViewModelBuilder.IO(input: sendModel, output: sendModel)
        let types = SendViewModelBuilder.Types(tokenItem: walletModel.tokenItem)

        let dependencies = SendViewModelBuilder.Dependencies(
            stepsManager: stepsManager,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: builder.makeSendBaseDataBuilder(
                input: sendModel,
                sendReceiveTokensListBuilder: builder.makeSendReceiveTokensListBuilder(
                    sendSourceTokenInput: sendModel,
                    receiveTokenOutput: sendModel,
                    analyticsLogger: analyticsLogger,
                )
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: builder.makeBlockchainSDKNotificationMapper()
        )

        return SendViewModelBuilder.make(
            io: io,
            types: types,
            dependencies: dependencies,
            router: router
        )
    }
}

class SendNavigationRouter {
    let stepsManager: any SendStepsManager
    let sendBaseDataBuilder: any SendBaseDataBuilder
    let feeSelector: FeeSelectorContentViewModel
    let providersSelector: SendSwapProvidersSelectorViewModel
    weak var router: (any SendRoutable)?

    init(
        stepsManager: any SendStepsManager,
        sendBaseDataBuilder: any SendBaseDataBuilder,
        feeSelector: FeeSelectorContentViewModel,
        providersSelector: SendSwapProvidersSelectorViewModel,
        router: any SendRoutable
    ) {
        self.stepsManager = stepsManager
        self.sendBaseDataBuilder = sendBaseDataBuilder
        self.feeSelector = feeSelector
        self.providersSelector = providersSelector
        self.router = router
    }
}

extension SendNavigationRouter: SendSummaryStepsRoutable {
    func summaryStepRequestEditDestination() {
        (stepsManager as? SendSummaryStepsRoutable)?.summaryStepRequestEditDestination()
    }

    func summaryStepRequestEditAmount() {
        (stepsManager as? SendSummaryStepsRoutable)?.summaryStepRequestEditAmount()
    }

    func summaryStepRequestEditFee() {
        router?.openFeeSelector(viewModel: feeSelector)
    }

    func summaryStepRequestEditProviders() {
        router?.openSwapProvidersSelector(viewModel: providersSelector)
    }
}

extension SendNavigationRouter: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        (stepsManager as? SendDestinationStepRoutable)?.destinationStepFulfilled()
    }
}

extension SendNavigationRouter: SendNewAmountRoutable {
    func openReceiveTokensList() {
        let tokensListBuilder = sendBaseDataBuilder.makeSendReceiveTokensList()
        router?.openReceiveTokensList(tokensListBuilder: tokensListBuilder)
    }
}

extension SendNavigationRouter: SendModelRoutable {
    func openNetworkCurrency() {
        let (userWalletId, feeTokenItem) = sendBaseDataBuilder.makeFeeCurrencyData()
        router?.openFeeCurrency(userWalletId: userWalletId, feeTokenItem: feeTokenItem)
    }

    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel) {
        router?.openHighPriceImpactWarningSheetViewModel(viewModel: viewModel)
    }

    func resetFlow() {
        stepsManager.resetFlow()
    }
}
