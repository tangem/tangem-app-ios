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

    @Test("A record written before account types existed keeps none, which stands for a crypto account")
    func recordWithoutTypeKeepsNone() throws {
        let account = Fixtures.untyped
        let object = try account.asDictionary(encoder: encoder)

        let decoded = try decoder.decode(StoredCryptoAccount.self, from: encoder.encode(account))

        #expect(decoded == account)
        #expect(decoded.type == nil)
        // The shape a previous version wrote, which is what makes such a record readable at all
        #expect(object["type"] == nil)
    }

    @Test("A joint record survives a round trip")
    func jointRecordRoundTrips() throws {
        let account = Fixtures.joint

        let decoded = try decoder.decode(StoredCryptoAccount.self, from: encoder.encode(account))

        #expect(decoded == account)
        #expect(decoded.type == .joint)
    }

    @Test("A record that spells the type out as null keeps no type, the same as a record that omits it")
    func recordWithNullTypeKeepsNone() throws {
        let spelledOut = try data(of: Fixtures.joint, replacingTypeWith: NSNull())

        let decoded = try decoder.decode(StoredCryptoAccount.self, from: spelledOut)

        #expect(decoded.type == nil)
    }

    @Test("A type this version cannot read is a crypto account rather than a failure")
    func unreadableTypeIsReadAsCrypto() throws {
        let unknownName = try data(of: Fixtures.joint, replacingTypeWith: "shared")
        let anotherShape = try data(of: Fixtures.joint, replacingTypeWith: 123)

        let decodedUnknownName = try decoder.decode(StoredCryptoAccount.self, from: unknownName)
        let decodedAnotherShape = try decoder.decode(StoredCryptoAccount.self, from: anotherShape)

        #expect(decodedUnknownName.type == .crypto)
        #expect(decodedAnotherShape.type == .crypto)
    }

    /// The storage reads the whole list at once and takes a failed read for an empty one, which sends a wallet that has
    /// accounts through the legacy migration — so one unreadable type must not cost the rest of the list.
    @Test("A list decodes as a whole even when one record carries an unreadable type")
    func listSurvivesAnUnreadableType() throws {
        let records = [
            try object(of: Fixtures.joint, replacingTypeWith: "shared"),
            try Fixtures.untyped.asDictionary(encoder: encoder),
        ]
        let list = try JSONSerialization.data(withJSONObject: records)

        let decoded = try decoder.decode([StoredCryptoAccount].self, from: list)

        #expect(decoded.count == 2)
        #expect(decoded.map(\.type) == [.crypto, nil])
    }
}

// MARK: - Helpers

private extension StoredCryptoAccountCodingTests {
    /// Rewrites an encoded record the way a version that knows another type would have written it.
    func object(of account: StoredCryptoAccount, replacingTypeWith type: Any) throws -> [String: Any] {
        var object = try account.asDictionary(encoder: encoder)
        object["type"] = type

        return object
    }

    func data(of account: StoredCryptoAccount, replacingTypeWith type: Any) throws -> Data {
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

        static let untyped = StoredCryptoAccount(
            derivationIndex: 0,
            name: nil,
            icon: icon,
            tokens: [],
            grouping: .none,
            sorting: .manual,
            type: nil
        )

        static let joint = StoredCryptoAccount(
            derivationIndex: 1,
            name: "Family",
            icon: icon,
            tokens: [],
            grouping: .byBlockchainNetwork,
            sorting: .byBalance,
            type: .joint
        )
    }
}
