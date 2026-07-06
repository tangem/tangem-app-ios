//
//  SendWithSwapFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class SendWithSwapFlowFactory: SendWithSwapFlowBaseDependenciesFactory {
    var transferableToken: SendTransferableToken { sourceToken }
    var tokenItem: TokenItem { transferableToken.tokenItem }

    let sourceToken: SendWithSwapToken
    private let predefinedSendParameters: PredefinedSendParameters?
    private let coordinatorSource: SendCoordinator.Source
    private let shouldStartFromTokenList: Bool
    let expressDependenciesFactory: ExpressDependenciesFactory

    lazy var autoupdatingTimer = AutoupdatingTimer()
    lazy var analyticsLogger: SendAnalyticsLogger = makeSendWithSwapAnalyticsLogger(sendType: .send, coordinatorSource: coordinatorSource)

    lazy var sendNotificationManager = makeSendNotificationManager()
    lazy var swapNotificationManager = makeSwapNotificationManager()
    lazy var notificationManager = makeSendWithSwapNotificationManager(
        receiveTokenInput: swapModel,
        sendNotificationManager: sendNotificationManager,
        swapNotificationManager: swapNotificationManager
    )
    private lazy var predefinedTransferValues = mapToPredefinedValues(parameters: predefinedSendParameters)
    private lazy var predefinedInitialStep = mapToInitialStep(parameters: predefinedSendParameters)

    lazy var transferModel = makeTransferModel(
        analyticsLogger: analyticsLogger,
        predefinedValues: predefinedTransferValues
    )
    lazy var swapModel = makeSwapModel(
        sourceToken: sourceToken,
        receiveToken: .none,
        analyticsLogger: analyticsLogger,
        autoupdatingTimer: autoupdatingTimer,
        pairUpdateHandler: SendWithSwapPairUpdateHandler(
            expressManager: expressDependenciesFactory.expressManager
        ),
        shouldStartInitialLoading: false
    )
    lazy var sendWithSwapModel = makeSendWithSwapModel(
        transferModel: transferModel,
        swapModel: swapModel,
        analyticsLogger: analyticsLogger,
        predefinedValues: predefinedTransferValues,
        autoupdatingTimer: autoupdatingTimer
    )

    init(
        sourceToken: SendWithSwapToken,
        predefinedSendParameters: PredefinedSendParameters? = nil,
        shouldStartFromTokenList: Bool = false,
        coordinatorSource: SendCoordinator.Source = .main
    ) {
        self.shouldStartFromTokenList = shouldStartFromTokenList
        self.sourceToken = sourceToken
        self.predefinedSendParameters = predefinedSendParameters
        self.coordinatorSource = coordinatorSource
        expressDependenciesFactory = CommonExpressDependenciesFactory(userWalletInfo: sourceToken.userWalletInfo)
    }

    private func mapToPredefinedValues(parameters: PredefinedSendParameters?) -> TransferModel.PredefinedValues {
        guard let parameters else {
            return .init()
        }

        let destination = SendDestination(value: .plain(parameters.destination), source: .qrCode)

        let amount = parameters.amount.map { amount in
            let fiatValue = tokenItem.currencyId.flatMap { currencyId in
                BalanceConverter().convertToFiat(amount, currencyId: currencyId)
            }

            return SendAmount(type: .typical(crypto: amount, fiat: fiatValue))
        }

        let additionalField: SendDestinationAdditionalField = {
            guard let type = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain) else {
                return .notSupported
            }

            guard let tag = parameters.tag?.nilIfEmpty else {
                return .empty(type: type)
            }

            do {
                let params = try makeTransactionParametersBuilder().transactionParameters(value: tag)
                return .filled(type: type, value: tag, params: params)
            } catch {
                assertionFailure("Failed to build transaction parameters for predefined tag: \(error)")
                return .empty(type: type)
            }
        }()

        return TransferModel.PredefinedValues(
            destination: destination,
            tag: additionalField,
            amount: amount
        )
    }

    private func makeAddContactViewModel(router: SendRoutable) -> SendAddContactFinishViewModel? {
        guard FeatureProvider.isAvailable(.addressBook) else {
            return nil
        }

        return SendAddContactFinishViewModel(
            sourceToken: sourceToken,
            destinationInput: sendWithSwapModel,
            receiveTokenInput: sendWithSwapModel,
            coordinator: router,
            analyticsLogger: CommonAddressBookAnalyticsLogger()
        )
    }

    private func mapToInitialStep(parameters: PredefinedSendParameters?) -> CommonSendStepsManager.InitialStep {
        guard let parameters else {
            return .amount
        }

        switch parameters.initialStep {
        case .amount:
            return .amount
        case .amountThenSummary:
            return .amountThenSummary
        case .summary:
            return .summary
        }
    }
}

