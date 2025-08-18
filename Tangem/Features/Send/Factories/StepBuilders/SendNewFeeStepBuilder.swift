//
//  SendNewFeeStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine
import BlockchainSdk

struct SendNewFeeStepBuilder {
    typealias IO = (input: SendFeeInput, output: SendFeeOutput)
    typealias ReturnValue = (feeSelector: FeeSelectorContentViewModel, compact: SendNewFeeCompactViewModel, finish: SendFeeFinishViewModel)

    let feeTokenItem: TokenItem
    let isFeeApproximate: Bool
    let feeProvider: SendFeeProvider
    let analyticsLogger: any FeeSelectorContentViewModelAnalytics
    let customFeeService: (any CustomFeeService)?
    let feeSelectorCustomFeeFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder

    func makeSendFee(io: IO) -> ReturnValue {
        let interactor = makeSendFeeInteractor(io: io)
        let feeSelector = FeeSelectorContentViewModel(
            input: interactor,
            output: interactor,
            analytics: analyticsLogger,
            customFieldsBuilder: feeSelectorCustomFeeFieldsBuilder,
            feeTokenItem: feeTokenItem
        )
        let compact = makeSendNewFeeCompactViewModel(input: io.input)
        let finish = makeSendFeeFinishViewModel(input: io.input)

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }

    func makeSendNewFeeCompactViewModel(input: SendFeeInput) -> SendNewFeeCompactViewModel {
        SendNewFeeCompactViewModel(feeTokenItem: feeTokenItem, isFeeApproximate: isFeeApproximate)
    }

    func makeSendFeeFinishViewModel(input: SendFeeInput) -> SendFeeFinishViewModel {
        SendFeeFinishViewModel(feeTokenItem: feeTokenItem, isFeeApproximate: isFeeApproximate)
    }

    private func makeSendFeeInteractor(io: IO) -> CommonSendFeeInteractor {
        let interactor = CommonSendFeeInteractor(
            input: io.input,
            output: io.output,
            provider: feeProvider,
            customFeeService: customFeeService
        )

        customFeeService?.setup(output: interactor)
        return interactor
    }
}
