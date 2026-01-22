//
//  SendFeeStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies { get }
}

extension SendFeeStepBuildable {
    func makeSendFeeStep(router: any SendFeeSelectorRoutable) -> SendFeeStepBuilder.ReturnValue {
        SendFeeStepBuilder.make(dependencies: feeDependencies, router: router)
    }
}

enum SendFeeStepBuilder {
    struct Dependencies {
        let tokenFeeManagerProviding: any TokenFeeProvidersManagerProviding
        let feeSelectorOutput: any FeeSelectorOutput
        let analyticsLogger: any FeeSelectorAnalytics
    }

    typealias ReturnValue = (
        feeSelectorBuilder: SendFeeSelectorBuilder,
        compact: FeeCompactViewModel,
        finish: SendFeeFinishViewModel
    )

    static func make(
        dependencies: Dependencies,
        router: SendFeeSelectorRoutable
    ) -> ReturnValue {
        let feeSelectorBuilder = SendFeeSelectorBuilder(
            tokenFeeManagerProviding: dependencies.tokenFeeManagerProviding,
            feeSelectorOutput: dependencies.feeSelectorOutput,
            analyticsLogger: dependencies.analyticsLogger
        )

        let compact = FeeCompactViewModel()
        let finish = SendFeeFinishViewModel()

        return (feeSelectorBuilder: feeSelectorBuilder, compact: compact, finish: finish)
    }
}
