//
//  SendAmountStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

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
        let input: SendAmountInput
        let output: SendAmountOutput
    }

    struct Types {
        let tokenItem: TokenItem
        let feeTokenItem: TokenItem
        let maxAmount: Decimal
        let settings: SendAmountViewModel.Settings
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

        let compact = SendAmountCompactViewModel(
            conventViewModel: SendAmountCompactContentViewModel(
                input: io.input,
                tokenIconInfo: types.settings.tokenIconInfo,
                tokenItem: types.tokenItem
            )
        )
        return (step: step, interactor: interactor, compact: compact)
    }
}
