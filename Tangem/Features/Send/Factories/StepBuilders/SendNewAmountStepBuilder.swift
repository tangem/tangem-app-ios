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
    typealias ReturnValue = (step: SendNewAmountStep, interactor: SendAmountInteractor, compact: SendAmountCompactViewModel)

    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let builder: SendDependenciesBuilder

    func makeSendNewAmountStep(
        io: IO,
        actionType: SendFlowActionType,
        sendFeeLoader: any SendFeeLoader,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        source: SendModel.PredefinedValues.Source
    ) -> ReturnValue {
        let interactor = makeSendAmountInteractor(
            io: io,
            sendAmountValidator: sendAmountValidator,
            amountModifier: amountModifier,
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
            sendFeeLoader: sendFeeLoader,
            source: source
        )

        let compact = makeSendAmountCompactViewModel(input: io.input)
        return (step: step, interactor: interactor, compact: compact)
    }

    func makeSendAmountCompactViewModel(input: SendAmountInput) -> SendAmountCompactViewModel {
        .init(
            input: input,
            tokenIconInfo: builder.makeTokenIconInfo(),
            tokenItem: tokenItem
        )
    }
}

// MARK: - Private

private extension SendNewAmountStepBuilder {
    func makeSendAmountViewModel(
        io: IO,
        interactor: SendAmountInteractor,
        actionType: SendFlowActionType,
    ) -> SendNewAmountViewModel {
        let initital = SendNewAmountViewModel.Settings(
            walletHeaderText: builder.walletHeaderText(for: actionType),
            tokenItem: tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceFormatted: builder.formattedBalance(for: io.input.amount, actionType: actionType),
            fiatIconURL: builder.makeFiatIconURL(),
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            possibleToChangeAmountType: builder.possibleToChangeAmountType(),
            actionType: actionType
        )

        return SendNewAmountViewModel(initial: initital, interactor: interactor)
    }

    private func makeSendAmountInteractor(
        io: IO,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        type: SendAmountCalculationType,
        actionType: SendFlowActionType
    ) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            input: io.input,
            output: io.output,
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            maxAmount: builder.maxAmount(for: io.input.amount, actionType: actionType),
            validator: sendAmountValidator,
            amountModifier: amountModifier,
            type: type
        )
    }
}
