//
//  EthereumP2PStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// Ethereum P2P liquid staking (native ETH, no ERC-20 approval). The P2P vault is modeled as the sole
/// staking target: it is auto-selected from the yield like any validator, so it shares the common
/// `CommonStakingFlow` shape (editable amount, validator selection, target carried into the action) and
/// only skips the approval stage. `P2PStakingManager` requires the vault address on the action, so the
/// target must ride along — hence the common path rather than a bespoke validator-less shape.
///
/// P2P uses its own backend (`P2PStakingManager`); those manager differences live in the SDK layer.
struct EthereumP2PStakingFlowProvider: CommonStakingFlow {
    let action: StakingAction
    let stages: StakingFlowStages

    var isStakeAmountEditable: Bool { true }
    var chainAllowsPartialUnstake: Bool { true }
}
