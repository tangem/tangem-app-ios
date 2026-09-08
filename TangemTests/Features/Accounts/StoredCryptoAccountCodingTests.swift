//
//  StoredCryptoAccountCodingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

// MARK: - Tests

@Suite("Tests for how `StoredCryptoAccount` reads the account type")
struct StoredCryptoAccountCodingTests {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    @Test("A record written before account types existed reads as a crypto account")
    func recordWithoutTypeReadsAsCrypto() throws {
        // The shape a previous version wrote: the very same record, minus the field it did not know about
        let preKindsRecord = try data(of: Fixtures.crypto, replacingTypeWith: nil)

        let decoded = try decoder.decode(StoredCryptoAccount.self, from: preKindsRecord)

        #expect(decoded == Fixtures.crypto)
        #expect(decoded.derivationIdentity.type == .crypto)
    }

    @Test("A record carries its type from the moment it is written")
    func recordIsWrittenWithItsType() throws {
        let object = try Fixtures.crypto.asDictionary(encoder: encoder)

        #expect(object["type"] as? String == "crypto")
    }

    @Test("A joint record survives a round trip")
    func jointRecordRoundTrips() throws {
        let account = Fixtures.joint

        let decoded = try decoder.decode(StoredCryptoAccount.self, from: encoder.encode(account))

        #expect(decoded == account)
        #expect(decoded.derivationIdentity.type == .joint)
    }

    @Test("A record that spells the type out as null reads as a crypto account, the same as a record that omits it")
    func recordWithNullTypeReadsAsCrypto() throws {
        let spelledOut = try data(of: Fixtures.joint, replacingTypeWith: NSNull())

        let decoded = try decoder.decode(StoredCryptoAccount.self, from: spelledOut)

        #expect(decoded.derivationIdentity.type == .crypto)
    }

    @Test("A type this version cannot read is a crypto account rather than a failure")
    func unreadableTypeIsReadAsCrypto() throws {
        let unknownName = try data(of: Fixtures.joint, replacingTypeWith: "shared")
        let anotherShape = try data(of: Fixtures.joint, replacingTypeWith: 123)

        let decodedUnknownName = try decoder.decode(StoredCryptoAccount.self, from: unknownName)
        let decodedAnotherShape = try decoder.decode(StoredCryptoAccount.self, from: anotherShape)

        #expect(decodedUnknownName.derivationIdentity.type == .crypto)
        #expect(decodedAnotherShape.derivationIdentity.type == .crypto)
    }

    /// The storage reads the whole list at once and takes a failed read for an empty one, which sends a wallet that has
    /// accounts through the legacy migration — so one unreadable type must not cost the rest of the list.
    @Test("A list decodes as a whole even when one record carries an unreadable type")
    func listSurvivesAnUnreadableType() throws {
        let records = [
            try object(of: Fixtures.joint, replacingTypeWith: "shared"),
            try object(of: Fixtures.crypto, replacingTypeWith: nil),
        ]
        let list = try JSONSerialization.data(withJSONObject: records)

        let decoded = try decoder.decode([StoredCryptoAccount].self, from: list)

        #expect(decoded.count == 2)
        #expect(decoded.map(\.derivationIdentity.type) == [.crypto, .crypto])
    }
}

// MARK: - Helpers

private extension StoredCryptoAccountCodingTests {
    /// Rewrites an encoded record the way another version would have written it: one that knows a different type,
    /// or — given nil — one from before the types existed.
    func object(of account: StoredCryptoAccount, replacingTypeWith type: Any?) throws -> [String: Any] {
        var object = try account.asDictionary(encoder: encoder)
        object["type"] = type

        return object
    }

    func data(of account: StoredCryptoAccount, replacingTypeWith type: Any?) throws -> Data {
        try JSONSerialization.data(withJSONObject: object(of: account, replacingTypeWith: type))
    }
}

// MARK: - Fixtures

private extension StoredCryptoAccountCodingTests {
    enum Fixtures {
        static let icon = StoredCryptoAccount.Icon(
            iconName: AccountModel.CompositeIcon.Name.star.rawValue,
            iconColor: AccountModel.CompositeIcon.Color.azure.rawValue
        )

        static let crypto = StoredCryptoAccount(
            derivationIndex: 0,
            type: .crypto,
            name: nil,
            icon: icon,
            tokens: [],
            grouping: .none,
            sorting: .manual
        )

        static let joint = StoredCryptoAccount(
            derivationIndex: 1,
            type: .joint,
            name: "Family",
            icon: icon,
            tokens: [],
            grouping: .byBlockchainNetwork,
            sorting: .byBalance
        )
    }
}
