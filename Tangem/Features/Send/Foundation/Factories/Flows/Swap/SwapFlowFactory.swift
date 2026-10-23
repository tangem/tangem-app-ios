//
//  SwapFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class SwapFlowFactory: SwapFlowBaseDependenciesFactory {
    let expressDependenciesFactory: ExpressDependenciesFactory

    private let parameters: PredefinedSwapParameters
    private var configuration: SwapFlowConfiguration { parameters.configuration }

    lazy var analyticsLogger: SendAnalyticsLogger = makeSwapAnalyticsLogger()
    lazy var swapModel = makeSwapModel(
        parameters: parameters,
        analyticsLogger: analyticsLogger,
        autoupdatingTimer: autoupdatingTimer,
        pairUpdateHandler: RegularSwapPairUpdateHandler(
            expressManager: expressDependenciesFactory.expressManager,
            swapRepository: expressDependenciesFactory.swapRepository,
            analyticsLogger: analyticsLogger
        ),
        initialResolvingPolicy: .enabled()
    )
    lazy var notificationManager = makeSwapNotificationManager()
    lazy var marketingBannerManager = makeSwapMarketingBannerManager()
    lazy var autoupdatingTimer = AutoupdatingTimer()

    init(parameters: PredefinedSwapParameters) {
        self.parameters = parameters

        expressDependenciesFactory = CommonExpressDependenciesFactory(
            userWalletInfo: parameters.userWalletInfo,
            preferredProviderId: parameters.extras?.providerId
        )
    }
}

// MARK: - SendGenericFlowFactory

extension SwapFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable, coordinatorStateProvider: SendCoordinatorStateProvider) -> SendViewModel {
        let amount = makeSwapAmountStep()
        let fee = makeSendFeeStep(router: router)
        let providers = makeSwapProviders(router: router)

        let summary = makeSwapSummaryStep(
            swapAmountViewModel: amount.viewModel,
            swapSummaryProviderViewModel: providers.compact,
            swapSummarySlippageViewModel: SwapSummarySlippageViewModel(swapProvidersInput: swapModel, slippageInput: swapModel),
            feeCompactViewModel: fee.compact,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendFeeFinishViewModel: fee.finish,
            router: router
        )

        // Steps setup
        fee.compact.bind(input: swapModel)
        fee.finish.bind(input: swapModel)

        // Notifications setup
        notificationManager.setupManager(with: swapModel)
        marketingBannerManager.setup(
            sourceTokenInput: swapModel,
            sourceTokenAmountInput: swapModel,
            receiveTokenInput: swapModel
        )

        notificationManager.setup(
            sourceTokenInput: swapModel,
            receiveTokenInput: swapModel,
            sendFeeInput: swapModel,
            swapModelStateProvider: swapModel,
            slippageInput: swapModel
        )

        // Logger setup
        analyticsLogger.setup(sendFeeInput: swapModel)
        analyticsLogger.setup(sendSourceTokenInput: swapModel)
        analyticsLogger.setup(sendReceiveTokenInput: swapModel)
        analyticsLogger.setup(sendSwapProvidersInput: swapModel)

        let tokenSelectorBuilder = SwapTokenSelectorViewModelBuilder(
            output: swapModel,
            sourceWalletsProvider: configuration.sourceTokenSelection.walletsProvider,
            receiveWalletsProvider: configuration.receiveTokenSelection.walletsProvider,
            allowsSourceMarketsTokens: configuration.sourceTokenSelection.allowsMarketsTokens,
            allowsReceiveMarketsTokens: configuration.receiveTokenSelection.allowsMarketsTokens,
            offeredReceiveTokens: configuration.offeredReceiveTokens
        )

        let stepsManager = CommonSwapStepsManager(
            summaryStep: summary,
            finishStep: finish,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            providersSelector: providers.selector,
            slippageSelectorBuilder: SwapSlippageSelectorBuilder(
                slippageInput: swapModel,
                slippageOutput: swapModel
            ),
            tokenSelectorBuilder: tokenSelectorBuilder,
            summaryTitleProvider: makeSummaryTitleProvider(),
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)
        summary.set(router: stepsManager)

        swapModel.router = viewModel
        swapModel.externalAmountUpdater = amount.amountUpdater

