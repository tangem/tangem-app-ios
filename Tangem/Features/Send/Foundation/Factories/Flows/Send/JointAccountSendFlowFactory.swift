//
//  JointAccountSendFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

class JointAccountSendFlowFactory: SendFlowBaseDependenciesFactory {
    let transferableToken: SendTransferableToken
    private let policy: JointAccountPolicy
    private let predefinedSendParameters: PredefinedSendParameters?
    private let coordinatorSource: SendCoordinator.Source

    lazy var analyticsLogger: SendAnalyticsLogger = makeSendAnalyticsLogger(sendType: .send, coordinatorSource: coordinatorSource)
    lazy var sendModel = makeTransferModel(
        analyticsLogger: analyticsLogger,
        predefinedValues: makePredefinedTransferValues(parameters: predefinedSendParameters)
    )

    lazy var notificationManager = makeSendNotificationManager()

    init(
        transferableToken: SendTransferableToken,
        policy: JointAccountPolicy,
        predefinedSendParameters: PredefinedSendParameters?,
        coordinatorSource: SendCoordinator.Source
    ) {
        self.transferableToken = transferableToken
        self.policy = policy
        self.predefinedSendParameters = predefinedSendParameters
        self.coordinatorSource = coordinatorSource
    }
}

// MARK: - SendGenericFlowFactory

extension JointAccountSendFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable, coordinatorStateProvider: SendCoordinatorStateProvider) -> SendViewModel {
        let amount = makeSendAmountStep()
        let destination = makeSendDestinationStep(router: router)
        let fee = makeSendFeeStep(router: router)
        let signatures = JointAccountSignaturesCompactViewModel(policy: policy, input: sendModel)

        let summary = makeSendSummaryStep(
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: fee.compact,
            jointAccountSignaturesCompactViewModel: signatures
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendDestinationCompactViewModel: destination.compact,
            addContactViewModel: SendAddContactFinishViewModel(
                sourceToken: transferableToken,
                destinationInput: sendModel,
                receiveTokenInput: nil,
                coordinator: router,
                analyticsLogger: CommonAddressBookAnalyticsLogger()
            ),
            sendFeeFinishViewModel: fee.finish,
            jointAccountSignaturesCompactViewModel: signatures,
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

        let stepsManager = CommonSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary,
            finishStep: finish,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            receiveTokensListBuilder: nil,
            providersSelector: nil,
            summaryTitleProvider: CommonSendSummaryTitleProvider(tokenItem: tokenItem),
            initialStep: CommonSendStepsManager.InitialStep(parameters: predefinedSendParameters),
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        amount.step.set(router: stepsManager)
        destination.step.set(stepRouter: stepsManager)
        summary.set(router: stepsManager)

        sendModel.router = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension JointAccountSendFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: sendModel, output: sendModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSendAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: sendModel,
                sourceTokenInput: sendModel
            ),
            approveViewModelInputDataBuilder: EmptyApproveViewModelInputDataBuilder(),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: sendModel
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            mainButtonUIOptionsProvider: JointAccountSendMainButtonUIOptionsProvider(
                base: CommonSendMainButtonUIOptionsProvider(sourceTokenInput: sendModel)
            )
        )
    }
}

// MARK: - SendAmountStepBuildable

extension JointAccountSendFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(
            sourceIO: (input: sendModel, output: sendModel),
            sourceAmountIO: (input: sendModel, output: sendModel)
        )
    }

    var amountTypes: SendAmountStepBuilder.Types {
        .init(initialSourceToken: transferableToken, flowActionType: .send)
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendAmountValidator: CommonSendAmountValidator(input: sendModel),
            amountModifier: .none,
            notificationService: .none,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendDestinationStepBuildable

extension JointAccountSendFlowFactory: SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder.IO {
        SendDestinationStepBuilder.IO(input: sendModel, output: sendModel, receiveTokenInput: nil)
    }

    var destinationTypes: SendDestinationStepBuilder.Types {
        .init(initialSourceToken: transferableToken)
    }

    var destinationDependencies: SendDestinationStepBuilder.Dependencies {
        SendDestinationStepBuilder.Dependencies(
            sendQRCodeService: makeSendQRCodeService(),
            analyticsLogger: analyticsLogger,
            destinationInteractorDependenciesProvider: SendDestinationInteractorDependenciesProvider(
                sourceToken: transferableToken,
                receivedToken: nil,
                analyticsLogger: analyticsLogger,
                destinationWalletDataProvider: CommonSendDestinationWalletDataProvider(sourceToken: transferableToken)
            )
        )
    }
}

// MARK: - SendFeeStepBuildable

extension JointAccountSendFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: sendModel,
            feeSelectorOutput: sendModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension JointAccountSendFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: sendModel, output: sendModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .editable, amountEditableType: .editable))
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: sendModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: JointAccountSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem, policy: policy),
            sendWithSwapDescriptionBuilder: makeSendWithSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFinishStepBuildable

extension JointAccountSendFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: sendModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
            headerTitleProvider: JointAccountFinishHeaderTitleProvider()
        )
    }
}
