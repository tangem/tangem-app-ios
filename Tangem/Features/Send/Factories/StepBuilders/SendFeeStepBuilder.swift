//
//  SendFeeStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFeeStepBuilder {
    typealias IO = (input: SendFeeInput, output: SendFeeOutput)
    typealias ReturnValue = (step: SendFeeStep, compact: SendFeeCompactViewModel)

    let walletModel: any WalletModel
    let builder: SendDependenciesBuilder

    func makeFeeSendStep(
        io: IO,
        notificationManager: NotificationManager,
        analyticsLogger: any SendFeeAnalyticsLogger,
        sendFeeProvider: SendFeeProvider,
        customFeeService: CustomFeeService?,
        router: SendFeeRoutable
    ) -> ReturnValue {
        let interactor = makeSendFeeInteractor(
            io: io,
            customFeeService: customFeeService,
            sendFeeProvider: sendFeeProvider
        )

        let viewModel = makeSendFeeViewModel(
            sendFeeInteractor: interactor,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            router: router
        )

        let step = SendFeeStep(
            viewModel: viewModel,
            feeProvider: sendFeeProvider,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger
        )

        let compact = makeSendFeeCompactViewModel(input: io.input)

        return (step: step, compact: compact)
    }

    func makeSendFeeCompactViewModel(input: SendFeeInput) -> SendFeeCompactViewModel {
        .init(
            input: input,
            feeTokenItem: walletModel.feeTokenItem,
            isFeeApproximate: builder.isFeeApproximate()
        )
    }
}

// MARK: - Private

private extension SendFeeStepBuilder {
    func makeSendFeeViewModel(
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: NotificationManager,
        analyticsLogger: any SendFeeAnalyticsLogger,
        router: SendFeeRoutable
    ) -> SendFeeViewModel {
        let settings = SendFeeViewModel.Settings(
            feeTokenItem: walletModel.feeTokenItem,
            tokenItem: walletModel.tokenItem
        )

        return SendFeeViewModel(
            settings: settings,
            interactor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: router,
            analyticsLogger: analyticsLogger
        )
    }

    private func makeSendFeeInteractor(io: IO, customFeeService: CustomFeeService?, sendFeeProvider: SendFeeProvider) -> SendFeeInteractor {
        let interactor = CommonSendFeeInteractor(
            input: io.input,
            output: io.output,
            provider: sendFeeProvider,
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService
        )

        customFeeService?.setup(output: interactor)
        return interactor
    }
}
