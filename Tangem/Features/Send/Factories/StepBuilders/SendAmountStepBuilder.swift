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

    let walletModel: any WalletModel
    let builder: SendDependenciesBuilder

    func makeSendAmountStep(
        io: IO,
        actionType: SendFlowActionType,
        sendFeeProvider: any SendFeeProvider,
        sendQRCodeService: SendQRCodeService?,
        sendAmountValidator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        analyticsLogger: SendAmountAnalyticsLogger,
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
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger
        )

        let step = SendAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            sendFeeProvider: sendFeeProvider,
            analyticsLogger: analyticsLogger
        )

        let compact = makeSendAmountCompactViewModel(input: io.input)
        return (step: step, interactor: interactor, compact: compact)
    }

    func makeSendAmountCompactViewModel(input: SendAmountInput) -> SendAmountCompactViewModel {
        let conventViewModel = SendAmountCompactContentViewModel(
            input: input,
            tokenIconInfo: builder.makeTokenIconInfo(),
            tokenItem: walletModel.tokenItem
        )

        return SendAmountCompactViewModel(conventViewModel: .default(viewModel: conventViewModel))
    }
}

// MARK: - Private

private extension SendAmountStepBuilder {
    func makeSendAmountViewModel(
        io: IO,
        interactor: SendAmountInteractor,
        actionType: SendFlowActionType,
        sendQRCodeService: SendQRCodeService?,
        analyticsLogger: SendAmountAnalyticsLogger,
    ) -> SendAmountViewModel {
        let initial = SendAmountViewModel.Settings(
            walletHeaderText: builder.walletHeaderText(for: actionType),
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceFormatted: builder.formattedBalance(for: io.input.amount, actionType: actionType),
            currencyPickerData: builder.makeCurrencyPickerData(),
            actionType: actionType
        )

        return SendAmountViewModel(
            initial: initial,
            interactor: interactor,
            analyticsLogger: analyticsLogger,
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
            feeTokenItem: walletModel.feeTokenItem,
            maxAmount: builder.maxAmount(for: io.input.amount, actionType: actionType),
            validator: sendAmountValidator,
            amountModifier: amountModifier,
            type: type
        )
    }
}
