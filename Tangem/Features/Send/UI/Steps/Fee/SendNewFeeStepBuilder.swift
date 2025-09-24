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
            customFieldsBuilder: customFeeService as? FeeSelectorCustomFeeFieldsBuilder,
            feeTokenItem: feeTokenItem,
            savingType: .autosave
        )
        let compact = makeSendNewFeeCompactViewModel(input: io.input)
        let finish = makeSendFeeFinishViewModel(input: io.input)

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }

    func makeSendNewFeeCompactViewModel(input: SendFeeInput) -> SendNewFeeCompactViewModel {
        SendNewFeeCompactViewModel(feeTokenItem: feeTokenItem, isFeeApproximate: builder.isFeeApproximate())
    }

    func makeSendFeeFinishViewModel(input: SendFeeInput) -> SendFeeFinishViewModel {
        SendFeeFinishViewModel(feeTokenItem: feeTokenItem, isFeeApproximate: builder.isFeeApproximate())
    }

    private func makeSendFeeInteractor(io: IO, feeProvider: SendFeeProvider, customFeeService: CustomFeeService?) -> CommonSendFeeInteractor {
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


enum SendNewFeeStepBuilder2 {
    struct IO {
        let input: SendFeeInput
        let output: SendFeeOutput
    }

    struct Types {
        let feeTokenItem: TokenItem
        let isFeeApproximate: Bool
    }

    struct Dependencies {
        let feeProvider: SendFeeProvider
        let analyticsLogger: any FeeSelectorContentViewModelAnalytics
        let customFeeService: (any CustomFeeService)?
    }

    typealias ReturnValue = (
        feeSelector: FeeSelectorContentViewModel,
        compact: SendNewFeeCompactViewModel,
        finish: SendFeeFinishViewModel
    )

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let interactor = CommonSendFeeInteractor(
            input: io.input,
            output: io.output,
            provider: dependencies.feeProvider,
            customFeeService: dependencies.customFeeService
        )

        let feeSelector = FeeSelectorContentViewModel(
            input: interactor,
            output: interactor,
            analytics: dependencies.analyticsLogger,
            customFieldsBuilder: dependencies.customFeeService as? FeeSelectorCustomFeeFieldsBuilder,
            feeTokenItem: types.feeTokenItem,
            savingType: .autosave
        )

        let compact = makeSendNewFeeCompactViewModel(input: io.input, types: types)
        let finish = makeSendFeeFinishViewModel(input: io.input, types: types)

        dependencies.customFeeService?.setup(output: interactor)

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }

    static func makeSendNewFeeCompactViewModel(input: SendFeeInput, types: Types) -> SendNewFeeCompactViewModel {
        SendNewFeeCompactViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)
    }

    static func makeSendFeeFinishViewModel(input: SendFeeInput, types: Types) -> SendFeeFinishViewModel {
        SendFeeFinishViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)
    }
}
