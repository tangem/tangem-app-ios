//
//  PolkadotDecodingTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import ScaleCodec
import BigInt
@testable import BlockchainSdk

/// These tests are needed because ScaleCodec decodes Data using little-endian,
/// but `BigUInt.init`  interprets those bytes as big-endian. That is why we need to check that everything is parsed correctly
struct PolkadotDecodingTests {
    @Test
    func decodePolkadotAccountData() throws {
        // given
        let bytesToDecode = Data(hex: "50d5893bd60f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
        // This is bytesToDecode.reversed()
        let reversedBytes = Data(hex: "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fd63b89d550")
        let refBigUInt = BigUInt(reversedBytes)

        // when
        let decodedData = try decode(PolkadotAccountData.self, from: bytesToDecode)

        // then
        #expect(decodedData.free == refBigUInt)
    }

    @Test
    func decodePolkadotQueriedInfo() throws {
        // given
        let additionalBytes = Data(hex: String(repeating: "00", count: 3))
        let partialFeeBytes = Data(hex: "61b69509000000000000000000000000")

        // This is partialFeeBytes.reversed()
        let partialFeeBytesReversed = Data(hex: "0000000000000000000000000995b661")
        let refBigUInt = BigUInt(partialFeeBytesReversed)

        // when
        let decodedData = try decode(PolkadotQueriedInfo.self, from: additionalBytes + partialFeeBytes)

        // then
        #expect(decodedData.partialFee == refBigUInt)
    }
}
