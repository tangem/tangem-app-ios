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
            provider: interactor.feeSelectorInteractor,
            output: interactor,
            mapper: CommonFeeSelectorContentViewModelMapper(
                feeTokenItem: types.feeTokenItem,
                feeFormatter: CommonFeeFormatter(),
                customFieldsBuilder: dependencies.customFeeService as? FeeSelectorCustomFeeFieldsBuilder
            ),
            customFeeAvailabilityProvider: dependencies.customFeeService as? FeeSelectorCustomFeeAvailabilityProvider,
            analytics: dependencies.analyticsLogger,
            router: interactor
        )

        let compact = SendNewFeeCompactViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)
        let finish = SendFeeFinishViewModel(feeTokenItem: types.feeTokenItem, isFeeApproximate: types.isFeeApproximate)

        dependencies.customFeeService?.setup(output: interactor)

        return (feeSelector: feeSelector, compact: compact, finish: finish)
    }
}