        // A deeplink can carry a FROM amount to prefill — push it into the amount field via the same
        // path a user's keystroke uses, so validation and the "insufficient funds" state kick in normally.
        if let sourceAmount = parameters.extras?.sourceAmount {
            amount.amountUpdater.externalUpdate(cryptoAmount: sourceAmount)
        }

        coordinatorStateProvider.setup(autoupdatingTimer: autoupdatingTimer)

        return viewModel
    }

    private func makeSummaryTitleProvider() -> any SendSummaryTitleProvider {
        if let summaryTitle = configuration.summaryTitle {
            return FixedSendSummaryTitleProvider(title: summaryTitle)
        }

        return SwapSummaryTitleProvider(sourceTokenInput: swapModel, receiveTokenInput: swapModel)
    }
}

// MARK: - SendBaseBuildable

extension SwapFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: swapModel, output: swapModel, sourceTokenInput: swapModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSwapAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: swapModel,
                sourceTokenInput: swapModel,
                receiveTokenInput: swapModel,
                providersInput: swapModel
            ),
            approveViewModelInputDataBuilder: CommonApproveViewModelInputDataBuilder(
                dataProvider: swapModel,
                analyticsLogger: analyticsLogger,
                output: swapModel
            ),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: swapModel
            ),
            analyticsLogger: analyticsLogger,
            mainButtonUIOptionsProvider: CommonSendMainButtonUIOptionsProvider(sourceTokenInput: swapModel)
        )
    }
}

// MARK: - SendAmountStepBuildable

extension SwapFlowFactory: SwapAmountStepBuildable {
    var amountIO: SwapAmountStepBuilder.IO {
        SwapAmountStepBuilder.IO(
            sourceIO: (input: swapModel, output: swapModel),
            sourceAmountIO: (input: swapModel, output: swapModel),
            receiveIO: (input: swapModel, output: swapModel),
            receiveAmountIO: (input: swapModel, output: swapModel),
            swapProvidersInput: swapModel,
            stateProvider: swapModel
        )
    }

    var amountTypes: SwapAmountStepBuilder.Types {
        .init(
            isPairReversalEnabled: configuration.isPairReversalAvailable,
            isSourceTokenSelectionEnabled: configuration.sourceTokenSelection.isSelectionEnabled,
            isReceiveTokenSelectionEnabled: configuration.receiveTokenSelection.isSelectionEnabled
        )
    }

    var amountDependencies: SwapAmountStepBuilder.Dependencies {
        SwapAmountStepBuilder.Dependencies(
            sendAmountValidator: CommonSwapAmountValidator(),
            analyticsLogger: analyticsLogger,
            isFixedRateMode: false
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension SwapFlowFactory: SwapSummaryStepBuildable {
    var summaryIO: SwapSummaryStepBuilder.IO {
        SwapSummaryStepBuilder.IO(
            input: swapModel,
            output: swapModel,
            sourceTokenInput: swapModel,
            sourceTokenAmountInput: swapModel,
            receiveTokenInput: swapModel,
            receiveTokenAmountInput: swapModel,
            swapModelStateProvider: swapModel
        )
    }

    var summaryDependencies: SwapSummaryStepBuilder.Dependencies {
        SwapSummaryStepBuilder.Dependencies(
            notificationManager: notificationManager,
            marketingBannerManager: marketingBannerManager,
            autoupdatingTimer: autoupdatingTimer,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SwapFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: swapModel,
            feeSelectorOutput: swapModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSwapProvidersBuildable

extension SwapFlowFactory: SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder.IO {
        SendSwapProvidersBuilder.IO(
            input: swapModel,
            output: swapModel,
            approveInput: swapModel,
            approveOutput: swapModel,
            sourceTokenInput: swapModel,
            receiveTokenInput: swapModel,
            receiveTokenAmountInput: swapModel
        )
    }

    var swapProvidersDependencies: SendSwapProvidersBuilder.Dependencies {
        SendSwapProvidersBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
            expressProviderFormatter: .init(balanceFormatter: .init()),
            priceChangeFormatter: .init(percentFormatter: .init())
        )
    }
}

// MARK: - SendFinishStepBuildable

extension SwapFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: swapModel)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
            headerTitleProvider: SwapFinishHeaderTitleProvider(
                sourceTokenInput: swapModel,
                receiveTokenInput: swapModel
            )
        )
    }
}
