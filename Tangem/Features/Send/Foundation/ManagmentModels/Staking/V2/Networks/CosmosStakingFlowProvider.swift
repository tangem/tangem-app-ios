//
//  CosmosStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// Cosmos native staking. Editable stake amount, validator selection, partial unstake. The Cosmos
/// public-key requirement is handled in the SDK/manager layer, not the flow.
struct CosmosStakingFlowProvider: CommonStakingFlow {
    let action: StakingAction
    let stages: StakingFlowStages

    var isStakeAmountEditable: Bool { true }
    var chainAllowsPartialUnstake: Bool { true }
}
