//
//  StakingFlowPropertiesTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
@testable import Tangem

@Suite("StakingFlowProperties")
struct StakingFlowPropertiesTests {
    @Test("Stake amount is editable everywhere except Cardano")
    func isStakeAmountEditable() {
        #expect(properties(.cardano(extended: true)).isStakeAmountEditable == false)
        #expect(properties(.solana(curve: .ed25519, testnet: false)).isStakeAmountEditable == true)
        #expect(properties(.ton(curve: .ed25519, testnet: false)).isStakeAmountEditable == true)
    }

    @Test("Only TON reserves an extra fee")
    func reservedFee() {
        #expect(properties(.ton(curve: .ed25519, testnet: false)).reservedFee == Decimal(string: "0.2")!)
        #expect(properties(.solana(curve: .ed25519, testnet: false)).reservedFee == .zero)
    }

    @Test("Only Cardano requires a staking deposit")
    func stakingDeposit() {
        #expect(properties(.cardano(extended: true)).stakingDeposit == 2)
        #expect(properties(.tron(testnet: false)).stakingDeposit == 0)
    }

    @Test("Solana does not support zero-balance operations")
    func supportsZeroBalanceOperations() {
        #expect(properties(.solana(curve: .ed25519, testnet: false)).supportsZeroBalanceOperations == false)
        #expect(properties(.tron(testnet: false)).supportsZeroBalanceOperations == true)
    }

    @Test("Partial unstake is disabled for TON and Cardano, allowed elsewhere")
    func supportsPartialUnstake() {
        #expect(properties(.ton(curve: .ed25519, testnet: false)).supportsPartialUnstake == false)
        #expect(properties(.cardano(extended: true)).supportsPartialUnstake == false)
        #expect(properties(.solana(curve: .ed25519, testnet: false)).supportsPartialUnstake == true)
        #expect(properties(.tron(testnet: false)).supportsPartialUnstake == true)
    }

    private func properties(_ blockchain: Blockchain) -> StakingFlowProperties {
        StakingFlowProperties(blockchain: blockchain)
    }
}
