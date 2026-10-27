//
//  SolanaNFTMetadataBuilder.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

struct SolanaNFTMetadataBuilder {
    var tokenStandard: UInt8?
    var ruleSet: PublicKey? = PublicKey(string: SolanaNFTFixtures.Programmable.ruleSet)
    var truncatesAfterEditionNonce = false

    static let tokenStandardOptionOffset = 148

    func build() -> Data {
        var data = Data([4])
        data += Data(repeating: 1, count: 32)
        data += Data(repeating: 2, count: 32)
        data += string("Name")
        data += string("SYM")
        data += string("https://example.com")
        data += Data([0xF4, 0x01])
        data += Data([1]) + UInt32(1).littleEndianData + Data(repeating: 3, count: 32) + Data([1, 100])
        data += Data([1, 1])
        data += Data([1, 255])

        if truncatesAfterEditionNonce {
            return data
        }

        data += tokenStandard.map { Data([1, $0]) } ?? Data([0])
        data += Data([1, 1]) + Data(repeating: 5, count: 32)
        data += Data([0])
        data += Data([0])
        data += Data([1, 0]) + (ruleSet.map { Data([1]) + $0.data } ?? Data([0]))
        data += Data(repeating: 0, count: 16)

        return data
    }

    private func string(_ value: String) -> Data {
        UInt32(value.utf8.count).littleEndianData + Data(value.utf8)
    }
}

private extension UInt32 {
    var littleEndianData: Data {
        withUnsafeBytes(of: littleEndian) { Data($0) }
    }
}
