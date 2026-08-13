//
//  CryptoAccountsNetworkMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for how `CryptoAccountsNetworkMapper` reads account types and per-type counters")
struct CryptoAccountsNetworkMapperTests {
    @Test("An account the endpoint marks joint is stored as one, and an account it marks otherwise as a crypto one")
    func accountTypesAreMapped() throws {
        let info = try map(response: Fixtures.responseWithoutPerTypeCounters)

        #expect(info.accounts.map(\.derivationIndex) == [0, 1, 2])
        // An account with no type at all and an account with a type this version does not know are both crypto accounts
        #expect(info.accounts.map(\.type) == [.crypto, .joint, .crypto])
    }

    @Test("Absent per-type counters stand in for the crypto one only, leaving the joint one with no count")
    func absentPerTypeCountersStandInForCryptoOnly() throws {
        let info = try map(response: Fixtures.responseWithoutPerTypeCounters)

        #expect(info.counters.crypto == 3)
        #expect(info.counters.joint == nil)
    }

    @Test("Per-type counters are taken as reported once the endpoint has them")
    func reportedPerTypeCountersAreTaken() throws {
        let info = try map(response: Fixtures.responseWithPerTypeCounters)

        #expect(info.counters.crypto == 2)
        #expect(info.counters.joint == 1)
    }
}

// MARK: - Helpers

private extension CryptoAccountsNetworkMapperTests {
    func map(response json: String) throws -> RemoteCryptoAccountsInfo {
        let response = try JSONDecoder().decode(AccountsDTO.Response.Accounts.self, from: Data(json.utf8))
        let mapper = CryptoAccountsNetworkMapper(supportedBlockchains: [], remoteIdentifierBuilder: { _ in "" })

        return mapper.map(response: response)
    }
}

// MARK: - Fixtures

private extension CryptoAccountsNetworkMapperTests {
    enum Fixtures {
        static let responseWithoutPerTypeCounters = """
        {
          "wallet": {
            "version": 1,
            "group": "network",
            "sort": "manual",
            "totalAccounts": 3,
            "totalArchivedAccounts": 0
          },
          "accounts": [
            { "id": "id-0", "name": "Main", "icon": "Star", "iconColor": "Azure", "derivation": 0, "tokens": [] },
            { "id": "id-1", "name": "Family", "icon": "Star", "iconColor": "Azure", "derivation": 1, "type": "joint", "tokens": [] },
            { "id": "id-2", "name": "Other", "icon": "Star", "iconColor": "Azure", "derivation": 2, "type": "shared", "tokens": [] }
          ],
          "unassignedTokens": []
        }
        """

        static let responseWithPerTypeCounters = """
        {
          "wallet": {
            "version": 1,
            "group": "network",
            "sort": "manual",
            "totalAccounts": 3,
            "totalArchivedAccounts": 0,
            "totalCryptoAccounts": 2,
            "totalJointAccounts": 1
          },
          "accounts": [],
          "unassignedTokens": []
        }
        """
    }
}
