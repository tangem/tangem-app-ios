//
//  OnrampFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import struct TangemUI.TokenIconInfo

class OnrampFlowFactory: OnrampFlowBaseDependenciesFactory {
    let userWalletInfo: SendWalletInfo
    let parameters: PredefinedOnrampParameters
    let source: SendCoordinator.Source

    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let defaultAddressString: String

    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let walletModelBalancesProvider: WalletModelBalancesProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let pendingExpressTransactionsManagerBuilder: PendingExpressTransactionsManagerBuilder
    let expressDependenciesFactory: ExpressDependenciesFactory

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
        providersBuilder: OnrampProvidersBuilder(
            io: (input: onrampModel, output: onrampModel),
            tokenItem: tokenItem,
            paymentMethodsInput: onrampModel,
            analyticsLogger: analyticsLogger
        ),
        paymentMethodsBuilder: OnrampPaymentMethodsBuilder(
            io: (input: onrampModel, output: onrampModel),
            analyticsLogger: analyticsLogger
        ),
        onrampRedirectingBuilder: OnrampRedirectingBuilder(
            io: (input: onrampModel, output: onrampModel),
            tokenItem: tokenItem,
            onrampManager: dependencies.manager
        )
    )

    init(
        userWalletInfo: SendWalletInfo,
        parameters: PredefinedOnrampParameters,
        source: SendCoordinator.Source,
        walletModel: any WalletModel,
        expressInput: CommonExpressDependenciesFactory.Input,
    ) {
        self.userWalletInfo = userWalletInfo
        self.parameters = parameters
        self.source = source

        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )
        defaultAddressString = walletModel.defaultAddressString

        walletModelDependenciesProvider = walletModel
        walletModelBalancesProvider = walletModel
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
            walletModel: walletModel
        )
        expressDependenciesFactory = CommonExpressDependenciesFactory(
            input: expressInput,
            initialWallet: walletModel.asExpressInteractorWallet,
            destinationWallet: .none,
            // We support only `CEX` in `Send With Swap` flow
            supportedProviderTypes: [.cex],
            operationType: .swapAndSend
        )
    }
}

// MARK: - SendGenericFlowFactory

extension OnrampFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let onramp = makeOnrampStep(router: router)
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

        let stepsManager = CommonNewOnrampStepsManager(
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

// MARK: - NewOnrampStepBuildable

extension OnrampFlowFactory: NewOnrampStepBuildable {
    var onrampIO: NewOnrampStepBuilder.IO {
        NewOnrampStepBuilder.IO(
            input: onrampModel,
            output: onrampModel,
            amountInput: onrampModel,
            amountOutput: onrampModel,
            providersInput: onrampModel,
            recentOnrampTransactionParametersFinder: onrampModel
        )
    }

    var onrampTypes: NewOnrampStepBuilder.Types {
        NewOnrampStepBuilder.Types(tokenItem: tokenItem)
    }

    var onrampDependencies: NewOnrampStepBuilder.Dependencies {
        NewOnrampStepBuilder.Dependencies(
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
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
