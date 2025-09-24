//
//  SendNewAmountStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct SendNewAmountStepBuilder {
    typealias SourceIO = (input: SendSourceTokenInput, output: SendSourceTokenOutput)
    typealias ReceiveIO = (input: SendReceiveTokenInput, output: SendReceiveTokenOutput)

    typealias SourceAmountIO = (input: SendSourceTokenAmountInput, output: SendSourceTokenAmountOutput)
    typealias ReceiveAmountIO = (input: SendReceiveTokenAmountInput, output: SendReceiveTokenAmountOutput)

    typealias ReturnValue = (step: SendNewAmountStep, amountUpdater: SendAmountExternalUpdater, compact: SendNewAmountCompactViewModel, finish: SendNewAmountFinishViewModel)

    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let builder: SendDependenciesBuilder

    func makeSendNewAmountStep(
        sourceIO: SourceIO,
        sourceAmountIO: SourceAmountIO,
        receiveIO: ReceiveIO,
        receiveAmountIO: ReceiveAmountIO,
        swapProvidersInput: SendSwapProvidersInput,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        notificationService: SendAmountNotificationService?,
        analyticsLogger: any SendAnalyticsLogger
    ) -> ReturnValue {
        let interactorSaver = CommonSendNewAmountInteractorSaver(
            sourceTokenAmountInput: sourceAmountIO.input,
            sourceTokenAmountOutput: sourceAmountIO.output,
            receiveTokenInput: receiveIO.input,
            receiveTokenOutput: receiveIO.output
        )

        let interactor = CommonSendNewAmountInteractor(
            sourceTokenInput: sourceIO.input,
            sourceTokenAmountInput: sourceAmountIO.input,
            receiveTokenInput: receiveIO.input,
            receiveTokenOutput: receiveIO.output,
            receiveTokenAmountInput: receiveAmountIO.input,
            validator: sendAmountValidator,
            amountModifier: amountModifier,
            notificationService: notificationService,
            saver: interactorSaver,
            type: .crypto
        )

        let viewModel = SendNewAmountViewModel(
            sourceToken: sourceIO.input.sourceToken,
            interactor: interactor,
            analyticsLogger: analyticsLogger
        )

        let step = SendNewAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            interactorSaver: interactorSaver,
            analyticsLogger: analyticsLogger
        )

        let compact = SendNewAmountCompactViewModel(
            sourceTokenInput: sourceIO.input,
            sourceTokenAmountInput: sourceAmountIO.input,
            receiveTokenInput: receiveIO.input,
            receiveTokenAmountInput: receiveAmountIO.input,
            swapProvidersInput: swapProvidersInput
        )

        let amountUpdater = SendAmountExternalUpdater(viewModel: viewModel, interactor: interactor)
        let finish = SendNewAmountFinishViewModel(
            sourceTokenInput: sourceIO.input,
            sourceTokenAmountInput: sourceAmountIO.input,
            receiveTokenInput: receiveIO.input,
            receiveTokenAmountInput: receiveAmountIO.input,
            swapProvidersInput: swapProvidersInput,
        )

        interactorSaver.updater = amountUpdater

        return (step: step, amountUpdater: amountUpdater, compact: compact, finish: finish)
    }

    func makeSendNewAmountCompactViewModel(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        swapProvidersInput: SendSwapProvidersInput,
    ) -> SendNewAmountCompactViewModel {
        SendNewAmountCompactViewModel(
            sourceTokenInput: sourceTokenInput,
            sourceTokenAmountInput: sourceTokenAmountInput,
            receiveTokenInput: receiveTokenInput,
            receiveTokenAmountInput: receiveTokenAmountInput,
            swapProvidersInput: swapProvidersInput,
        )
    }

    func makeSendNewAmountFinishViewModel(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        swapProvidersInput: SendSwapProvidersInput,
    ) -> SendNewAmountFinishViewModel {
        SendNewAmountFinishViewModel(
            sourceTokenInput: sourceTokenInput,
            sourceTokenAmountInput: sourceTokenAmountInput,
            receiveTokenInput: receiveTokenInput,
            receiveTokenAmountInput: receiveTokenAmountInput,
            swapProvidersInput: swapProvidersInput,
        )
    }
}


