//
//  OnrampFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemLocalization
import struct TangemUI.TokenIconInfo

class OnrampFlowFactory: OnrampFlowBaseDependenciesFactory {
    let sourceToken: SendSourceToken
    let parameters: PredefinedOnrampParameters
    let coordinatorSource: SendCoordinator.Source

    let baseDataBuilderFactory: SendBaseDataBuilderFactory

    let pendingExpressTransactionsManagerBuilder: PendingExpressTransactionsManagerBuilder
    let expressDependenciesFactory: ExpressDependenciesFactory

    lazy var dependencies = makeOnrampDependencies(preferredValues: parameters.preferredValues)
    lazy var analyticsLogger = makeOnrampSendAnalyticsLogger(source: coordinatorSource)
    lazy var notificationManager = makeOnrampNotificationManager(input: onrampModel, delegate: onrampModel)

    lazy var onrampModel = makeOnrampModel(
        onrampManager: dependencies.manager,
        onrampDataRepository: dependencies.dataRepository,
        onrampRepository: dependencies.repository,
        analyticsLogger: analyticsLogger,
        predefinedValues: .init(amount: parameters.amount)
    )

    lazy var dataBuilder = makeOnrampBaseDataBuilder(
        onrampRepository: dependencies.repository,
        onrampDataRepository: dependencies.dataRepository,
        onrampRedirectingBuilder: OnrampRedirectingBuilder(
            io: (input: onrampModel, output: onrampModel),
            tokenItem: tokenItem,
            onrampManager: dependencies.manager
        )
    )

    init(
        sourceToken: SendSourceToken,
        parameters: PredefinedOnrampParameters,
        coordinatorSource: SendCoordinator.Source,
        baseDataBuilderFactory: SendBaseDataBuilderFactory,
        source: ExpressInteractorWalletModelWrapper
    ) {
        self.sourceToken = sourceToken
        self.parameters = parameters
        self.coordinatorSource = coordinatorSource
        self.baseDataBuilderFactory = baseDataBuilderFactory

        pendingExpressTransactionsManagerBuilder = .init(
            userWalletId: sourceToken.userWalletInfo.id.stringValue,
            tokenItem: sourceToken.tokenItem,
        )

        let expressDependenciesInput = ExpressDependenciesInput(userWalletInfo: sourceToken.userWalletInfo, source: source)
        expressDependenciesFactory = CommonExpressDependenciesFactory(input: expressDependenciesInput)
    }
}

// MARK: - SendGenericFlowFactory

extension OnrampFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let onramp = makeOnrampSummaryStep()
        let offersSelectorViewModel = OnrampOffersSelectorViewModel(
            tokenItem: tokenItem,
            analyticsLogger: analyticsLogger,
            input: onrampModel,
            output: onrampModel
        )

        let finish = makeSendFinishStep(
            onrampAmountCompactViewModel: OnrampAmountCompactViewModel(
                onrampAmountInput: onrampModel,
                onrampProvidersInput: onrampModel,
                tokenItem: tokenItem
            ),
            onrampStatusCompactViewModel: OnrampStatusCompactViewModel(
                input: onrampModel,
                pendingTransactionsManager: pendingExpressTransactionsManagerBuilder.makePendingExpressTransactionsManager(
                    expressAPIProvider: expressDependenciesFactory.expressAPIProvider
                )
            ),
            router: router
        )

        notificationManager.setupManager(with: onrampModel)

        // Logger setup
        analyticsLogger.setup(onrampProvidersInput: onrampModel)

        // If user already has saved country in the repository then the bottom sheet will not show
        // And we can show keyboard safely
        let shouldActivateKeyboard = dependencies.repository.preferenceCountry != nil

        let stepsManager = CommonOnrampStepsManager(
            onrampStep: onramp,
            offersSelectorViewModel: offersSelectorViewModel,
            finishStep: finish,
            summaryTitleProvider: OnrampSendSummaryTitleProvider(tokenItem: tokenItem),
            onrampBaseDataBuilder: dataBuilder,

            shouldActivateKeyboard: shouldActivateKeyboard,
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        onramp.set(router: stepsManager)
        onrampModel.router = stepsManager

        onrampModel.alertPresenter = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension OnrampFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: onrampModel, output: onrampModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSendAlertBuilder(),
            dataBuilder: dataBuilder,
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper(),
            tangemIconProvider: CommonTangemIconProvider(config: sourceToken.userWalletInfo.config)
        )
    }
}

// MARK: - OnrampAmountStepBuildable

extension OnrampFlowFactory: OnrampSummaryStepBuildable {
    var onrampIO: OnrampSummaryStepBuilder.IO {
        OnrampSummaryStepBuilder.IO(
            amountInput: onrampModel,
            amountOutput: onrampModel,
            output: onrampModel,
            providersInput: onrampModel,
            recentOnrampTransactionParametersFinder: onrampModel
        )
    }

    var onrampTypes: OnrampSummaryStepBuilder.Types {
        OnrampSummaryStepBuilder.Types(tokenItem: tokenItem)
    }

    var onrampDependencies: OnrampSummaryStepBuilder.Dependencies {
        OnrampSummaryStepBuilder.Dependencies(
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendFinishStepBuildable

extension OnrampFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: onrampModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(
            title: Localization.commonInProgress,
            tokenItem: tokenItem
        )
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
