//
//  StakingValidatorsStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct StakingValidatorsStepBuilder {
    typealias IO = (input: StakingValidatorsInput, output: StakingValidatorsOutput)
    typealias ReturnValue = (
        step: StakingValidatorsStep?,
        interactor: StakingValidatorsInteractor,
        compact: StakingValidatorsCompactViewModel
    )

    func makeStakingValidatorsStep(
        io: IO,
        manager: some StakingManager,
        currentValidator: ValidatorInfo? = nil,
        actionType: SendFlowActionType,
        sendFeeProvider: SendFeeProvider,
        analyticsLogger: any SendValidatorsAnalyticsLogger
    ) -> ReturnValue {
        let interactor = makeStakingValidatorsInteractor(
            io: io,
            manager: manager,
            currentValidator: currentValidator,
            actionType: actionType
        )

        let viewModel = StakingValidatorsViewModel(interactor: interactor, analyticsLogger: analyticsLogger)
        var step: StakingValidatorsStep?

        if let validatorInfos = manager.state.yieldInfo?.preferredValidators, validatorInfos.count > 1 {
            step = StakingValidatorsStep(viewModel: viewModel, interactor: interactor, sendFeeProvider: sendFeeProvider)
        }

        let compact = makeStakingValidatorsCompactViewModel(io: io)

        return (step: step, interactor: interactor, compact: compact)
    }

    func makeRestakingValidatorsStep(
        io: IO,
        manager: some StakingManager,
        currentValidator: ValidatorInfo? = nil,
        actionType: SendFlowActionType,
        sendFeeProvider: SendFeeProvider,
        analyticsLogger: any SendValidatorsAnalyticsLogger
    ) -> StakingValidatorsStep {
        let interactor = makeStakingValidatorsInteractor(
            io: io,
            manager: manager,
            currentValidator: currentValidator,
            actionType: actionType
        )
        let viewModel = StakingValidatorsViewModel(interactor: interactor, analyticsLogger: analyticsLogger)
        return StakingValidatorsStep(viewModel: viewModel, interactor: interactor, sendFeeProvider: sendFeeProvider)
    }

    func makeStakingValidatorsCompactViewModel(io: IO) -> StakingValidatorsCompactViewModel {
        .init(input: io.input)
    }
}

// MARK: - Private

private extension StakingValidatorsStepBuilder {
    func makeStakingValidatorsInteractor(
        io: IO,
        manager: some StakingManager,
        currentValidator: ValidatorInfo?,
        actionType: SendFlowActionType
    ) -> StakingValidatorsInteractor {
        CommonStakingValidatorsInteractor(
            input: io.input,
            output: io.output,
            manager: manager,
            currentValidator: currentValidator,
            actionType: actionType
        )
    }
}

enum StakingValidatorsStepBuilder2 {
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
        step: StakingValidatorsStep?,
        interactor: StakingValidatorsInteractor,
        compact: StakingValidatorsCompactViewModel
    )

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
//        manager: some StakingManager,
//        currentValidator: ValidatorInfo? = nil,
//        actionType: SendFlowActionType,
//        sendFeeProvider: SendFeeProvider,
//        analyticsLogger: any SendValidatorsAnalyticsLogger
    ) -> ReturnValue {
        let interactor = CommonStakingValidatorsInteractor(
            input: io.input,
            output: io.output,
            manager: dependencies.manager,
            currentValidator: types.currentValidator,
            actionType: types.actionType
        )

        let viewModel = StakingValidatorsViewModel(interactor: interactor, analyticsLogger: dependencies.analyticsLogger)
        var step: StakingValidatorsStep?

        if let validatorInfos = dependencies.manager.state.yieldInfo?.preferredValidators, validatorInfos.count > 1 {
            step = StakingValidatorsStep(viewModel: viewModel, interactor: interactor, sendFeeProvider: dependencies.sendFeeProvider)
        }

        let compact = StakingValidatorsCompactViewModel(input: io.input)

        return (step: step, interactor: interactor, compact: compact)
    }

//    func makeRestakingValidatorsStep(
//        io: IO,
//        manager: some StakingManager,
//        currentValidator: ValidatorInfo? = nil,
//        actionType: SendFlowActionType,
//        sendFeeProvider: SendFeeProvider,
//        analyticsLogger: any SendValidatorsAnalyticsLogger
//    ) -> StakingValidatorsStep {
//        let interactor = makeStakingValidatorsInteractor(
//            io: io,
//            manager: manager,
//            currentValidator: currentValidator,
//            actionType: actionType
//        )
//        let viewModel = StakingValidatorsViewModel(interactor: interactor, analyticsLogger: analyticsLogger)
//        return StakingValidatorsStep(viewModel: viewModel, interactor: interactor, sendFeeProvider: sendFeeProvider)
//    }
//
//    func makeStakingValidatorsCompactViewModel(io: IO) -> StakingValidatorsCompactViewModel {
//        .init(input: io.input)
//    }
}
