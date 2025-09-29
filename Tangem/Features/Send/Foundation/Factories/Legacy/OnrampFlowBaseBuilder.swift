//
//  OnrampFlowBaseBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

struct PredefinedOnrampParameters: Hashable {
    static let none = PredefinedOnrampParameters(amount: .none, preferredValues: .none)

    let amount: Decimal?
    let preferredValues: PreferredValues
}

struct OnrampFlowBaseBuilder {
    let walletModel: any WalletModel
    let source: SendCoordinator.Source
    let onrampAmountBuilder: OnrampAmountBuilder
    let onrampStepBuilder: OnrampStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(parameters: PredefinedOnrampParameters, router: SendRoutable) -> SendViewModel {
        let (onrampManager, onrampRepository, onrampDataRepository) = builder.makeOnrampDependencies(
            preferredValues: parameters.preferredValues
        )

        let analyticsLogger = builder.makeOnrampSendAnalyticsLogger(source: source)
        let onrampModel = builder.makeOnrampModel(
            onrampManager: onrampManager,
            onrampDataRepository: onrampDataRepository,
            onrampRepository: onrampRepository,
            analyticsLogger: analyticsLogger,
            predefinedValues: .init(amount: parameters.amount)
        )

        analyticsLogger.setup(onrampProvidersInput: onrampModel)

        let notificationManager = builder.makeOnrampNotificationManager(input: onrampModel, delegate: onrampModel)

        let providersBuilder = OnrampProvidersBuilder(
            io: (input: onrampModel, output: onrampModel),
            tokenItem: walletModel.tokenItem,
            paymentMethodsInput: onrampModel,
            analyticsLogger: analyticsLogger
        )

        let paymentMethodsBuilder = OnrampPaymentMethodsBuilder(
            io: (input: onrampModel, output: onrampModel),
            analyticsLogger: analyticsLogger
        )

        let onrampRedirectingBuilder = OnrampRedirectingBuilder(
            io: (input: onrampModel, output: onrampModel),
            tokenItem: walletModel.tokenItem,
            onrampManager: onrampManager
        )

        let (onrampAmountViewModel, _) = onrampAmountBuilder.makeOnrampAmountViewModel(
            io: (input: onrampModel, output: onrampModel),
            onrampProvidersInput: onrampModel,
            coordinator: router
        )

        let onrampProvidersCompactViewModel = providersBuilder.makeOnrampProvidersCompactViewModel()
        let onrampAmountCompactViewModel = onrampAmountBuilder.makeOnrampAmountCompactViewModel(
            onrampAmountInput: onrampModel,
            onrampProvidersInput: onrampModel
        )

        let onrampStatusCompactViewModel = OnrampStatusCompactViewModel(
            input: onrampModel,
            pendingTransactionsManager: builder.makePendingExpressTransactionsManager()
        )

        let onramp = onrampStepBuilder.makeOnrampStep(
            io: (input: onrampModel, output: onrampModel),
            providersInput: onrampModel,
            onrampAmountViewModel: onrampAmountViewModel,
            onrampProvidersCompactViewModel: onrampProvidersCompactViewModel,
            notificationManager: notificationManager
        )

        let finish = SendFinishStepBuilder.make(
            io: .init(input: onrampModel),
            types: .init(tokenItem: walletModel.tokenItem),
            dependencies: .init(analyticsLogger: analyticsLogger),
            sendAmountCompactViewModel: .none,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: .none,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel,
            router: router
        )

        let stepsManager = CommonOnrampStepsManager(
            onrampStep: onramp.step,
            finishStep: finish,
            summaryTitleProvider: builder.makeOnrampSummaryTitleProvider(),
            // If user already has saved country in the repository then the bottom sheet will not show
            // And we can show keyboard safely
            shouldActivateKeyboard: onrampRepository.preferenceCountry != nil
        )

        let dataBuilder = builder.makeOnrampBaseDataBuilder(
            onrampRepository: onrampRepository,
            onrampDataRepository: onrampDataRepository,
            providersBuilder: providersBuilder,
            paymentMethodsBuilder: paymentMethodsBuilder,
            onrampRedirectingBuilder: onrampRedirectingBuilder
        )

        let interactor = CommonSendBaseInteractor(input: onrampModel, output: onrampModel)
        let viewModel = SendViewModel(
            interactor: interactor,
            stepsManager: stepsManager,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: dataBuilder,
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: builder.makeBlockchainSDKNotificationMapper(),
            coordinator: router
        )

        stepsManager.set(output: viewModel)

        onrampProvidersCompactViewModel.router = viewModel
        onramp.step.set(router: viewModel)

        onrampModel.router = viewModel
        onrampModel.alertPresenter = viewModel

        return viewModel
    }
}
