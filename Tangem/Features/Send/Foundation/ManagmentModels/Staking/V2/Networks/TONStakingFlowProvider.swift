//
//  TONStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// TON pooled (Chorus One) staking. Editable stake amount, but no partial unstake. The extra TON
/// reserve check is a pre-flow precondition handled before the flow is opened, not here.
struct TONStakingFlowProvider: CommonStakingFlow {
    let action: StakingAction
    let stages: StakingFlowStages

    var isStakeAmountEditable: Bool { true }
    var chainAllowsPartialUnstake: Bool { false }
}
