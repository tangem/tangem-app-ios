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
    typealias ReturnValue = (feeSelector: FeeSelectorContentViewModel, interactor: SendFeeInteractor, compact: SendNewFeeCompactViewModel, finish: SendFeeCompactViewModel)

    private let feeTokenItem: TokenItem
    private let builder: SendDependenciesBuilder

    init(feeTokenItem: TokenItem, builder: SendDependenciesBuilder) {
        self.feeTokenItem = feeTokenItem
        self.builder = builder
    }

    func makeSendFee(io: IO) -> ReturnValue {
        let interactor = makeSendFeeInteractor(io: io)
        let feeSelector = FeeSelectorContentViewModel(
            input: interactor,
            output: interactor,
            analytics: builder.makeFeeSelectorContentViewModelAnalytics(flowKind: .send),
            customFieldsBuilder: builder.makeFeeSelectorCustomFeeFieldsBuilder(),
            feeTokenItem: feeTokenItem
        )
        let compact = makeSendNewFeeCompactViewModel(input: io.input)
        let finish = makeSendFeeCompactViewModel(input: io.input)

        return (feeSelector: feeSelector, interactor: interactor, compact: compact, finish: finish)
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

    private func makeSendFeeInteractor(io: IO) -> CommonSendFeeInteractor {
        let customFeeService = builder.makeCustomFeeService()
        let interactor = CommonSendFeeInteractor(
            input: io.input,
            output: io.output,
            provider: builder.makeSendFeeProvider(),
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService
        )

        customFeeService?.setup(input: interactor, output: interactor)
        return interactor
    }
}
