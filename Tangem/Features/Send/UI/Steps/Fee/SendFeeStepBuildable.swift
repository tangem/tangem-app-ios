//
//  SendFeeStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendFeeStepBuildable {
    var feeIO: SendNewFeeStepBuilder.IO { get }
    var feeTypes: SendNewFeeStepBuilder.Types { get }
    var feeDependencies: SendNewFeeStepBuilder.Dependencies { get }
}

extension SendFeeStepBuildable {
    func makeSendFeeStep() -> SendNewFeeStepBuilder.ReturnValue {
        SendNewFeeStepBuilder.make(io: feeIO, types: feeTypes, dependencies: feeDependencies)
    }
}

enum SendNewFeeStepBuilder {
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
        let analyticsLogger: any FeeSelectorAnalytics
        let customFeeService: (any CustomFeeService)?
    }

    typealias ReturnValue = (
        feeSelector: SendFeeSelectorViewModel,
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
            feeTokenItem: types.feeTokenItem,
            customFeeProvider: dependencies.customFeeService as? FeeSelectorCustomFeeProvider
        )

        let feeSelectorViewModel = FeeSelectorBuilder().makeFeeSelectorViewModel(
            tokensDataProvider: interactor.feeSelectorInteractor,
            feesDataProvider: interactor.feeSelectorInteractor,
            customFeeService: dependencies.customFeeService,
            mapper: CommonFeeSelectorFeesViewModelMapper(
                feeFormatter: CommonFeeFormatter(),
                customFieldsBuilder: dependencies.customFeeService as? FeeSelectorCustomFeeFieldsBuilder
            ),
            analytics: dependencies.analyticsLogger,
            output: interactor,
            router: interactor // [REDACTED_TODO_COMMENT]
        )

        let feeSelector = SendFeeSelectorViewModel(feeSelectorViewModel: feeSelectorViewModel)
        let compact = SendNewFeeCompactViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)
        let finish = SendFeeFinishViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }
}
