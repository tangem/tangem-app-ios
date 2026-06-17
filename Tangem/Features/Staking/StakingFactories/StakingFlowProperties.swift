//
//  StakingFlowProperties.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

/// Flow-shaping, per-chain staking traits read by the V2 staking flow (`StakeModel` / `StakeFactory`).
///
/// Keyed on `Blockchain`. This is the app-side home for the traits the legacy `StakingBlockchainParams`
/// exposes; the two coexist while `stakingFlowV2` is behind a toggle and are unified once the legacy
/// flow is removed.
struct StakingFlowProperties {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    var isStakeAmountEditable: Bool {
        switch blockchain {
        case .cardano: false
        default: true
        }
    }

    var stakingDeposit: UInt64 {
        switch blockchain {
        case .cardano: 2
        default: 0
        }
    }

    var stakingDepositAmount: UInt64 {
        stakingDeposit * blockchain.decimalValue.uint64Value
    }

    var reservedFee: Decimal {
        switch blockchain {
        case .ton: Decimal(string: "0.2")!
        default: .zero
        }
    }

    var supportsZeroBalanceOperations: Bool {
        switch blockchain {
        case .solana: false
        default: true
        }
    }

    /// The chain half of "is partial unstake allowed". The runtime half (validator `preferred`)
    /// is combined by the caller (see `CommonStakingFlow.isPartialUnstakeAllowed`).
    var supportsPartialUnstake: Bool {
        switch blockchain {
        case .ton, .cardano: false
        default: true
        }
    }
}
