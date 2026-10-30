//
//  PolymarketSessionKeySignatureTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket session key signature", .timeLimit(.minutes(1)))
struct PolymarketSessionKeySignatureTests {
    @Test("The envelope names the session key, offsets the wallet signature past three words and ends with the magic suffix")
    func envelopeLayout() throws {
        let envelope = try PolymarketSessionKeySignature.envelope(
            depositWalletSignature: "0x" + String(repeating: "AB", count: 65),
            sessionKeyAddress: Fixtures.sessionKey
        )

        #expect(envelope == "0x"
            + "0000000000000000000000005e55000000000000000000000000000000000001"
            + "0000000000000000000000000000000000000000000000000000000000000000"
            + "0000000000000000000000000000000000000000000000000000000000000060"
            + "0000000000000000000000000000000000000000000000000000000000000041"
            + "abababababababababababababababababababababababababababababababab"
            + "abababababababababababababababababababababababababababababababab"
            + "ab00000000000000000000000000000000000000000000000000000000000000"
            + "6492649264926492649264926492649264926492649264926492649264926492")
    }

    @Test("A signature that already fills whole words gets no padding before the magic suffix")
    func alignedSignatureIsNotPadded() throws {
        let envelope = try PolymarketSessionKeySignature.envelope(
            depositWalletSignature: "0x" + String(repeating: "cd", count: 64),
            sessionKeyAddress: Fixtures.sessionKey
        )

        #expect(envelope == "0x"
            + "0000000000000000000000005e55000000000000000000000000000000000001"
            + "0000000000000000000000000000000000000000000000000000000000000000"
            + "0000000000000000000000000000000000000000000000000000000000000060"
            + "0000000000000000000000000000000000000000000000000000000000000040"
            + "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd"
            + "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd"
            + "6492649264926492649264926492649264926492649264926492649264926492")
    }

    @Test("A malformed session key is refused instead of being named in the envelope", arguments: [
        "",
        "5E55000000000000000000000000000000000001",
        "0x5E550000000000000000000000000000000001",
        "0x" + String(repeating: "z", count: 40),
    ])
    func malformedSessionKeyIsRefused(_ address: String) {
        #expect(throws: PolymarketSessionKeySignatureError.invalidAddress(address)) {
            try PolymarketSessionKeySignature.envelope(depositWalletSignature: Fixtures.signature, sessionKeyAddress: address)
        }
    }

    @Test("A signature that is not whole bytes of ASCII hex is refused instead of being wrapped", arguments: [
        "",
        "0x",
        "0xabc",
        "0x" + String(repeating: "zz", count: 65),
        "0x" + String(repeating: "ａｂ", count: 65),
    ])
    func malformedSignatureIsRefused(_ signature: String) {
        #expect(throws: PolymarketSessionKeySignatureError.invalidSignature) {
            try PolymarketSessionKeySignature.envelope(depositWalletSignature: signature, sessionKeyAddress: Fixtures.sessionKey)
        }
    }
}

// MARK: - Fixtures

private enum Fixtures {
    static let sessionKey = "0x5E55000000000000000000000000000000000001"
    static let signature = "0x" + String(repeating: "ab", count: 65)
}
