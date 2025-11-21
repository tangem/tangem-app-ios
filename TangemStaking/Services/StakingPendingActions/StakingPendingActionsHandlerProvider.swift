//
//  StakingPendingActionsHandlerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingPendingActionsHandlerProvider {
    public func makeStakingPendingActionsHandler(network: StakingNetworkType) -> StakingPendingActionsHandler {
        switch network {
        case .ton: TonStakingPendingActionsHandler()
        default: CommonStakingPendingActionsHandler()
        }
    }
}
