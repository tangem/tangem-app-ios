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
    typealias ReturnValue = (
        step: SendNewDestinationStep,
        externalUpdater: SendExternalDestinationUpdater,
        compact: SendNewDestinationCompactViewModel,
        finish: SendDestinationCompactViewModel
    )

    let interactorDependenciesProvider: SendNewDestinationInteractorDependenciesProvider
    let sendQRCodeService: any SendQRCodeService
    let analyticsLogger: any SendDestinationAnalyticsLogger

    func makeSendDestinationStep(
        io: IO,
        receiveTokenInput: SendReceiveTokenInput,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let interactorSaver = CommonSendNewDestinationInteractorSaver(input: io.input, output: io.output)
        let interactor = makeSendDestinationInteractor(
            io: io,
            receiveTokenInput: receiveTokenInput,
            interactorSaver: interactorSaver,
            analyticsLogger: analyticsLogger
        )

        let viewModel = SendNewDestinationViewModel(
            interactor: interactor,
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            router: router
        )

        let step = SendNewDestinationStep(
            viewModel: viewModel,
            interactor: interactor,
            interactorSaver: interactorSaver,
            analyticsLogger: analyticsLogger
        )
        let externalUpdater = SendExternalDestinationUpdater(viewModel: viewModel)
        let compact = SendNewDestinationCompactViewModel(input: io.input)
        let finish = SendDestinationCompactViewModel(input: io.input, addressTextViewHeightModel: .init())

        interactorSaver.updater = externalUpdater

        return (step: step, externalUpdater: externalUpdater, compact: compact, finish: finish)
    }
}

private extension SendNewDestinationStepBuilder {
    func makeSendDestinationInteractor(
        io: IO,
        receiveTokenInput: SendReceiveTokenInput,
        interactorSaver: any SendNewDestinationInteractorSaver,
        analyticsLogger: SendDestinationAnalyticsLogger
    ) -> SendNewDestinationInteractor {
        CommonSendNewDestinationInteractor(
            input: io.input,
            receiveTokenInput: receiveTokenInput,
            saver: interactorSaver,
            dependenciesBuilder: interactorDependenciesProvider,
        )
    }
}
