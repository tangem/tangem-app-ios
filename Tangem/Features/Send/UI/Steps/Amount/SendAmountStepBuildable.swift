//
//  SendAmountStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder2.IO { get }
    var amountTypes: SendAmountStepBuilder2.Types { get }
    var amountDependencies: SendAmountStepBuilder2.Dependencies { get }
}

extension SendAmountStepBuildable {
    func makeSendAmountStep() -> SendAmountStepBuilder2.ReturnValue {
        SendAmountStepBuilder2.make(io: amountIO, types: amountTypes, dependencies: amountDependencies)
    }
}

enum SendAmountStepBuilder2 {
    struct IO {
        let input: SendAmountInput
        let output: SendAmountOutput
    }

    struct Types {
        let tokenItem: TokenItem
        let feeTokenItem: TokenItem
        let maxAmount: Decimal
        let settings: SendAmountViewModel.Settings
        /*
         .init(
         walletHeaderText: builder.walletHeaderText(for: actionType),
         tokenItem: walletModel.tokenItem,
         tokenIconInfo: builder.makeTokenIconInfo(),
         balanceFormatted: builder.formattedBalance(for: io.input.amount, actionType: actionType),
         currencyPickerData: builder.makeCurrencyPickerData(),
         actionType: actionType
         )
         */
    }

    struct Dependencies {
        let sendFeeProvider: any SendFeeProvider
        let sendQRCodeService: (any SendQRCodeService)?
        let sendAmountValidator: any SendAmountValidator
        let amountModifier: (any SendAmountModifier)?
        let analyticsLogger: any SendAmountAnalyticsLogger
    }

    typealias ReturnValue = (step: SendAmountStep, interactor: SendAmountInteractor, compact: SendAmountCompactViewModel)

    static func make(io: IO, types: Types, dependencies: Dependencies,) -> ReturnValue {
        let interactor = CommonSendAmountInteractor(
            input: io.input,
            output: io.output,
            tokenItem: types.tokenItem,
            feeTokenItem: types.feeTokenItem,
            maxAmount: types.maxAmount,
            validator: dependencies.sendAmountValidator,
            amountModifier: dependencies.amountModifier,
            type: .crypto
        )

        let viewModel = SendAmountViewModel(
            initial: types.settings,
            interactor: interactor,
            analyticsLogger: dependencies.analyticsLogger,
            sendQRCodeService: dependencies.sendQRCodeService
        )

        let step = SendAmountStep(
            viewModel: viewModel,
            interactor: interactor,
            sendFeeProvider: dependencies.sendFeeProvider,
            analyticsLogger: dependencies.analyticsLogger
        )

        let compact = makeSendAmountCompactViewModel(input: io.input, types: types)
        return (step: step, interactor: interactor, compact: compact)
    }

    static func makeSendAmountCompactViewModel(input: SendAmountInput, types: Types) -> SendAmountCompactViewModel {
        let conventViewModel = SendAmountCompactContentViewModel(
            input: input,
            tokenIconInfo: types.settings.tokenIconInfo,
            tokenItem: types.tokenItem
        )

        return SendAmountCompactViewModel(conventViewModel: conventViewModel)
    }
}
