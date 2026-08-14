//
//  JointAccountSignedPayloadTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

/// The vector below is shared with Android and the backend: the same payload has to canonicalise to the same bytes and
/// hash to the same digest everywhere, because the endpoint verifies the signature against its own canonical form of
/// what it receives. A divergence here rejects every signature this platform produces.
@Suite("Tests for the form a joint account's creation is signed in")
struct JointAccountSignedPayloadTests {
    @Test("The vector payload canonicalises to the shared bytes")
    func vectorPayloadCanonicalises() throws {
        let canonical = try JointAccountDerivationUtils.canonicalPayload(of: Constants.vectorPayload)

        #expect(String(decoding: canonical, as: UTF8.self) == Constants.expectedCanonicalPayload)
    }

    @Test("The vector payload hashes to the shared digest")
    func vectorPayloadDigests() throws {
        let digest = try JointAccountDerivationUtils.digest(payload: Constants.vectorPayload)

        #expect(digest.hexString.lowercased() == Constants.expectedDigest)
    }

    @Test("Properties are ordered by name")
    func propertiesAreOrderedByName() throws {
        let canonical = try JointAccountDerivationUtils.canonicalPayload(of: ["b": 1, "a": 2, "C": 3])

        #expect(String(decoding: canonical, as: UTF8.self) == #"{"C":3,"a":2,"b":1}"#)
    }

    @Test("A quote and a backslash are escaped, a slash is not")
    func stringsAreEscapedTheWayTheSpecAsks() throws {
        let canonical = try JointAccountDerivationUtils.canonicalPayload(of: ["k": #"a/b"c\d"#])

        #expect(String(decoding: canonical, as: UTF8.self) == #"{"k":"a/b\"c\\d"}"#)
    }

    @Test("A control character becomes a four-digit escape")
    func controlCharactersAreEscaped() throws {
        let canonical = try JointAccountDerivationUtils.canonicalPayload(of: ["k": "a\u{01}b"])

        #expect(String(decoding: canonical, as: UTF8.self) == #"{"k":"a\u0001b"}"#)
    }

    @Test("Anything outside the ASCII range travels as itself")
    func nonASCIIIsNotEscaped() throws {
        let canonical = try JointAccountDerivationUtils.canonicalPayload(of: ["k": "Famille élargie 👨‍👩‍👧"])

        #expect(String(decoding: canonical, as: UTF8.self) == #"{"k":"Famille élargie 👨‍👩‍👧"}"#)
    }
}

// MARK: - Constants

private extension JointAccountSignedPayloadTests {
    enum Constants {
        static let vectorPayload = JointAccountCreationPayload(
            config: JointAccountCreationPayload.Config(
                name: "Family",
                icon: "Family",
                iconColor: "Azure",
                membersCount: 3,
                threshold: 2
            ),
            creator: JointAccountCreationPayload.Creator(
                walletId: "4B2F1C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A4B6C8D0E2F4A6",
                name: "Alice",
                address: "0xE31C6A9eE83A0f6f2e44dDcb9837B162802DeC12",
                derivation: 0
            )
        )

        static let expectedCanonicalPayload = """
        {"config":{"icon":"Family","iconColor":"Azure","membersCount":3,"name":"Family","threshold":2},\
        "creator":{"address":"0xE31C6A9eE83A0f6f2e44dDcb9837B162802DeC12","derivation":0,"name":"Alice",\
        "walletId":"4B2F1C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A4B6C8D0E2F4A6"}}
        """

        static let expectedDigest = "e6d9ac30fb18e01faba90cda8249f91ca17e427be57390f8f50964731eb753c2"
    }
}
