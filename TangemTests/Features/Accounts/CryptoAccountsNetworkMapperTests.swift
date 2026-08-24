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
    @Test("An account is stored with the kind the endpoint gave it, and with none at all when it gave none it can place")
    func accountTypesAreMapped() throws {
        let info = try map(response: Fixtures.responseWithoutPerTypeCounters)

        #expect(info.accounts.map(\.derivationIndex) == [0, 1, 2])
        // Guessing a kind for the first and the last would put that guess in the next save and overwrite the endpoint's
        #expect(info.accounts.map(\.type) == [nil, .joint, nil])
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

    @Test("Every account tells the endpoint its kind, and one stored before the kind was says nothing")
    func accountTypesAreWritten() throws {
        let types = try map(request: [
            Fixtures.storedAccount(derivationIndex: 0, type: .crypto),
            Fixtures.storedAccount(derivationIndex: 1, type: .joint),
            Fixtures.storedAccount(derivationIndex: 2, type: nil),
        ])

        #expect(types == ["crypto", "joint", nil])
    }
}

// MARK: - Helpers

private extension CryptoAccountsNetworkMapperTests {
    func map(response json: String) throws -> RemoteCryptoAccountsInfo {
        let response = try JSONDecoder().decode(AccountsDTO.Response.Accounts.self, from: Data(json.utf8))
        let mapper = CryptoAccountsNetworkMapper(supportedBlockchains: [], remoteIdentifierBuilder: { _ in "" })

        return mapper.map(response: response)
    }

    /// - Returns: The account kinds as they appear on the wire, an absent one included, which is what the hand-written
    /// encoder decides.
    func map(request accounts: [StoredCryptoAccount]) throws -> [String?] {
        let externalParametersProvider = TokenListAddressesProviderStub()
        let mapper = CryptoAccountsNetworkMapper(
            supportedBlockchains: [],
            remoteIdentifierBuilder: { "id-\($0.derivationIndex)" }
        )
        mapper.externalParametersProvider = externalParametersProvider

        // The mapper holds the provider weakly and traps without one, so the stub has to be kept alive across the call
        let request = withExtendedLifetime(externalParametersProvider) { mapper.map(request: accounts).accounts }
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]

        return (encoded?["accounts"] as? [[String: Any]])?.map { $0["type"] as? String } ?? []
    }
}

private final class TokenListAddressesProviderStub: UserTokenListExternalParametersProvider {
    func provideTokenListAddresses() -> [WalletModelId: [String]]? { [:] }
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

        static func storedAccount(derivationIndex: Int, type: AccountType?) -> StoredCryptoAccount {
            StoredCryptoAccount(
                derivationIndex: derivationIndex,
                name: "Account \(derivationIndex)",
                icon: StoredCryptoAccount.Icon(iconName: "Star", iconColor: "Azure"),
                tokens: [],
                grouping: .none,
                sorting: .manual,
                type: type
            )
        }
    }
}
