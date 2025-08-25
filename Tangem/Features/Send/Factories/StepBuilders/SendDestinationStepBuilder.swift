//
//  SendDestinationStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendDestinationStepBuilder {
    typealias IO = (input: SendDestinationInput, output: SendDestinationOutput)
    typealias ReturnValue = (step: SendDestinationStep, interactor: SendDestinationInteractor, compact: SendDestinationCompactViewModel)

    let walletModel: any WalletModel
    let builder: SendDependenciesBuilder

    func makeSendDestinationStep(
        io: IO,
        sendFeeProvider: any SendFeeProvider,
        sendQRCodeService: SendQRCodeService,
        analyticsLogger: SendDestinationAnalyticsLogger,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let addressTextViewHeightModel = AddressTextViewHeightModel()
        let interactor = makeSendDestinationInteractor(io: io, analyticsLogger: analyticsLogger)

        let viewModel = makeSendDestinationViewModel(
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        let step = SendDestinationStep(
            viewModel: viewModel,
            interactor: interactor,
            sendFeeProvider: sendFeeProvider,
            analyticsLogger: analyticsLogger
        )

        let compact = makeSendDestinationCompactViewModel(
            input: io.input,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        return (step: step, interactor: interactor, compact: compact)
    }

    func makeSendDestinationCompactViewModel(
        input: SendDestinationInput,
        addressTextViewHeightModel: AddressTextViewHeightModel = .init()
    ) -> SendDestinationCompactViewModel {
        .init(input: input, addressTextViewHeightModel: addressTextViewHeightModel)
    }
}

private extension SendDestinationStepBuilder {
    func makeSendDestinationViewModel(
        interactor: SendDestinationInteractor,
        sendQRCodeService: SendQRCodeService,
        analyticsLogger: any SendDestinationAnalyticsLogger,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        router: SendDestinationRoutable
    ) -> SendDestinationViewModel {
        let tokenItem = walletModel.tokenItem
        let suggestedWallets = builder.makeSuggestedWallets()
        let additionalFieldType = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain)

        let settings = SendDestinationViewModel.Settings(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets
        )

        let viewModel = SendDestinationViewModel(
            settings: settings,
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        return viewModel
    }

    func makeSendDestinationInteractor(io: IO, analyticsLogger: SendDestinationAnalyticsLogger) -> SendDestinationInteractor {
        CommonSendDestinationInteractor(
            input: io.input,
            output: io.output,
            validator: builder.makeSendDestinationValidator(),
            transactionHistoryProvider: builder.makeSendDestinationTransactionHistoryProvider(),
            addressResolver: builder.makeAddressResolver(),
            additionalFieldType: .type(for: walletModel.tokenItem.blockchain),
            parametersBuilder: builder.makeSendTransactionParametersBuilder(),
            analyticsLogger: analyticsLogger
        )
    }
}
