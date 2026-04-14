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
        let sourceIO: (input: any SendSourceInput, output: any SendSourceOutput)
        let receiveIO: (input: any SendReceiveInput, output: any SendReceiveOutput)?
        let swapProvidersInput: SendSwapProvidersInput?

        init(
            sourceIO: (input: any SendSourceInput, output: any SendSourceOutput),
            receiveIO: (input: any SendReceiveInput, output: any SendReceiveOutput)? = nil,
            swapProvidersInput: SendSwapProvidersInput? = nil
        ) {
            self.sourceIO = sourceIO
            self.receiveIO = receiveIO
            self.swapProvidersInput = swapProvidersInput
        }
    }

    struct Types {
        let initialSourceToken: SendSourceToken
        let flowActionType: SendFlowActionType
    }

    struct Dependencies {
        let sendAmountValidator: any SendAmountValidator
        let amountModifier: (any SendAmountModifier)?
        let notificationService: (any SendAmountNotificationService)?
        let analyticsLogger: any SendAmountAnalyticsLogger
        let providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>?

        init(
            sendAmountValidator: any SendAmountValidator,
            amountModifier: (any SendAmountModifier)?,
            notificationService: (any SendAmountNotificationService)?,
            analyticsLogger: any SendAmountAnalyticsLogger,
            providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>? = nil
        ) {
            self.sendAmountValidator = sendAmountValidator
            self.amountModifier = amountModifier
            self.notificationService = notificationService
            self.analyticsLogger = analyticsLogger
            self.providerRateTypesPublisher = providerRateTypesPublisher
        }
    }

    typealias ReturnValue = (step: SendAmountStep, amountUpdater: SendAmountExternalUpdater, compact: SendAmountCompactViewModel, finish: SendAmountFinishViewModel)

    static func make(io: IO, types: Types, dependencies: Dependencies) -> ReturnValue {
        let interactorSaver = CommonSendAmountInteractorSaver(
            sourceTokenAmountInput: io.sourceIO.input,
            sourceTokenAmountOutput: io.sourceIO.output,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenOutput: io.receiveIO?.output
        )

        let interactor = CommonSendAmountInteractor(
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceIO.input,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenOutput: io.receiveIO?.output,
            receiveTokenAmountInput: io.receiveIO?.input,
            receiveTokenAmountOutput: io.receiveIO?.output,
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
            providerRateTypesPublisher: dependencies.providerRateTypesPublisher
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
            sourceTokenAmountInput: io.sourceIO.input,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenAmountInput: io.receiveIO?.input,
            swapProvidersInput: io.swapProvidersInput,
            isReceiveAmountApproximatePublisher: viewModel.isReceiveAmountApproximatePublisher
        )

        let amountUpdater = SendAmountExternalUpdater(viewModel: viewModel, interactor: interactor)
        let finish = SendAmountFinishViewModel(
            flowActionType: types.flowActionType,
            sourceTokenInput: io.sourceIO.input,
            sourceTokenAmountInput: io.sourceIO.input,
            receiveTokenInput: io.receiveIO?.input,
            receiveTokenAmountInput: io.receiveIO?.input,
            swapProvidersInput: io.swapProvidersInput,
        )

        interactorSaver.updater = amountUpdater

        return (step: step, amountUpdater: amountUpdater, compact: compact, finish: finish)
    }
}
