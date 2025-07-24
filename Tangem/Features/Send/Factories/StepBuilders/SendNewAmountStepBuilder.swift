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

    typealias ReturnValue = (step: SendNewAmountStep, amountUpdater: SendExternalAmountUpdater, compact: SendNewAmountCompactViewModel, finish: SendNewAmountFinishViewModel)

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
        analyticsLogger: any SendAnalyticsLogger
    ) -> ReturnValue {
        let interactorSaver = CommonSendNewAmountInteractorSaver(
            sourceTokenAmountInput: sourceAmountIO.input,
            sourceTokenAmountOutput: sourceAmountIO.output
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
            sourceTokenInput: sourceIO.input,
            settings: .init(possibleToChangeAmountType: builder.possibleToChangeAmountType(), actionType: actionType),
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

        let amountUpdater = SendExternalAmountUpdater(viewModel: viewModel, interactor: interactor)
        let finish = SendNewAmountFinishViewModel(
            sourceTokenInput: sourceIO.input,
            sourceTokenAmountInput: sourceAmountIO.input,
            receiveTokenInput: receiveIO.input,
            receiveTokenAmountInput: receiveAmountIO.input,
            swapProvidersInput: swapProvidersInput,
        )

        return (step: step, amountUpdater: amountUpdater, compact: compact, finish: finish)
    }
}
