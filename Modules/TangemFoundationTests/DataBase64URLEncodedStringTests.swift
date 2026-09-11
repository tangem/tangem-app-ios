//
//  DataBase64URLEncodedStringTests.swift
//  TangemFoundationTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite
struct DataBase64URLEncodedStringTests {
    @Test
    func emptyDataEncodesToEmptyString() {
        #expect(Data().base64URLEncodedString == "")
    }

    @Test
    func substitutesAlphabetAndStripsPadding() {
        #expect(Data([0xF8, 0x00]).base64URLEncodedString == "-AA")
    }

    @Test(
        arguments: [
            Data(),
            Data([0x01]),
            Data([0x01, 0x02]),
            Data([0x01, 0x02, 0x03]),
            Data((0 ... 255).map { UInt8($0) }),
        ]
    )
    func roundTripsThroughExistingDecoder(originalData: Data) throws {
        let encoded = originalData.base64URLEncodedString

        #expect(!encoded.contains("+"))
        #expect(!encoded.contains("/"))
        #expect(!encoded.contains("="))

        let decoded = try #require(encoded.base64URLDecodedData())
        #expect(decoded == originalData)
    }
}