// MARK: - SendGenericFlowFactory

extension SendWithSwapFlowFactory: SendGenericFlowFactory {
    func make(
        router: any SendRoutable,
        coordinatorStateProvider: SendCoordinatorStateProvider
    ) -> SendViewModel {
        let amount = makeSendAmountStep(shouldStartFromTokenList: shouldStartFromTokenList)
        let destination = makeSendDestinationStep(router: router)
        let fee = makeSendFeeStep(router: router)
        let providers = makeSwapProviders(router: router)

        let summary = makeSendSummaryStep(
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendDestinationCompactViewModel: destination.compact,
            addContactViewModel: makeAddContactViewModel(router: router),
            sendFeeFinishViewModel: fee.finish,
            router: router
        )

        // Model setup
        // We have to set dependencies here after all setups is completed
        sendWithSwapModel.externalDestinationUpdater = destination.externalUpdater

        // Forward external updaters to internal models
        transferModel.externalAmountUpdater = amount.amountUpdater
        transferModel.externalDestinationUpdater = destination.externalUpdater
        transferModel.informationRelevanceService = CommonInformationRelevanceService(
            input: sendWithSwapModel, provider: sendWithSwapModel
        )
        swapModel.externalAmountUpdater = amount.amountUpdater

        // Steps setup
        fee.compact.bind(input: sendWithSwapModel)
        fee.finish.bind(input: sendWithSwapModel)

        // Notifications setup
        sendNotificationManager.setup(input: transferModel)
        sendNotificationManager.setupManager(with: transferModel)

        swapNotificationManager.setupManager(with: sendWithSwapModel)
        swapNotificationManager.setup(
            sourceTokenInput: swapModel,
            receiveTokenInput: swapModel,
            sendFeeInput: swapModel,
            swapModelStateProvider: swapModel
        )

        // Logger setup
        analyticsLogger.setup(sendDestinationInput: sendWithSwapModel)
        analyticsLogger.setup(sendFeeInput: sendWithSwapModel)
        analyticsLogger.setup(sendSourceTokenInput: sendWithSwapModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendWithSwapModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendWithSwapModel)

        let sendReceiveTokensListBuilder = SendReceiveTokensListBuilder(
            userWalletInfo: userWalletInfo,
            sourceTokenInput: sendWithSwapModel,
            receiveTokenOutput: sendWithSwapModel,
            analyticsLogger: analyticsLogger
        )

        let stepsManager = CommonSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary,
            finishStep: finish,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            receiveTokensListBuilder: sendReceiveTokensListBuilder,
            providersSelector: providers.selector,
            summaryTitleProvider: SendWithSwapSummaryTitleProvider(receiveTokenInput: sendWithSwapModel),
            initialStep: predefinedInitialStep,
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        amount.step.set(router: stepsManager)
        destination.step.set(stepRouter: stepsManager)
        summary.set(router: stepsManager)

        transferModel.router = viewModel

        swapModel.router = viewModel
        swapModel.alertPresenter = viewModel

        sendWithSwapModel.router = viewModel
        sendWithSwapModel.alertPresenter = viewModel

        coordinatorStateProvider.setup(autoupdatingTimer: autoupdatingTimer)

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension SendWithSwapFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: sendWithSwapModel, output: sendWithSwapModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSendAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: sendWithSwapModel,
                sourceTokenInput: sendWithSwapModel
            ),
            approveViewModelInputDataBuilder: CommonApproveViewModelInputDataBuilder(
                dataProvider: sendWithSwapModel,
                analyticsLogger: analyticsLogger,
                output: sendWithSwapModel,
                confirmTransactionPolicy: sourceToken.confirmTransactionPolicy
            ),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: sendWithSwapModel
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            mainButtonUIOptionsProvider: CommonSendMainButtonUIOptionsProvider(sourceTokenInput: sendWithSwapModel)
        )
    }
}

