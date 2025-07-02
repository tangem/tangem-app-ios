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
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let interactor = makeSendDestinationInteractor(io: io, receiveTokenInput: receiveTokenInput)

        let viewModel = SendNewDestinationViewModel(
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            router: router
        )

        let step = SendNewDestinationStep(viewModel: viewModel, interactor: interactor)

        let compact = SendNewDestinationCompactViewModel(input: io.input)

        let finish = SendDestinationCompactViewModel(input: io.input, addressTextViewHeightModel: .init())

        return (step: step, compact: compact, finish: finish)
    }
}

private extension SendNewDestinationStepBuilder {
    func makeSendDestinationInteractor(io: IO, receiveTokenInput: SendReceiveTokenInput) -> SendNewDestinationInteractor {
        CommonSendNewDestinationInteractor(
            input: io.input,
            output: io.output,
            receiveTokenInput: receiveTokenInput,
            dependenciesBuilder: builder.makeSendNewDestinationInteractorDependenciesProvider(),
        )
    }
}
