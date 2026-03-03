//
//  SwapAmountStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapAmountStepBuildable {
    var amountIO: SwapAmountStepBuilder.IO { get }
    var amountTypes: SwapAmountStepBuilder.Types { get }
    var amountDependencies: SwapAmountStepBuilder.Dependencies { get }
}

extension SwapAmountStepBuildable {
    func makeSwapAmountStep() -> SwapAmountStepBuilder.ReturnValue {
        SwapAmountStepBuilder.make(io: amountIO, types: amountTypes, dependencies: amountDependencies)
    }
}

enum SwapAmountStepBuilder {
    struct IO {
        let sourceIO: (input: SendSourceTokenInput, output: SendSourceTokenOutput)
        let sourceAmountIO: (input: SendSourceTokenAmountInput, output: SendSourceTokenAmountOutput)
        let receiveIO: (input: SendReceiveTokenInput, output: SendReceiveTokenOutput)?
        let receiveAmountIO: (input: SendReceiveTokenAmountInput, output: SendReceiveTokenAmountOutput)?
        let swapProvidersInput: SendSwapProvidersInput?
        let stateProvider: any SwapModelStateProvider

        init(
            sourceIO: (input: SendSourceTokenInput, output: SendSourceTokenOutput),
            sourceAmountIO: (input: SendSourceTokenAmountInput, output: SendSourceTokenAmountOutput),
            receiveIO: (input: SendReceiveTokenInput, output: SendReceiveTokenOutput)? = nil,
            receiveAmountIO: (input: SendReceiveTokenAmountInput, output: SendReceiveTokenAmountOutput)? = nil,
            swapProvidersInput: SendSwapProvidersInput? = nil,
            stateProvider: any SwapModelStateProvider
        ) {
            self.sourceIO = sourceIO
            self.sourceAmountIO = sourceAmountIO
            self.receiveIO = receiveIO
            self.receiveAmountIO = receiveAmountIO
            self.swapProvidersInput = swapProvidersInput
            self.stateProvider = stateProvider
        }
    }

    struct Types {
        let initialTokenItem: TokenItem
    }

    struct Dependencies {
        let sendAmountValidator: any SendAmountValidator
        let analyticsLogger: any SendAmountAnalyticsLogger
        let isFixedRateMode: Bool

        init(
            sendAmountValidator: any SendAmountValidator,
            analyticsLogger: any SendAmountAnalyticsLogger,
            isFixedRateMode: Bool = false
        ) {
            self.sendAmountValidator = sendAmountValidator
            self.analyticsLogger = analyticsLogger
            self.isFixedRateMode = isFixedRateMode
        }
    }

    typealias ReturnValue = (step: SwapAmountStep, viewModel: SwapAmountViewModel, amountUpdater: SendAmountExternalUpdater, finish: SendAmountFinishViewModel)

    static func make(io: IO, types: Types, dependencies: Dependencies) -> ReturnValue {
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
            receiveTokenAmountOutput: io.receiveAmountIO?.output,
            validator: dependencies.sendAmountValidator,
            amountModifier: .none,
            notificationService: .none,
            saver: interactorSaver,
            type: .crypto
        )

        let viewModel = SwapAmountViewModel(
            initialTokenItem: types.initialTokenItem,
            interactor: interactor,
            stateProvider: io.stateProvider,
            sourceTokenInput: io.sourceIO.input,
            receiveTokenInput: io.receiveIO?.input,
            isFixedRateMode: dependencies.isFixedRateMode
        )

        let finish = SendAmountFinishViewModel(
            flowActionType: .swap,
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceAmountIO.input,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenAmountInput: io.receiveAmountIO?.input,
            swapProvidersInput: io.swapProvidersInput,
        )

        let step = SwapAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            interactorSaver: interactorSaver,
            analyticsLogger: dependencies.analyticsLogger
        )

        let amountUpdater = SendAmountExternalUpdater(viewModel: viewModel, interactor: interactor)
        interactorSaver.updater = amountUpdater

        return (step: step, viewModel: viewModel, amountUpdater: amountUpdater, finish: finish)
    }
}
