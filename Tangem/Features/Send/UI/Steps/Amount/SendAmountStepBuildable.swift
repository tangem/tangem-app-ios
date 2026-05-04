//
//  SendAmountStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress

protocol SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO { get }
    var amountTypes: SendAmountStepBuilder.Types { get }
    var amountDependencies: SendAmountStepBuilder.Dependencies { get }
}

extension SendAmountStepBuildable {
    func makeSendAmountStep() -> SendAmountStepBuilder.ReturnValue {
        SendAmountStepBuilder.make(io: amountIO, types: amountTypes, dependencies: amountDependencies)
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

    struct Types {
        let initialSourceToken: SendSourceToken
        let flowActionType: SendFlowActionType
        let isSwapAwareFlow: Bool

        init(
            initialSourceToken: SendSourceToken,
            flowActionType: SendFlowActionType,
            isSwapAwareFlow: Bool = false
        ) {
            self.initialSourceToken = initialSourceToken
            self.flowActionType = flowActionType
            self.isSwapAwareFlow = isSwapAwareFlow
        }
    }

    struct Dependencies {
        let sendAmountValidator: any SendAmountValidator
        let amountModifier: (any SendAmountModifier)?
        let notificationService: (any SendAmountNotificationService)?
        let analyticsLogger: any SendAmountAnalyticsLogger
        let providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>?
        let currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never>?

        init(
            sendAmountValidator: any SendAmountValidator,
            amountModifier: (any SendAmountModifier)?,
            notificationService: (any SendAmountNotificationService)?,
            analyticsLogger: any SendAmountAnalyticsLogger,
            providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>? = nil,
            currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never>? = nil
        ) {
            self.sendAmountValidator = sendAmountValidator
            self.amountModifier = amountModifier
            self.notificationService = notificationService
            self.analyticsLogger = analyticsLogger
            self.providerRateTypesPublisher = providerRateTypesPublisher
            self.currentRateTypePublisher = currentRateTypePublisher
        }
    }

    typealias ReturnValue = (step: SendAmountStep, amountUpdater: SendAmountExternalUpdater, compact: SendAmountCompactViewModel, finish: SendAmountFinishViewModel)

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
            amountModifier: dependencies.amountModifier,
            notificationService: dependencies.notificationService,
            saver: interactorSaver
        )

        let viewModel = SendAmountViewModel(
            sourceToken: types.initialSourceToken,
            flowActionType: types.flowActionType,
            interactor: interactor,
            analyticsLogger: dependencies.analyticsLogger,
            providerRateTypesPublisher: dependencies.providerRateTypesPublisher,
            currentRateTypePublisher: dependencies.currentRateTypePublisher
        )

        let step = SendAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            interactorSaver: interactorSaver,
            analyticsLogger: dependencies.analyticsLogger
        )

        let compact = SendAmountCompactViewModel(
            initialSourceToken: types.initialSourceToken,
            actionType: types.flowActionType,
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceAmountIO.input,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenAmountInput: io.receiveAmountIO?.input,
            swapProvidersInput: io.swapProvidersInput,
            isReceiveAmountApproximatePublisher: viewModel.isReceiveAmountApproximatePublisher
        )

        let amountUpdater = SendAmountExternalUpdater(viewModel: viewModel, interactor: interactor)
        let finish = SendAmountFinishViewModel(
            flowActionType: types.flowActionType,
            isSwapAwareFlow: types.isSwapAwareFlow,
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
