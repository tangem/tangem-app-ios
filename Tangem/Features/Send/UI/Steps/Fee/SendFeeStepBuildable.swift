//
//  SendFeeStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendFeeStepBuildable {
    var feeIO: SendNewFeeStepBuilder2.IO { get }
    var feeTypes: SendNewFeeStepBuilder2.Types { get }
    var feeDependencies: SendNewFeeStepBuilder2.Dependencies { get }
}

extension SendFeeStepBuildable {
    func makeSendFeeStep() -> SendNewFeeStepBuilder2.ReturnValue {
        SendNewFeeStepBuilder2.make(io: feeIO, types: feeTypes, dependencies: feeDependencies)
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
        dependencies: Dependencies
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

    static func makeSendFeeCompactViewModel(input: SendFeeInput, types: Types) -> SendFeeCompactViewModel {
        SendFeeCompactViewModel(input: input, feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)
    }

    static func makeSendFeeFinishViewModel(input: SendFeeInput, types: Types) -> SendFeeFinishViewModel {
        SendFeeFinishViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)
    }
}
