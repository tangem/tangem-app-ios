//
//  SendDestinationStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendDestinationStepBuilder {
    typealias IO = (input: SendDestinationInput, output: SendDestinationOutput)
    typealias ReturnValue = (
        step: SendDestinationStep,
        externalUpdater: SendDestinationExternalUpdater,
        compact: SendDestinationCompactViewModel
    )

    let builder: SendDependenciesBuilder

    func makeSendDestinationStep(
        io: IO,
        receiveTokenInput: SendReceiveTokenInput,
        sendQRCodeService: SendQRCodeService,
        analyticsLogger: any SendDestinationAnalyticsLogger,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let interactorSaver = CommonSendDestinationInteractorSaver(input: io.input, output: io.output)
        let interactor = makeSendDestinationInteractor(
            io: io,
            receiveTokenInput: receiveTokenInput,
            interactorSaver: interactorSaver,
            analyticsLogger: analyticsLogger
        )

        let viewModel = SendDestinationViewModel(
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            router: router
        )

        let step = SendDestinationStep(
            viewModel: viewModel,
            interactor: interactor,
            interactorSaver: interactorSaver,
            analyticsLogger: analyticsLogger
        )
        let externalUpdater = SendDestinationExternalUpdater(viewModel: viewModel)
        let compact = SendDestinationCompactViewModel(input: io.input)

        interactorSaver.updater = externalUpdater

        return (step: step, externalUpdater: externalUpdater, compact: compact)
    }

    func makeSendDestinationCompactViewModel(input: SendDestinationInput) -> SendDestinationCompactViewModel {
        .init(input: input)
    }
}

private extension SendDestinationStepBuilder {
    func makeSendDestinationInteractor(
        io: IO,
        receiveTokenInput: SendReceiveTokenInput,
        interactorSaver: any SendDestinationInteractorSaver,
        analyticsLogger: SendDestinationAnalyticsLogger
    ) -> SendDestinationInteractor {
        CommonSendDestinationInteractor(
            input: io.input,
            receiveTokenInput: receiveTokenInput,
            saver: interactorSaver,
            dependenciesBuilder: builder.makeSendDestinationInteractorDependenciesProvider(
                analyticsLogger: analyticsLogger
            ),
        )
    }
}
