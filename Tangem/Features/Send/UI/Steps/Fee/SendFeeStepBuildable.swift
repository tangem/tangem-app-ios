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
    func makeSendFeeStep(router: any FeeSelectorRoutable) -> SendNewFeeStepBuilder.ReturnValue {
        SendNewFeeStepBuilder.make(io: feeIO, types: feeTypes, dependencies: feeDependencies, router: router)
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
        dependencies: Dependencies,
        router: any FeeSelectorRoutable
    ) -> ReturnValue {
        let feeSelectorInteractor = CommonFeeSelectorInteractor(
            input: io.input,
            feeTokenItemsProvider: dependencies.feeProvider,
            feesProvider: dependencies.feeProvider,
            suggestedFeeProvider: nil,
            customFeeProvider: dependencies.customFeeService as? FeeSelectorCustomFeeProvider,
            output: io.output
        )

        let feeSelectorViewModel = FeeSelectorBuilder().makeFeeSelectorViewModel(
            tokensDataProvider: feeSelectorInteractor,
            feesDataProvider: feeSelectorInteractor,
            customFeeAvailabilityProvider: dependencies.customFeeService as? FeeSelectorCustomFeeAvailabilityProvider,
            mapper: CommonFeeSelectorFeesViewModelMapper(
                feeFormatter: CommonFeeFormatter(),
                customFieldsBuilder: dependencies.customFeeService as? FeeSelectorCustomFeeFieldsBuilder
            ),
            analytics: dependencies.analyticsLogger,
            output: io.output,
            router: router
        )

        let feeSelector = SendFeeSelectorViewModel(feeSelectorViewModel: feeSelectorViewModel)
        let compact = SendNewFeeCompactViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)
        let finish = SendFeeFinishViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }
}
