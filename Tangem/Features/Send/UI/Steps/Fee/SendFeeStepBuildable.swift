//
//  SendFeeStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendFeeStepBuildable {
    var feeIO: SendNewFeeStepBuilder.IO { get }
    var feeDependencies: SendNewFeeStepBuilder.Dependencies { get }
}

extension SendFeeStepBuildable {
    func makeSendFeeStep(router: any SendFeeSelectorRoutable) -> SendNewFeeStepBuilder.ReturnValue {
        SendNewFeeStepBuilder.make(io: feeIO, dependencies: feeDependencies, router: router)
    }
}

enum SendNewFeeStepBuilder {
    struct IO {
        let input: SendFeeInput
        let output: SendFeeOutput
    }

    struct Dependencies {
        let feeSelectorInteractor: FeeSelectorInteractor
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
        dependencies: Dependencies,
        router: SendFeeSelectorRoutable
    ) -> ReturnValue {
        let feeSelectorViewModel = FeeSelectorBuilder().makeFeeSelectorViewModel(
            feeSelectorInteractor: dependencies.feeSelectorInteractor,
            analytics: dependencies.analyticsLogger,
            feeFormatter: CommonFeeFormatter(),
            router: router
        )

        let feeSelector = SendFeeSelectorViewModel(feeSelectorViewModel: feeSelectorViewModel, router: router)
        let compact = SendNewFeeCompactViewModel()
        let finish = SendFeeFinishViewModel()

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }
}
