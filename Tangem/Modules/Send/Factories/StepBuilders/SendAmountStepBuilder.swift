//
//  SendAmountStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct SendAmountStepBuilder {
    typealias IO = (input: SendAmountInput, output: SendAmountOutput)
    typealias ReturnValue = (step: SendAmountStep, interactor: SendAmountInteractor, compact: SendAmountCompactViewModel)

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendAmountStep(
        io: IO,
        actionType: SendFlowActionType,
        sendFeeLoader: any SendFeeLoader,
        sendQRCodeService: SendQRCodeService?,
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
            actionType: actionType,
            sendQRCodeService: sendQRCodeService
        )

        let step = SendAmountStep(
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
            tokenItem: walletModel.tokenItem
        )
    }
}

// MARK: - Private

private extension SendAmountStepBuilder {
    func makeSendAmountViewModel(
        io: IO,
        interactor: SendAmountInteractor,
        actionType: SendFlowActionType,
        sendQRCodeService: SendQRCodeService?
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            walletHeaderText: builder.walletHeaderText(for: actionType),
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceFormatted: builder.formattedBalance(for: io.input.amount, actionType: actionType),
            currencyPickerData: builder.makeCurrencyPickerData(),
            actionType: actionType
        )

        return SendAmountViewModel(
            initial: initital,
            interactor: interactor,
            sendQRCodeService: sendQRCodeService
        )
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
            tokenItem: walletModel.tokenItem,
            maxAmount: builder.maxAmount(for: io.input.amount, actionType: actionType),
            validator: sendAmountValidator,
            amountModifier: amountModifier,
            type: type
        )
    }
}
