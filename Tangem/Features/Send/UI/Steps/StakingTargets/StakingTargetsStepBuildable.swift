//
//  StakingTargetsStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStaking

protocol StakingTargetsStepBuildable {
    var stakingTargetsIO: StakingTargetsStepBuilder.IO { get }
    var stakingTargetsTypes: StakingTargetsStepBuilder.Types { get }
    var stakingTargetsDependencies: StakingTargetsStepBuilder.Dependencies { get }
}

extension StakingTargetsStepBuildable {
    func makeStakingTargetsStep() -> StakingTargetsStepBuilder.ReturnValue {
        StakingTargetsStepBuilder.makeStakingTargetsStep(
            io: stakingTargetsIO,
            types: stakingTargetsTypes,
            dependencies: stakingTargetsDependencies,
        )
    }
}

enum StakingTargetsStepBuilder {
    struct IO {
        let input: StakingTargetsInput
        let output: StakingTargetsOutput
    }

    struct Types {
        let actionType: SendFlowActionType
        let currentTarget: StakingTargetInfo?
    }

    struct Dependencies {
        let manager: any StakingManager
        let analyticsLogger: any SendTargetsAnalyticsLogger
    }

    typealias ReturnValue = (
        step: StakingTargetsStep,
        interactor: StakingTargetsInteractor,
        compact: StakingTargetsCompactViewModel
    )

    static func makeStakingTargetsStep(
        io: IO,
        types: Types,
        dependencies: Dependencies,
    ) -> ReturnValue {
        let interactor = CommonStakingTargetsInteractor(
            input: io.input,
            output: io.output,
            manager: dependencies.manager,
            currentTarget: types.currentTarget,
            actionType: types.actionType
        )

        let viewModel = StakingTargetsViewModel(interactor: interactor, analyticsLogger: dependencies.analyticsLogger)
        let preferredTargetsCount = dependencies.manager.state.yieldInfo?.preferredTargets.count ?? 0
        let step = StakingTargetsStep(viewModel: viewModel, interactor: interactor)
        let compact = StakingTargetsCompactViewModel(input: io.input, preferredTargetsCount: preferredTargetsCount)

        return (step: step, interactor: interactor, compact: compact)
    }
}
