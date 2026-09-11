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

/// The creation vector below is shared with Android and the backend: the same payload has to canonicalise to the same
/// bytes and hash to the same digest everywhere, because the endpoint verifies the signature against its own canonical
/// form of what it receives. A divergence here rejects every signature this platform produces. Joining and activating
/// have no vector of their own yet, so what is pinned for them is the layout this side lays them out in.
@Suite("Tests for the form a joint account's requests are signed in")
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

    @Test("Joining lays the invite, the settings and the member out side by side")
    func joinPayloadCanonicalises() throws {
        let canonical = try JointAccountDerivationUtils.canonicalPayload(of: Constants.joinPayload)

        #expect(String(decoding: canonical, as: UTF8.self) == Constants.expectedCanonicalJoinPayload)
    }

    @Test("Activating puts the address inside the settings rather than beside them")
    func activationPayloadCanonicalises() throws {
        let canonical = try JointAccountDerivationUtils.canonicalPayload(of: Constants.activationPayload)

        #expect(String(decoding: canonical, as: UTF8.self) == Constants.expectedCanonicalActivationPayload)
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
        static let config = JointAccountSignedConfig(
            name: "Family",
            icon: "Family",
            iconColor: "Azure",
            membersCount: 3,
            threshold: 2
        )

        static let vectorPayload = JointAccountCreationPayload(
            config: config,
            creator: JointAccountSignedMember(
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

        static let joinPayload = JointAccountJoinPayload(
            inviteId: "7C1D5E9B3A8F2064D7E1C3A5B9F8027E4C6A1D3B5F7092E4C6A8D0B2F4E6A801",
            config: config,
            member: JointAccountSignedMember(
                walletId: "9A3E7C1B5D2F8064A2C4E6B8D0F2A4C6E8B0D2F4A6C8E0B2D4F6A8C0E2B4D6F8",
                name: "Bob",
                address: "0x2b5aD9c1E7F40638B2c1A9d3E5F70241C6b8A91c",
                derivation: 7
            )
        )

        static let expectedCanonicalJoinPayload = """
        {"config":{"icon":"Family","iconColor":"Azure","membersCount":3,"name":"Family","threshold":2},\
        "inviteId":"7C1D5E9B3A8F2064D7E1C3A5B9F8027E4C6A1D3B5F7092E4C6A8D0B2F4E6A801",\
        "member":{"address":"0x2b5aD9c1E7F40638B2c1A9d3E5F70241C6b8A91c","derivation":7,"name":"Bob",\
        "walletId":"9A3E7C1B5D2F8064A2C4E6B8D0F2A4C6E8B0D2F4A6C8E0B2D4F6A8C0E2B4D6F8"}}
        """

        static let activationPayload = JointAccountActivationPayload(
            walletId: "4B2F1C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A4B6C8D0E2F4A6",
            cryptoAccountId: "1D3F5A7C9E0B2D4F6A8C0E2B4D6F8A0C2E4B6D8F0A2C4E6B8D0F2A4C6E8B0D2F",
            config: JointAccountActivationPayload.Config(
                config: config,
                safeAddress: "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"
            )
        )

        static let expectedCanonicalActivationPayload = """
        {"config":{"icon":"Family","iconColor":"Azure","membersCount":3,"name":"Family",\
        "safeAddress":"0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b","threshold":2},\
        "cryptoAccountId":"1D3F5A7C9E0B2D4F6A8C0E2B4D6F8A0C2E4B6D8F0A2C4E6B8D0F2A4C6E8B0D2F",\
        "walletId":"4B2F1C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A4B6C8D0E2F4A6"}
        """
    }
}
