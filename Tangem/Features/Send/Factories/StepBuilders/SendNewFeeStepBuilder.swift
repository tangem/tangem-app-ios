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
    typealias ReturnValue = (feeSelector: FeeSelectorContentViewModel, compact: SendNewFeeCompactViewModel, finish: SendFeeCompactViewModel)

    private let feeTokenItem: TokenItem
    private let builder: SendDependenciesBuilder

    init(feeTokenItem: TokenItem, builder: SendDependenciesBuilder) {
        self.feeTokenItem = feeTokenItem
        self.builder = builder
    }

    func makeSendFee(
        io: IO,
        feeProvider: SendFeeProvider,
        analyticsLogger: any FeeSelectorContentViewModelAnalytics,
        customFeeService: (any CustomFeeService)?
    ) -> ReturnValue {
        let interactor = makeSendFeeInteractor(io: io, feeProvider: feeProvider, customFeeService: customFeeService)
        let feeSelector = FeeSelectorContentViewModel(
            input: interactor,
            output: interactor,
            analytics: analyticsLogger,
            customFieldsBuilder: builder.makeFeeSelectorCustomFeeFieldsBuilder(customFeeService: customFeeService),
            feeTokenItem: feeTokenItem
        )
        let compact = makeSendNewFeeCompactViewModel(input: io.input)
        let finish = makeSendFeeCompactViewModel(input: io.input)

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }

    func makeSendNewFeeCompactViewModel(input: SendFeeInput) -> SendNewFeeCompactViewModel {
        SendNewFeeCompactViewModel(
            input: input,
            feeTokenItem: feeTokenItem,
            isFeeApproximate: builder.isFeeApproximate()
        )
    }

    func makeSendFeeCompactViewModel(input: SendFeeInput) -> SendFeeCompactViewModel {
        SendFeeCompactViewModel(
            input: input,
            feeTokenItem: feeTokenItem,
            isFeeApproximate: builder.isFeeApproximate()
        )
    }

    private func makeSendFeeInteractor(io: IO, feeProvider: SendFeeProvider, customFeeService: CustomFeeService?) -> CommonSendFeeInteractor {
        let interactor = CommonSendFeeInteractor(
            input: io.input,
            output: io.output,
            provider: feeProvider,
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService
        )

        customFeeService?.setup(output: interactor)
        return interactor
    }
}
