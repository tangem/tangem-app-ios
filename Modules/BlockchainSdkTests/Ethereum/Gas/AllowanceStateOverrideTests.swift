//
//  AllowanceStateOverrideTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BigInt
@testable import BlockchainSdk

struct AllowanceStateOverrideTests {
    /// On-chain–verified golden vector: USDC on Polygon, base slot 10. This is the strongest guarantee
    /// our hash is *real* keccak256 — a manual re-derivation using the same wrong hash would still pass.
    @Test
    func storageKeyMatchesOnChainVerifiedUSDCPolygon() {
        let owner = "0xE43516ce4Bc0CaE629dC5608BdfcFE0EdD4468fe"
        let spender = "0x4cD00E387622C35bDDB9b4c962C136462338BC31"
        let expected = "0xd44cd0bb81b8c13f5509fb4769f894d9fd73411d2ba39aaada5059e235722aa8"

        let key = AllowanceSlot.solidity(10).storageKey(owner: owner, spender: spender)

        #expect("0x" + key.hex() == expected)
    }

    /// Re-derives the OZ v5 ERC-7201 `_allowances` slot from the namespace string and confirms it matches
    /// our hardcoded `AllowanceSlot.ozV5ERC20Allowances`. Second independent pin of keccak256.
    @Test
    func erc7201BaseMatchesHardcodedOzV5Allowances() {
        let derived = AllowanceSlot.erc7201Base(namespace: "openzeppelin.storage.ERC20", offsetInStruct: 1)

        #expect(derived == AllowanceSlot.ozV5ERC20Allowances)
    }
}
