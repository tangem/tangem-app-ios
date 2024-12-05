//
//  StakingFinishAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct StakingFinishAnalyticsLogger: SendFinishAnalyticsLogger {
    private let tokenItem: TokenItem
    private let actionType: SendFlowActionType
    private weak var stakingValidatorsInput: StakingValidatorsInput?

    init(
        tokenItem: TokenItem,
        actionType: SendFlowActionType,
        stakingValidatorsInput: StakingValidatorsInput
    ) {
        self.tokenItem = tokenItem
        self.actionType = actionType
        self.stakingValidatorsInput = stakingValidatorsInput
    }

    func onAppear() {
        guard let stakingAnalyticsAction = actionType.stakingAnalyticsAction else {
            return
        }

        Analytics.log(event: .stakingStakeInProgressScreenOpened, params: [
            .validator: stakingValidatorsInput?.selectedValidator?.name ?? "",
            .token: tokenItem.currencySymbol,
            .action: stakingAnalyticsAction.rawValue,
        ])
    }
}
