//
//  YieldWithdrawalBatchingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Testing
@testable import Tangem

@Suite("YieldWithdrawalClaimBatching")
struct YieldWithdrawalClaimBatchingTests {
    @Test("Avalanche keeps the two-step withdrawal")
    func avalancheIsExcluded() {
        #expect(!YieldWithdrawalClaimBatching.isSupported(blockchain: .avalanche(testnet: false)))
    }

    @Test("Every other Yield Mode chain batches the claim into the exit, Monad above all")
    func everyOtherYieldChainBatches() {
        let chains: [Blockchain] = [
            .ethereum(testnet: false),
            .arbitrum(testnet: false),
            .optimism(testnet: false),
            .base(testnet: false),
            .bsc(testnet: false),
            .polygon(testnet: false),
            .monad(testnet: false),
        ]

        for chain in chains {
            #expect(YieldWithdrawalClaimBatching.isSupported(blockchain: chain), "\(chain.displayName)")
        }
    }

    @Test("The list denies rather than permits, so a chain nobody listed still batches")
    func anUnlistedChainStillBatches() {
        #expect(YieldWithdrawalClaimBatching.isSupported(blockchain: .gnosis))
    }
}

@Suite("YieldExitResult")
struct YieldExitResultTests {
    @Test("Without a claim leg the single hash is the exit's")
    func exitAloneOwnsTheOnlyHash() {
        let result = YieldExitResult(hashes: ["0xexit"], hasPrecedingTransaction: false)

        #expect(result.exitHash == "0xexit")
        #expect(result.precedingHash == nil)
    }

    @Test("With a claim leg in front the exit is the second hash, never the first")
    func claimLeadsAndTheExitFollows() {
        let result = YieldExitResult(hashes: ["0xclaim", "0xexit"], hasPrecedingTransaction: true)

        #expect(result.precedingHash == "0xclaim")
        #expect(result.exitHash == "0xexit")
    }

    @Test("Defensive: a truncated hash list reports no exit rather than the claim's hash")
    func aTruncatedHashListIsDefensiveOnly() {
        let result = YieldExitResult(hashes: ["0xclaim"], hasPrecedingTransaction: true)

        #expect(result.precedingHash == "0xclaim")
        #expect(result.exitHash == nil)
    }

    @Test("Defensive: no hashes at all report neither leg")
    func anEmptyHashListIsDefensiveOnly() {
        let result = YieldExitResult(hashes: [], hasPrecedingTransaction: true)

        #expect(result.precedingHash == nil)
        #expect(result.exitHash == nil)
    }
}
