//
//  StakingValidatorsStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStaking

protocol StakingValidatorsStepBuildable {
    var stakingValidatorsIO: StakingValidatorsStepBuilder.IO { get }
    var stakingValidatorsTypes: StakingValidatorsStepBuilder.Types { get }
    var stakingValidatorsDependencies: StakingValidatorsStepBuilder.Dependencies { get }
}

extension StakingValidatorsStepBuildable {
    func makeStakingValidatorsStep() -> StakingValidatorsStepBuilder.ReturnValue {
        StakingValidatorsStepBuilder.makeStakingValidatorsStep(
            io: stakingValidatorsIO,
            types: stakingValidatorsTypes,
            dependencies: stakingValidatorsDependencies,
        )
    }
}

enum StakingValidatorsStepBuilder {
    struct IO {
        let input: StakingValidatorsInput
        let output: StakingValidatorsOutput
    }

    struct Types {
        let actionType: SendFlowActionType
        let currentValidator: ValidatorInfo?
    }

    struct Dependencies {
        let manager: any StakingManager
        let sendFeeProvider: any SendFeeProvider
        let analyticsLogger: any SendValidatorsAnalyticsLogger
    }

    typealias ReturnValue = (
        step: StakingValidatorsStep,
        interactor: StakingValidatorsInteractor,
        compact: StakingValidatorsCompactViewModel
    )

    static func makeStakingValidatorsStep(
        io: IO,
        types: Types,
        dependencies: Dependencies,
    ) -> ReturnValue {
        let interactor = CommonStakingValidatorsInteractor(
            input: io.input,
            output: io.output,
            manager: dependencies.manager,
            currentValidator: types.currentValidator,
            actionType: types.actionType
        )

        let viewModel = StakingValidatorsViewModel(interactor: interactor, analyticsLogger: dependencies.analyticsLogger)
        let preferredValidatorsCount = dependencies.manager.state.yieldInfo?.preferredValidators.count ?? 0
        let step = StakingValidatorsStep(viewModel: viewModel, interactor: interactor, sendFeeProvider: dependencies.sendFeeProvider)
        let compact = StakingValidatorsCompactViewModel(input: io.input, preferredValidatorsCount: preferredValidatorsCount)

        return (step: step, interactor: interactor, compact: compact)
    }
}
