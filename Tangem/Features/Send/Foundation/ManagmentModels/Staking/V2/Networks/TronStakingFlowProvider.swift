//
//  TronStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// Tron (TRX) native staking. Editable stake amount, validator selection, partial unstake. The Tron
/// resource type (energy/bandwidth) is handled in the SDK/manager layer, not the flow.
struct TronStakingFlowProvider: CommonStakingFlow {
    let action: StakingAction
    let stages: StakingFlowStages

    var isStakeAmountEditable: Bool { true }
    var chainAllowsPartialUnstake: Bool { true }
}
