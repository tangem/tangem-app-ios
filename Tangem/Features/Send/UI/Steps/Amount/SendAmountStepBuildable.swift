//
//  SendAmountStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO { get }
    var amountDependencies: SendAmountStepBuilder.Dependencies { get }
}

extension SendAmountStepBuildable {
    func makeSendAmountStep() -> SendAmountStepBuilder.ReturnValue {
        SendAmountStepBuilder.make(io: amountIO, dependencies: amountDependencies)
    }
}

enum SendAmountStepBuilder {
    struct IO {
        let sourceIO: (input: SendSourceTokenInput, output: SendSourceTokenOutput)
        let sourceAmountIO: (input: SendSourceTokenAmountInput, output: SendSourceTokenAmountOutput)
        let receiveIO: (input: SendReceiveTokenInput, output: SendReceiveTokenOutput)?
        let receiveAmountIO: (input: SendReceiveTokenAmountInput, output: SendReceiveTokenAmountOutput)?
        let swapProvidersInput: SendSwapProvidersInput?

        init(
            sourceIO: (input: SendSourceTokenInput, output: SendSourceTokenOutput),
            sourceAmountIO: (input: SendSourceTokenAmountInput, output: SendSourceTokenAmountOutput),
            receiveIO: (input: SendReceiveTokenInput, output: SendReceiveTokenOutput)? = nil,
            receiveAmountIO: (input: SendReceiveTokenAmountInput, output: SendReceiveTokenAmountOutput)? = nil,
            swapProvidersInput: SendSwapProvidersInput? = nil
        ) {
            self.sourceIO = sourceIO
            self.sourceAmountIO = sourceAmountIO
            self.receiveIO = receiveIO
            self.receiveAmountIO = receiveAmountIO
            self.swapProvidersInput = swapProvidersInput
        }
    }

    struct Dependencies {
        let sendAmountValidator: any SendAmountValidator
        let amountModifier: (any SendAmountModifier)?
        let notificationService: (any SendAmountNotificationService)?
        let analyticsLogger: any SendAmountAnalyticsLogger
    }

    typealias ReturnValue = (step: SendAmountStep, amountUpdater: SendAmountExternalUpdater, compact: SendAmountCompactViewModel, finish: SendAmountFinishViewModel)

    static func make(io: IO, dependencies: Dependencies) -> ReturnValue {
        let interactorSaver = CommonSendAmountInteractorSaver(
            sourceTokenAmountInput: io.sourceAmountIO.input,
            sourceTokenAmountOutput: io.sourceAmountIO.output,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenOutput: io.receiveIO?.output
        )

        let interactor = CommonSendAmountInteractor(
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceAmountIO.input,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenOutput: io.receiveIO?.output,
            receiveTokenAmountInput: io.receiveAmountIO?.input,
            validator: dependencies.sendAmountValidator,
            amountModifier: dependencies.amountModifier,
            notificationService: dependencies.notificationService,
            saver: interactorSaver,
            type: .crypto
        )

        let viewModel = SendAmountViewModel(
            sourceToken: io.sourceIO.input.sourceToken,
            interactor: interactor,
            analyticsLogger: dependencies.analyticsLogger
        )

        let step = SendAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            interactorSaver: interactorSaver,
            analyticsLogger: dependencies.analyticsLogger
        )

        let compact = SendAmountCompactViewModel(
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceAmountIO.input,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenAmountInput: io.receiveAmountIO?.input,
            swapProvidersInput: io.swapProvidersInput
        )

        let amountUpdater = SendAmountExternalUpdater(viewModel: viewModel, interactor: interactor)
        let finish = SendAmountFinishViewModel(
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceAmountIO.input,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenAmountInput: io.receiveAmountIO?.input,
            swapProvidersInput: io.swapProvidersInput,
        )

        interactorSaver.updater = amountUpdater

        return (step: step, amountUpdater: amountUpdater, compact: compact, finish: finish)
    }
}