import Foundation
import TangemExpress

enum SendNewAmountStepBuilder2 {
    struct IO {
        typealias SourceIO = (input: SendSourceTokenInput, output: SendSourceTokenOutput)
        typealias ReceiveIO = (input: SendReceiveTokenInput, output: SendReceiveTokenOutput)

        typealias SourceAmountIO = (input: SendSourceTokenAmountInput, output: SendSourceTokenAmountOutput)
        typealias ReceiveAmountIO = (input: SendReceiveTokenAmountInput, output: SendReceiveTokenAmountOutput)

        let sourceIO: SourceIO
        let sourceAmountIO: SourceAmountIO
        let receiveIO: ReceiveIO
        let receiveAmountIO: ReceiveAmountIO
        let swapProvidersInput: SendSwapProvidersInput
    }

    struct Dependencies {
        let sendAmountValidator: any SendAmountValidator
        let amountModifier: (any SendAmountModifier)?
        let notificationService: (any SendAmountNotificationService)?
        let analyticsLogger: any SendAnalyticsLogger
    }

    typealias ReturnValue = (step: SendNewAmountStep, amountUpdater: SendAmountExternalUpdater, compact: SendNewAmountCompactViewModel, finish: SendNewAmountFinishViewModel)

    static func make(io: IO, dependencies: Dependencies) -> ReturnValue {
        let interactorSaver = CommonSendNewAmountInteractorSaver(
            sourceTokenAmountInput: io.sourceAmountIO.input,
            sourceTokenAmountOutput: io.sourceAmountIO.output,
            receiveTokenInput: io.receiveIO.input,
            receiveTokenOutput: io.receiveIO.output
        )

        let interactor = CommonSendNewAmountInteractor(
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceAmountIO.input,
            receiveTokenInput: io.receiveIO.input,
            receiveTokenOutput: io.receiveIO.output,
            receiveTokenAmountInput: io.receiveAmountIO.input,
            validator: dependencies.sendAmountValidator,
            amountModifier: dependencies.amountModifier,
            notificationService: dependencies.notificationService,
            saver: interactorSaver,
            type: .crypto
        )

        let viewModel = SendNewAmountViewModel(
            sourceToken: io.sourceIO.input.sourceToken,
            interactor: interactor,
            analyticsLogger: dependencies.analyticsLogger
        )

        let step = SendNewAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            interactorSaver: interactorSaver,
            analyticsLogger: dependencies.analyticsLogger
        )

        let compact = SendNewAmountCompactViewModel(
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceAmountIO.input,
            receiveTokenInput: io.receiveIO.input,
            receiveTokenAmountInput: io.receiveAmountIO.input,
            swapProvidersInput: io.swapProvidersInput
        )

        let amountUpdater = SendAmountExternalUpdater(viewModel: viewModel, interactor: interactor)
        let finish = SendNewAmountFinishViewModel(
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceAmountIO.input,
            receiveTokenInput: io.receiveIO.input,
            receiveTokenAmountInput: io.receiveAmountIO.input,
            swapProvidersInput: io.swapProvidersInput,
        )

        interactorSaver.updater = amountUpdater

        return (step: step, amountUpdater: amountUpdater, compact: compact, finish: finish)
    }

    static func makeSendNewAmountCompactViewModel(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        swapProvidersInput: SendSwapProvidersInput,
    ) -> SendNewAmountCompactViewModel {
        SendNewAmountCompactViewModel(
            sourceTokenInput: sourceTokenInput,
            sourceTokenAmountInput: sourceTokenAmountInput,
            receiveTokenInput: receiveTokenInput,
            receiveTokenAmountInput: receiveTokenAmountInput,
            swapProvidersInput: swapProvidersInput,
        )
    }

    static func makeSendNewAmountFinishViewModel(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        swapProvidersInput: SendSwapProvidersInput,
    ) -> SendNewAmountFinishViewModel {
        SendNewAmountFinishViewModel(
            sourceTokenInput: sourceTokenInput,
            sourceTokenAmountInput: sourceTokenAmountInput,
            receiveTokenInput: receiveTokenInput,
            receiveTokenAmountInput: receiveTokenAmountInput,
            swapProvidersInput: swapProvidersInput,
        )
    }
}
