//
//  AccountTypeCodingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for `AccountType` coding")
struct AccountTypeCodingTests {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    @Test("Raw values are the names the endpoint reports and a stored record keeps")
    func rawValuesAreTheReportedNames() {
        #expect(AccountType.crypto.rawValue == "crypto")
        #expect(AccountType.joint.rawValue == "joint")
    }

    @Test("A known name decodes to its case")
    func knownNamesDecode() throws {
        let decoded = try decoder.decode([AccountType].self, from: Data(#"["crypto","joint"]"#.utf8))

        #expect(decoded == [.crypto, .joint])
    }

    @Test("A name this version does not know is read as a crypto account")
    func unknownNameIsReadAsCrypto() throws {
        let decoded = try decoder.decode([AccountType].self, from: Data(#"["shared","JOINT"]"#.utf8))

        #expect(decoded == [.crypto, .crypto])
    }

    @Test("A value that is no name at all is read as a crypto account")
    func valueOfAnotherShapeIsReadAsCrypto() throws {
        let decoded = try decoder.decode([AccountType].self, from: Data(#"[123,{"joint":{}}]"#.utf8))

        #expect(decoded == [.crypto, .crypto])
    }

    /// A record that spells the type out as null is another matter: an optional field is read with `decodeIfPresent`,
    /// which answers a null with no type at all and never reaches this decoding — see `StoredCryptoAccountCodingTests`.
    @Test("A null reaching this decoding is read as a crypto account")
    func nullIsReadAsCrypto() throws {
        let decoded = try decoder.decode([AccountType].self, from: Data(#"[null]"#.utf8))

        #expect(decoded == [.crypto])
    }

    @Test("Encoding stays the raw name, so what one version writes another reads as the same case")
    func encodingStaysTheRawName() throws {
        let encoded = try encoder.encode([AccountType.joint, .crypto])

        #expect(String(decoding: encoded, as: UTF8.self) == #"["joint","crypto"]"#)
        #expect(try decoder.decode([AccountType].self, from: encoded) == [.joint, .crypto])
    }
}
