//
//  BLSUtilTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Testing
@testable import TangemHotSdk
import Foundation

struct PrivateInfoTests {
    @Test
    func testEncodeDecodeWithPassphrase() throws {
        let entropy = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        let passphrase = "test-passphrase"
        let privateInfo = PrivateInfo(entropy: entropy, passphrase: passphrase)

        let encoded = privateInfo.encode()
        let decoded = try #require(PrivateInfo(data: encoded))

        #expect(decoded.entropy == entropy)
        #expect(decoded.passphrase == passphrase)
    }

    @Test
    func testEncodeDecodeWithoutPassphrase() throws {
        let entropy = Data([0x0A, 0x0B, 0x0C])
        let privateInfo = PrivateInfo(entropy: entropy, passphrase: "")

        let encoded = privateInfo.encode()
        let decoded = try #require(PrivateInfo(data: encoded))

        #expect(decoded.entropy == entropy)
        #expect(decoded.passphrase == "")
    }

    @Test
    func testDecodeInvalidData() {
        let invalidData = Data([0x00, 0x01])

        let decoded = PrivateInfo(data: invalidData)

        #expect(decoded == nil)
    }
}
