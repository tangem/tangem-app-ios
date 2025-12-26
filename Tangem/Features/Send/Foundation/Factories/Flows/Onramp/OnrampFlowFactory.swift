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
    let userWalletInfo: UserWalletInfo
    let parameters: PredefinedOnrampParameters
    let source: SendCoordinator.Source

    let tokenHeaderProvider: SendGenericTokenHeaderProvider
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let defaultAddressString: String

    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let pendingExpressTransactionsManagerBuilder: PendingExpressTransactionsManagerBuilder
    let expressDependenciesFactory: ExpressDependenciesFactory
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?

    lazy var dependencies = makeOnrampDependencies(
        preferredValues: parameters.preferredValues
    )

    lazy var analyticsLogger = makeOnrampSendAnalyticsLogger(source: source)

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
        userWalletInfo: UserWalletInfo,
        parameters: PredefinedOnrampParameters,
        source: SendCoordinator.Source,
        walletModel: any WalletModel
    ) {
        self.userWalletInfo = userWalletInfo
        self.parameters = parameters
        self.source = source

        tokenHeaderProvider = SendTokenHeaderProvider(
            userWalletInfo: userWalletInfo,
            account: walletModel.account,
            flowActionType: .onramp
        )
        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )
        defaultAddressString = walletModel.defaultAddressString

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
        pendingExpressTransactionsManagerBuilder = .init(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: walletModel.tokenItem,
        )

        let source = ExpressInteractorWalletModelWrapper(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            expressOperationType: .onramp
        )

        let expressDependenciesInput = ExpressDependenciesInput(userWalletInfo: userWalletInfo, source: source)
        expressDependenciesFactory = CommonExpressDependenciesFactory(input: expressDependenciesInput)

        accountModelAnalyticsProvider = walletModel.account
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
                pendingTransactionsManager: makePendingExpressTransactionsManager()
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
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper()
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
