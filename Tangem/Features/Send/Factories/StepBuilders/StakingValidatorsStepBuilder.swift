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
        sendFeeLoader: SendFeeLoader
    ) -> ReturnValue {
        let interactor = makeStakingValidatorsInteractor(
            io: io,
            manager: manager,
            currentValidator: currentValidator,
            actionType: actionType
        )

        let viewModel = makeStakingValidatorsViewModel(interactor: interactor)
        var step: StakingValidatorsStep?

        if let validatorInfos = manager.state.yieldInfo?.preferredValidators, validatorInfos.count > 1 {
            step = StakingValidatorsStep(viewModel: viewModel, interactor: interactor, sendFeeLoader: sendFeeLoader)
        }

        let compact = makeStakingValidatorsCompactViewModel(io: io)

        return (step: step, interactor: interactor, compact: compact)
    }

    func makeRestakingValidatorsStep(
        io: IO,
        manager: some StakingManager,
        currentValidator: ValidatorInfo? = nil,
        actionType: SendFlowActionType,
        sendFeeLoader: SendFeeLoader
    ) -> StakingValidatorsStep {
        let interactor = makeStakingValidatorsInteractor(
            io: io,
            manager: manager,
            currentValidator: currentValidator,
            actionType: actionType
        )
        let viewModel = makeStakingValidatorsViewModel(interactor: interactor)
        return StakingValidatorsStep(viewModel: viewModel, interactor: interactor, sendFeeLoader: sendFeeLoader)
    }

    func makeStakingValidatorsCompactViewModel(io: IO) -> StakingValidatorsCompactViewModel {
        .init(input: io.input)
    }
}

// MARK: - Private

private extension StakingValidatorsStepBuilder {
    func makeStakingValidatorsViewModel(interactor: StakingValidatorsInteractor) -> StakingValidatorsViewModel {
        StakingValidatorsViewModel(interactor: interactor)
    }

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