// MARK: - SendAmountStepBuildable

extension SendWithSwapFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(
            sourceIO: (input: sendWithSwapModel, output: sendWithSwapModel),
            sourceAmountIO: (input: sendWithSwapModel, output: sendWithSwapModel),
            receiveIO: (input: sendWithSwapModel, output: sendWithSwapModel),
            receiveAmountIO: (input: sendWithSwapModel, output: sendWithSwapModel),
            swapProvidersInput: sendWithSwapModel,
        )
    }

    var amountTypes: SendAmountStepBuilder.Types {
        .init(initialSourceToken: sourceToken, flowActionType: .send)
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendAmountValidator: CommonSendAmountValidator(input: sendWithSwapModel),
            amountModifier: .none,
            notificationService: notificationManager as? SendAmountNotificationService,
            analyticsLogger: analyticsLogger,
            providerRateTypesPublisher: sendWithSwapModel.providerRateTypesPublisher
        )
    }
}

// MARK: - SendDestinationStepBuildable

extension SendWithSwapFlowFactory: SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder.IO {
        SendDestinationStepBuilder.IO(
            input: sendWithSwapModel,
            output: sendWithSwapModel,
            receiveTokenInput: sendWithSwapModel
        )
    }

    var destinationTypes: SendDestinationStepBuilder.Types {
        .init(initialSourceToken: sourceToken)
    }

    var destinationDependencies: SendDestinationStepBuilder.Dependencies {
        SendDestinationStepBuilder.Dependencies(
            sendQRCodeService: makeSendQRCodeService(),
            analyticsLogger: analyticsLogger,
            destinationInteractorDependenciesProvider: SendDestinationInteractorDependenciesProvider(
                sourceToken: sourceToken,
                receivedToken: sendWithSwapModel.receiveToken.value,
                analyticsLogger: analyticsLogger,
                destinationWalletDataProvider: CommonSendDestinationWalletDataProvider(sourceToken: sourceToken)
            )
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SendWithSwapFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: sendWithSwapModel,
            feeSelectorOutput: sendWithSwapModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSwapProvidersBuildable

extension SendWithSwapFlowFactory: SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder.IO {
        SendSwapProvidersBuilder.IO(input: sendWithSwapModel, output: sendWithSwapModel, approveInput: sendWithSwapModel, approveOutput: sendWithSwapModel, sourceTokenInput: sendWithSwapModel, receiveTokenInput: sendWithSwapModel, receiveTokenAmountInput: sendWithSwapModel)
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

extension SendWithSwapFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(
            input: sendWithSwapModel,
            output: sendWithSwapModel,
            swapModelStateProvider: swapModel
        )
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .editable, amountEditableType: .editable))
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: sendWithSwapModel,
            notificationManager: notificationManager,
            autoupdatingTimer: autoupdatingTimer,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            sendWithSwapDescriptionBuilder: makeSendWithSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFinishStepBuildable

extension SendWithSwapFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: sendWithSwapModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
            headerTitleProvider: SendWithSwapFinishHeaderTitleProvider()
        )
    }
}
