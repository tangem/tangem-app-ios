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
    typealias IO = (input: SendAmountInput, output: SendAmountOutput)
    typealias ReturnValue = (step: SendNewAmountStep, interactor: SendAmountInteractor, compact: SendNewAmountCompactViewModel, finish: SendTokenAmountCompactViewModel)

    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let builder: SendDependenciesBuilder

    func makeSendNewAmountStep(
        io: IO,
        actionType: SendFlowActionType,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        receiveTokenInput: SendReceiveTokenInput?,
        receiveTokenOutput: SendReceiveTokenOutput?,
        flowKind: SendModel.PredefinedValues.FlowKind
    ) -> ReturnValue {
        let interactor = makeSendAmountInteractor(
            io: io,
            sendAmountValidator: sendAmountValidator,
            amountModifier: amountModifier,
            receiveTokenInput: receiveTokenInput,
            receiveTokenOutput: receiveTokenOutput,
            type: .crypto,
            actionType: actionType
        )

        let viewModel = makeSendAmountViewModel(
            io: io,
            interactor: interactor,
            actionType: actionType
        )

        let step = SendNewAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            flowKind: flowKind
        )

        let compact = makeSendAmountCompactViewModel(input: io.input, receiveTokenInput: receiveTokenInput, actionType: actionType, flowKind: flowKind)
        let finish = makeSendAmountCompactViewModel(input: io.input)
        return (step: step, interactor: interactor, compact: compact, finish: finish)
    }

    func makeSendAmountCompactViewModel(input: SendAmountInput) -> SendTokenAmountCompactViewModel {
        let token = makeSendReceiveToken()
        let viewModel = SendTokenAmountCompactViewModel(receiveToken: token)
        viewModel.bind(amountPublisher: input.amountPublisher)

        return viewModel
    }

    func makeSendAmountCompactViewModel(input: SendAmountInput, receiveTokenInput: SendReceiveTokenInput?, actionType: SendFlowActionType, flowKind: SendModel.PredefinedValues.FlowKind) -> SendNewAmountCompactViewModel {
        let token = makeSendReceiveToken()
        let viewModel = SendNewAmountCompactViewModel(
            input: input,
            sendToken: token,
            flow: flowKind,
            balanceProvider: builder.makeTokenBalanceProvider(),
            receiveTokenInput: receiveTokenInput
        )

        return viewModel
    }
}

// MARK: - Private

private extension SendNewAmountStepBuilder {
    func makeSendAmountViewModel(
        io: IO,
        interactor: SendAmountInteractor,
        actionType: SendFlowActionType
    ) -> SendNewAmountViewModel {
        let initital = SendNewAmountViewModel.Settings(
            walletHeaderText: builder.walletHeaderText(for: actionType),
            tokenItem: tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceFormatted: builder.formattedBalance(for: io.input.amount, actionType: actionType),
            fiatIconURL: builder.makeFiatIconURL(),
            fiatItem: builder.makeFiatItem(),
            possibleToChangeAmountType: builder.possibleToChangeAmountType(),
            actionType: actionType
        )

        return SendNewAmountViewModel(initial: initital, interactor: interactor)
    }

    private func makeSendAmountInteractor(
        io: IO,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        receiveTokenInput: SendReceiveTokenInput?,
        receiveTokenOutput: SendReceiveTokenOutput?,
        type: SendAmountCalculationType,
        actionType: SendFlowActionType
    ) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            input: io.input,
            output: io.output,
            receiveTokenInput: receiveTokenInput,
            receiveTokenOutput: receiveTokenOutput,
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            maxAmount: builder.maxAmount(for: io.input.amount, actionType: actionType),
            validator: sendAmountValidator,
            amountModifier: amountModifier,
            type: type
        )
    }

    func makeSendReceiveToken() -> SendReceiveToken {
        SendReceiveToken(
            wallet: builder.walletName(),
            tokenItem: tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            fiatItem: builder.makeFiatItem()
        )
    }
}
