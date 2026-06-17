//
//  SolanaStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// Solana native multi-validator staking: editable stake amount, validator selection, partial unstake,
/// no approval or account-initialization prerequisite. Pure common path.
struct SolanaStakingFlowProvider: CommonStakingFlow {
    let action: StakingAction
    let stages: StakingFlowStages

    var isStakeAmountEditable: Bool { true }
    var chainAllowsPartialUnstake: Bool { true }
}
