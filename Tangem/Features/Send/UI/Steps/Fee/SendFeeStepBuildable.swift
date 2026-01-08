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
    func makeSendFeeStep(router: any SendFeeSelectorRoutable) -> SendNewFeeStepBuilder.ReturnValue {
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
        let customFeeProvider: (any CustomFeeProvider)?
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
        router: SendFeeSelectorRoutable
    ) -> ReturnValue {
        let feeSelectorInteractor = CommonFeeSelectorInteractor(
            input: io.input,
            output: io.output,
            feesProvider: dependencies.feeProvider,
        )

        let feeSelectorViewModel = FeeSelectorBuilder().makeFeeSelectorViewModel(
            feeSelectorInteractor: feeSelectorInteractor,
            customFeeAvailabilityProvider: dependencies.customFeeProvider,
            mapper: CommonFeeSelectorFeesViewModelMapper(
                feeFormatter: CommonFeeFormatter(),
                customFieldsBuilder: dependencies.customFeeProvider
            ),
            analytics: dependencies.analyticsLogger,
            router: router
        )

        let feeSelector = SendFeeSelectorViewModel(feeSelectorViewModel: feeSelectorViewModel, router: router)
        let compact = SendNewFeeCompactViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)
        let finish = SendFeeFinishViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }
}
