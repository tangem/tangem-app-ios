//
//  OnrampFlowBaseBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampFlowBaseBuilder {
    let userWalletModel: UserWalletModel
    let walletModel: WalletModel
    let source: SendCoordinator.Source
    let onrampAmountBuilder: OnrampAmountBuilder
    let onrampStepBuilder: OnrampStepBuilder
    let sendFinishStepBuilder: SendFinishStepBuilder
    let builder: SendDependenciesBuilder

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let (onrampManager, onrampRepository, onrampDataRepository) = builder.makeOnrampDependencies(
            userWalletId: userWalletModel.userWalletId.stringValue
        )

        let onrampModel = builder.makeOnrampModel(
            onrampManager: onrampManager,
            onrampDataRepository: onrampDataRepository,
            onrampRepository: onrampRepository
        )
        let notificationManager = builder.makeOnrampNotificationManager(input: onrampModel, delegate: onrampModel)
        let sendFinishAnalyticsLogger = builder.makeOnrampFinishAnalyticsLogger(onrampProvidersInput: onrampModel)

        let providersBuilder = OnrampProvidersBuilder(
            io: (input: onrampModel, output: onrampModel),
            tokenItem: walletModel.tokenItem,
            paymentMethodsInput: onrampModel
        )

        let paymentMethodsBuilder = OnrampPaymentMethodsBuilder(
            io: (input: onrampModel, output: onrampModel)
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

        let onramp = onrampStepBuilder.makeOnrampStep(
            io: (input: onrampModel, output: onrampModel),
            providersInput: onrampModel,
            onrampAmountViewModel: onrampAmountViewModel,
            onrampProvidersCompactViewModel: onrampProvidersCompactViewModel,
            notificationManager: notificationManager
        )

        let finish = sendFinishStepBuilder.makeSendFinishStep(
            input: onrampModel,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendDestinationCompactViewModel: .none,
            sendAmountCompactViewModel: .none,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            stakingValidatorsCompactViewModel: .none,
            sendFeeCompactViewModel: .none,
            onrampStatusCompactViewModel: .init()
        )

        let stepsManager = CommonOnrampStepsManager(
            onrampStep: onramp.step,
            finishStep: finish,
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
            userWalletModel: userWalletModel,
            alertBuilder: builder.makeSendAlertBuilder(),
            dataBuilder: dataBuilder,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            source: source,
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
