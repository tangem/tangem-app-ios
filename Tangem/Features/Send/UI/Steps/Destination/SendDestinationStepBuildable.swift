//
//  SendDestinationStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder.IO { get }
    var destinationDependencies: SendDestinationStepBuilder.Dependencies { get }
}

extension SendDestinationStepBuildable {
    func makeSendDestinationStep(router: any SendDestinationRoutable) -> SendDestinationStepBuilder.ReturnValue {
        SendDestinationStepBuilder.make(
            io: destinationIO,
            dependencies: destinationDependencies,
            router: router
        )
    }
}

enum SendDestinationStepBuilder {
    struct IO {
        let input: SendDestinationInput
        let output: SendDestinationOutput
        let receiveTokenInput: SendReceiveTokenInput
        let destinationAccountOutput: SendDestinationAccountOutput
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
            router: router,
            destinationAccountOutput: io.destinationAccountOutput
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
