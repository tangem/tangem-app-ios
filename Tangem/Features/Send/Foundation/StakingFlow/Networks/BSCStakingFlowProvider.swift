//
//  BSCStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// BSC (BNB) native staking. Editable stake amount, validator selection, partial unstake.
struct BSCStakingFlowProvider: GenericStakingFlowProvider {
    let action: StakingAction
    let stages: StakeStagesResolver

    var isStakeAmountEditable: Bool { true }
    var chainAllowsPartialUnstake: Bool { true }
}
