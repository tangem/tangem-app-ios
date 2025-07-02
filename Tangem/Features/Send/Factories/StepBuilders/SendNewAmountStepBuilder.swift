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

    typealias ReturnValue = (step: SendNewAmountStep, amountUpdater: SendExternalAmountUpdater, compact: SendNewAmountCompactViewModel, finish: SendTokenAmountCompactViewModel)

    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let builder: SendDependenciesBuilder

    func makeSendNewAmountStep(
        sourceIO: SourceIO,
        sourceAmountIO: SourceAmountIO,
        receiveIO: ReceiveIO,
        receiveAmountIO: ReceiveAmountIO,
        swapProvidersInput: SendSwapProvidersInput,
        actionType: SendFlowActionType,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        notificationService: SendAmountNotificationService?,
        flowKind: SendModel.PredefinedValues.FlowKind
    ) -> ReturnValue {
        let interactor = CommonSendNewAmountInteractor(
            sourceTokenInput: sourceIO.input,
            sourceTokenAmountInput: sourceAmountIO.input,
            sourceTokenAmountOutput: sourceAmountIO.output,
            receiveTokenInput: receiveIO.input,
            receiveTokenOutput: receiveIO.output,
            receiveTokenAmountInput: receiveAmountIO.input,
            validator: sendAmountValidator,
            amountModifier: amountModifier,
            notificationService: notificationService,
            type: .crypto
        )

        let viewModel = SendNewAmountViewModel(
            sourceTokenInput: sourceIO.input,
            settings: .init(possibleToChangeAmountType: builder.possibleToChangeAmountType(), actionType: actionType),
            interactor: interactor
        )

        let step = SendNewAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            flowKind: flowKind
        )

        let compact = SendNewAmountCompactViewModel(
            sourceTokenInput: sourceIO.input,
            sourceTokenAmountInput: sourceAmountIO.input,
            receiveTokenInput: receiveIO.input,
            receiveTokenAmountInput: receiveAmountIO.input,
            swapProvidersInput: swapProvidersInput,
            flow: flowKind,
        )

        let amountUpdater = SendExternalAmountUpdater(viewModel: viewModel, interactor: interactor)
        let finish = makeSendAmountCompactViewModel(tokenInput: sourceIO.input, amountInput: sourceAmountIO.input)

        return (step: step, amountUpdater: amountUpdater, compact: compact, finish: finish)
    }

    func makeSendAmountCompactViewModel(
        tokenInput: SendSourceTokenInput,
        amountInput: SendSourceTokenAmountInput
    ) -> SendTokenAmountCompactViewModel {
        let viewModel = SendTokenAmountCompactViewModel(sourceToken: tokenInput.sourceToken)
        viewModel.bind(amountPublisher: amountInput.sourceAmountPublisher)

        return viewModel
    }
}
