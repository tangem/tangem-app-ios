//
//  SendNewDestinationStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendNewDestinationStepBuilder {
    typealias IO = (input: SendDestinationInput, output: SendDestinationOutput)
    typealias ReturnValue = (step: SendNewDestinationStep, compact: SendNewDestinationCompactViewModel, finish: SendDestinationCompactViewModel)

    let builder: SendDependenciesBuilder

    func makeSendDestinationStep(
        io: IO,
        receiveTokenInput: SendReceiveTokenInput,
        sendQRCodeService: SendQRCodeService,
        analyticsLogger: any SendDestinationAnalyticsLogger,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let interactor = makeSendDestinationInteractor(
            io: io,
            receiveTokenInput: receiveTokenInput,
            analyticsLogger: analyticsLogger
        )

        let viewModel = SendNewDestinationViewModel(
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            router: router
        )

        let step = SendNewDestinationStep(viewModel: viewModel, interactor: interactor, analyticsLogger: analyticsLogger)
        let compact = SendNewDestinationCompactViewModel(input: io.input)
        let finish = SendDestinationCompactViewModel(input: io.input, addressTextViewHeightModel: .init())

        return (step: step, compact: compact, finish: finish)
    }
}

private extension SendNewDestinationStepBuilder {
    func makeSendDestinationInteractor(
        io: IO,
        receiveTokenInput: SendReceiveTokenInput,
        analyticsLogger: SendDestinationAnalyticsLogger
    ) -> SendNewDestinationInteractor {
        CommonSendNewDestinationInteractor(
            input: io.input,
            output: io.output,
            receiveTokenInput: receiveTokenInput,
            dependenciesBuilder: builder.makeSendNewDestinationInteractorDependenciesProvider(
                analyticsLogger: analyticsLogger
            ),
        )
    }
}
