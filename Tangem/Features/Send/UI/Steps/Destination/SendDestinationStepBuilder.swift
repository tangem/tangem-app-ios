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
        let interactor = CommonSendDestinationInteractor(
            input: io.input,
            receiveTokenInput: receiveTokenInput,
            saver: interactorSaver,
            dependenciesBuilder: builder.makeSendDestinationInteractorDependenciesProvider(
                analyticsLogger: analyticsLogger
            ),
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

extension SendDestinationStepBuilder {
    protocol DataProvider {
        func makeSendDestinationInteractorDependenciesProvider(analyticsLogger: any SendDestinationAnalyticsLogger) -> SendDestinationInteractorDependenciesProvider
    }
}

import Foundation
import BlockchainSdk

enum SendDestinationStepBuilder2 {
    struct IO {
        let input: SendDestinationInput
        let output: SendDestinationOutput
        let receiveTokenInput: SendReceiveTokenInput
    }

    struct Dependencies {
        let sendQRCodeService: any SendQRCodeService
        let analyticsLogger: any SendDestinationAnalyticsLogger
        let destinationInteractorDependenciesProvider: SendDestinationInteractorDependenciesProvider
    }

    typealias ReturnValue = (
        step: SendDestinationStep,
        externalUpdater: SendDestinationExternalUpdater,
        compact: SendDestinationCompactViewModel
    )

    static func make(
        io: IO,
        dependencies: Dependencies,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let interactorSaver = CommonSendDestinationInteractorSaver(input: io.input, output: io.output)
        let interactor = CommonSendDestinationInteractor(
            input: io.input,
            receiveTokenInput: io.receiveTokenInput,
            saver: interactorSaver,
            dependenciesBuilder: dependencies.destinationInteractorDependenciesProvider
        )

        let viewModel = SendDestinationViewModel(
            interactor: interactor,
            sendQRCodeService: dependencies.sendQRCodeService,
            analyticsLogger: dependencies.analyticsLogger,
            router: router
        )

        let step = SendDestinationStep(
            viewModel: viewModel,
            interactor: interactor,
            interactorSaver: interactorSaver,
            analyticsLogger: dependencies.analyticsLogger
        )

        let externalUpdater = SendDestinationExternalUpdater(viewModel: viewModel)
        let compact = SendDestinationCompactViewModel(input: io.input)

        interactorSaver.updater = externalUpdater

        return (step: step, externalUpdater: externalUpdater, compact: compact)
    }
}
