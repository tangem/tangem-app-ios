//
//  EthereumUtilsTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
@testable import BlockchainSdk
import Testing
import Foundation

@Suite("EthereumUtils Tests")
struct EthereumUtilsTests {
    // MARK: - mapToBigUInt

    @Test
    func mapToBigUIntZeroReturnsZero() {
        #expect(EthereumUtils.mapToBigUInt(.zero) == .zero)
    }

    @Test
    func mapToBigUIntGreatestFiniteMagnitudeReturnsMaxUInt256() {
        #expect(EthereumUtils.mapToBigUInt(.greatestFiniteMagnitude) == BigUInt(2).power(256) - 1)
    }

    @Test
    func mapToBigUIntSmallValueIsExact() {
        #expect(EthereumUtils.mapToBigUInt(Decimal(1_000_000)) == BigUInt(1_000_000))
    }

    /// Regression: [REDACTED_INFO]. Going through `Decimal.uint64Value` used to silently
    /// truncate values above `2^64 - 1` to `value mod 2^64`, which broke
    /// `approve(specified)` calldata for 18-decimal ERC-20 tokens above ~18.446
    /// units (a 1Inch swap of 23.99 POL ended up as a 5.55 POL allowance).
    @Test
    func mapToBigUIntPreservesValuesAboveUInt64() {
        // 23.992630803268789361 POL × 10^18 = 23992630803268789361 wei.
        let result = EthereumUtils.mapToBigUInt(Decimal(stringValue: "23992630803268789361")!)

        #expect(result == BigUInt("23992630803268789361"))
        // The previous, buggy code path produced `value mod 2^64` for the same input.
        #expect(result != BigUInt("5545886729559237745"))
    }

    @Test
    func mapToBigUIntPreservesLargeValuesNearUInt256() {
        // 10^27 wei — well above 2^64 ≈ 1.84 × 10^19, well below 2^256 - 1.
        let result = EthereumUtils.mapToBigUInt(Decimal(stringValue: "1000000000000000000000000000")!)
        #expect(result == BigUInt("1000000000000000000000000000"))
    }

    @Test
    func mapToBigUIntRoundsFractionalDown() {
        // Matches the existing `.rounded()` default (scale = 0, mode = .down).
        #expect(EthereumUtils.mapToBigUInt(Decimal(stringValue: "100.9")!) == BigUInt(100))
    }
}
