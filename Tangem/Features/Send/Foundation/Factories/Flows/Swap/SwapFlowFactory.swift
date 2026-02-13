//
//  SwapFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class SwapFlowFactory: SendFlowBaseDependenciesFactory {
    let sourceToken: SendSourceToken
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let expressDependenciesFactory: ExpressDependenciesFactory

    lazy var analyticsLogger: SendAnalyticsLogger = makeSendAnalyticsLogger(sendType: .send)
    lazy var swapManager = makeSwapManager()
    lazy var sendModel = makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger, predefinedValues: .init())
    lazy var notificationManager = makeSendWithSwapNotificationManager(receiveTokenInput: sendModel)

    init(
        sourceToken: SendSourceToken,
        baseDataBuilderFactory: SendBaseDataBuilderFactory,
        source: ExpressInteractorWalletModelWrapper
    ) {
        self.sourceToken = sourceToken
        self.baseDataBuilderFactory = baseDataBuilderFactory

        let expressDependenciesInput = ExpressDependenciesInput(
            userWalletInfo: sourceToken.userWalletInfo,
            source: source,
            destination: .none
        )

        expressDependenciesFactory = CommonExpressDependenciesFactory(input: expressDependenciesInput)
    }
}

// MARK: - SendGenericFlowFactory

extension SwapFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let fee = makeSendFeeStep(router: router)
        let providers = makeSwapProviders()

        let summary = makeSwapSummaryStep(
            sendFeeCompactViewModel: fee.compact
        )

        let finish = makeSendFinishStep(
            // sendAmountFinishViewModel: amount.finish,
            // sendDestinationCompactViewModel: destination.compact,
            sendFeeFinishViewModel: fee.finish,
            router: router
        )

        // Steps setup
        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        // Notifications setup
        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        // Logger setup
        analyticsLogger.setup(sendDestinationInput: sendModel)
        analyticsLogger.setup(sendFeeInput: sendModel)
        analyticsLogger.setup(sendSourceTokenInput: sendModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendModel)

        let stepsManager = CommonSwapStepsManager(
            summaryStep: summary,
            finishStep: finish,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            providersSelector: providers,
            summaryTitleProvider: SendWithSwapSummaryTitleProvider(receiveTokenInput: sendModel),
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)
        summary.set(router: stepsManager)

        sendModel.router = viewModel
        sendModel.alertPresenter = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension SwapFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: sendModel, output: sendModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSendAlertBuilder(),
            dataBuilder: baseDataBuilderFactory.makeSendBaseDataBuilder(
                baseDataInput: sendModel,
                approveDataInput: swapManager,
                sendReceiveTokensListBuilder: SendReceiveTokensListBuilder(
                    userWalletInfo: userWalletInfo,
                    sourceTokenInput: sendModel,
                    receiveTokenOutput: sendModel,
                    receiveTokenBuilder: makeSendReceiveTokenBuilder(),
                    analyticsLogger: analyticsLogger
                )
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper(),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension SwapFlowFactory: SwapSummaryStepBuildable {
    var summaryIO: SwapSummaryStepBuilder.IO {
        SwapSummaryStepBuilder.IO(input: sendModel, output: sendModel, receiveTokenAmountInput: sendModel)
    }

    var summaryTypes: SwapSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .editable, amountEditableType: .editable))
    }

    var summaryDependencies: SwapSummaryStepBuilder.Dependencies {
        SwapSummaryStepBuilder.Dependencies(
            sendFeeProvider: sendModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SwapFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: sendModel,
            feeSelectorOutput: sendModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSwapProvidersBuildable

extension SwapFlowFactory: SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder.IO {
        SendSwapProvidersBuilder.IO(input: sendModel, output: sendModel, receiveTokenInput: sendModel)
    }

    var swapProvidersTypes: SendSwapProvidersBuilder.Types {
        SendSwapProvidersBuilder.Types(tokenItem: tokenItem)
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
        SendFinishStepBuilder.IO(input: sendModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
