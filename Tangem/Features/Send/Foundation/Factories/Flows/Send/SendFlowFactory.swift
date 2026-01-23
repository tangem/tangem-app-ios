//
//  SendFlowBaseFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class SendFlowFactory: SendFlowBaseDependenciesFactory {
    let userWalletInfo: UserWalletInfo
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?

    let walletAddresses: [String]
    let shouldShowFeeSelector: Bool
    let tokenHeaderProvider: SendGenericTokenHeaderProvider

    let tokenFeeProvidersManager: TokenFeeProvidersManager
    let walletModelHistoryUpdater: any WalletModelHistoryUpdater
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let expressDependenciesFactory: ExpressDependenciesFactory

    let suggestedWallets: [SendDestinationSuggestedWallet]
    let analyticsLogger: SendAnalyticsLogger

    private let sourceWalletModel: any WalletModel

    lazy var swapManager = makeSwapManager()
    lazy var sendModel = makeSendWithSwapModel(swapManager: swapManager, analyticsLogger: analyticsLogger, predefinedValues: .init())
    lazy var notificationManager = makeSendWithSwapNotificationManager(receiveTokenInput: sendModel)

    init(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) {
        self.userWalletInfo = userWalletInfo
        sourceWalletModel = walletModel

        tokenHeaderProvider = SendTokenHeaderProvider(
            userWalletInfo: userWalletInfo,
            account: walletModel.account,
            flowActionType: .send
        )
        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )
        accountModelAnalyticsProvider = walletModel.account
        walletAddresses = walletModel.addresses.map(\.value)
        shouldShowFeeSelector = walletModel.shouldShowFeeSelector

        suggestedWallets = SendSuggestedWalletsFactory().makeSuggestedWallets(walletModel: walletModel)
        analyticsLogger = Self.makeSendAnalyticsLogger(walletModel: walletModel, sendType: .send)

        walletModelHistoryUpdater = walletModel
        tokenFeeProvidersManager = TokenFeeProvidersManagerBuilder(walletModel: walletModel).makeTokenFeeProvidersManager()
        walletModelDependenciesProvider = walletModel
        availableBalanceProvider = walletModel.availableBalanceProvider
        fiatAvailableBalanceProvider = walletModel.fiatAvailableBalanceProvider
        transactionDispatcherFactory = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )
        baseDataBuilderFactory = SendBaseDataBuilderFactory(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo
        )

        let source = ExpressInteractorWalletModelWrapper(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            expressOperationType: .swapAndSend
        )

        let expressDependenciesInput = ExpressDependenciesInput(
            userWalletInfo: userWalletInfo,
            source: source,
            destination: .none
        )

        expressDependenciesFactory = CommonExpressDependenciesFactory(input: expressDependenciesInput)
    }
}

// MARK: - SendGenericFlowFactory

extension SendFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let amount = makeSendAmountStep()
        let destination = makeSendDestinationStep(router: router)
        let fee = makeSendFeeStep(router: router)
        let providers = makeSwapProviders()

        let summary = makeSendSummaryStep(
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            feeCompactViewModel: fee.compact
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendDestinationCompactViewModel: destination.compact,
            sendFeeFinishViewModel: fee.finish,
            router: router
        )

        // Model setup
        // We have to set dependencies here after all setups is completed
        sendModel.externalAmountUpdater = amount.amountUpdater
        sendModel.externalDestinationUpdater = destination.externalUpdater

        sendModel.informationRelevanceService = CommonInformationRelevanceService(
            input: sendModel, provider: sendModel
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

        let stepsManager = CommonSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary,
            finishStep: finish,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            providersSelector: providers,
            summaryTitleProvider: SendWithSwapSummaryTitleProvider(receiveTokenInput: sendModel),
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        amount.step.set(router: viewModel)
        destination.step.set(stepRouter: stepsManager)
        summary.set(router: stepsManager)

        sendModel.router = viewModel
        sendModel.alertPresenter = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension SendFlowFactory: SendBaseBuildable {
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

// MARK: - SendAmountStepBuildable

extension SendFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(
            sourceIO: (input: sendModel, output: sendModel),
            sourceAmountIO: (input: sendModel, output: sendModel),
            receiveIO: (input: sendModel, output: sendModel),
            receiveAmountIO: (input: sendModel, output: sendModel),
            swapProvidersInput: sendModel,
        )
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendAmountValidator: CommonSendAmountValidator(input: sendModel),
            amountModifier: .none,
            notificationService: notificationManager as? SendAmountNotificationService,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendDestinationStepBuildable

extension SendFlowFactory: SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder.IO {
        SendDestinationStepBuilder.IO(
            input: sendModel,
            output: sendModel,
            receiveTokenInput: sendModel,
            destinationAccountOutput: sendModel
        )
    }

    var destinationDependencies: SendDestinationStepBuilder.Dependencies {
        SendDestinationStepBuilder.Dependencies(
            sendQRCodeService: makeSendQRCodeService(),
            analyticsLogger: analyticsLogger,
            destinationInteractorDependenciesProvider: makeSendDestinationInteractorDependenciesProvider(
                receiveTokenInput: sendModel,
                analyticsLogger: analyticsLogger
            ),
        )
    }

    private func makeSendDestinationInteractorDependenciesProvider(
        receiveTokenInput: SendReceiveTokenInput,
        analyticsLogger: any SendDestinationAnalyticsLogger
    ) -> SendDestinationInteractorDependenciesProvider {
        let walletDataFactory = SendDestinationWalletDataFactory()
        let sendingWalletData = walletDataFactory.makeWalletData(
            walletModel: sourceWalletModel,
            analyticsLogger: analyticsLogger
        )

        return SendDestinationInteractorDependenciesProvider(
            receivedTokenType: receiveTokenInput.receiveToken,
            sendingWalletData: sendingWalletData,
            walletDataFactory: walletDataFactory
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SendFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: sendModel,
            feeSelectorOutput: sendModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSwapProvidersBuildable

extension SendFlowFactory: SendSwapProvidersBuildable {
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

// MARK: - SendSummaryStepBuildable

extension SendFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: sendModel, output: sendModel, receiveTokenAmountInput: sendModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .editable, amountEditableType: .editable))
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: sendModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFinishStepBuildable

extension SendFlowFactory: SendFinishStepBuildable {
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
