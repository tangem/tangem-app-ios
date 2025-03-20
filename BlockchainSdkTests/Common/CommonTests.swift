//
//  CommonTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import BigInt
@testable import BlockchainSdk

struct CommonTests {
    @Test
    func hexStringExtensions() {
        #expect("0xaabbccdd".hasHexPrefix())
        #expect("0xAABBCC".hasHexPrefix())
        #expect(!"aabbccdd".hasHexPrefix())
        #expect("aabbccdd".addHexPrefix() == "0xaabbccdd")
        #expect("AABBCCdd".addHexPrefix() == "0xAABBCCdd")
        #expect("0xaabbccdd".addHexPrefix() == "0xaabbccdd")
        #expect("0xaabbccdd".removeHexPrefix() == "aabbccdd")
        #expect("0xAABBCCdd".removeHexPrefix() == "AABBCCdd")
        #expect("AABBCCdd".removeHexPrefix() == "AABBCCdd")
    }

    @Test
    func overflow() {
        let max = BigUInt(18446744073709551615)
        let eth = Blockchain.ethereum(testnet: false)
        let calculated = Decimal(UInt64(max)) / eth.decimalValue
        let estimated = Decimal(string: "18.446744073709551615")
        #expect(calculated == estimated)
    }
}
