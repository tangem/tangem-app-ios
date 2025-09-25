//
//  SendFinishStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder2.IO { get }
    var finishTypes: SendFinishStepBuilder2.Types { get }
    var finishDependencies: SendFinishStepBuilder2.Dependencies { get }
}

extension SendFinishStepBuildable {
    func makeSendFinishStep(
        sendAmountCompactViewModel: SendAmountCompactViewModel? = nil,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel? = nil,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel? = nil,
        sendFeeCompactViewModel: SendFeeCompactViewModel? = nil,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel? = nil,
        router: SendRoutable,
    ) -> SendFinishStepBuilder2.ReturnValue {
        SendFinishStepBuilder2.make(
            io: finishIO, types: finishTypes,
            dependencies: finishDependencies,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel,
            router: router,
        )
    }
}

enum SendFinishStepBuilder2 {
    struct IO {
        let input: SendFinishInput
    }

    struct Types {
        let tokenItem: TokenItem
    }

    struct Dependencies {
        let analyticsLogger: any SendFinishAnalyticsLogger
    }

    typealias ReturnValue = SendFinishStep

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?,
        router: SendRoutable,
    ) -> ReturnValue {
        let viewModel = SendFinishViewModel(
            input: io.input,
            tokenItem: types.tokenItem,
            sendFinishAnalyticsLogger: dependencies.analyticsLogger,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel,
            coordinator: router
        )

        let step = SendFinishStep(viewModel: viewModel)
        return step
    }
}
