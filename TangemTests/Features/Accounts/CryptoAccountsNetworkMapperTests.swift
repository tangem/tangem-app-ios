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
    @Test("An account is stored with the kind the endpoint gave it, and a kind-less one as the wallet's own")
    func accountTypesAreMapped() throws {
        let info = try map(response: Fixtures.responseWithoutPerTypeCounters)

        #expect(info.accounts.map(\.derivationIdentity.derivationIndex) == [0, 1])
        // A record from before the kinds existed names none and is one of the wallet's own accounts;
        // an unknown kind is a contract violation and traps in the mapper, so there is no case for it here
        #expect(info.accounts.map(\.derivationIdentity.type) == [.crypto, .joint])
    }

    @Test("Absent per-type counters stand in for the crypto one only, leaving the joint one with no count")
    func absentPerTypeCountersStandInForCryptoOnly() throws {
        let info = try map(response: Fixtures.responseWithoutPerTypeCounters)

        #expect(info.counters.crypto == 2)
        #expect(info.counters.joint == nil)
    }

    @Test("While the joint accounts feature is off, the whole total is the only count read, whatever else the answer carries")
    func wholeTotalIsTheOnlyCountReadWhileTheFeatureIsOff() throws {
        let info = try map(response: Fixtures.responseWithPerTypeCounters)

        #expect(info.counters.crypto == 3)
        #expect(info.counters.joint == nil)
    }

    @Test("Without the joint accounts feature, an answer missing the whole total is turned away at decoding")
    func wholeTotalIsRequiredWhileTheFeatureIsOff() {
        // The decoding of `Wallet` expects the shape of the endpoint the feature decides, and unit tests
        // run with the joint accounts feature off — so the v1 shape, with the whole total, is the expected one
        #expect(throws: DecodingError.self) {
            try map(response: Fixtures.responseWithoutTotalAccounts)
        }
    }

    @Test("An answer counting neither the accounts as a whole nor their kinds is turned away at decoding")
    func answerCountingNeitherIsTurnedAway() {
        #expect(throws: DecodingError.self) {
            try map(response: Fixtures.responseWithoutAnyCounters)
        }
    }

    @Test("No account tells the endpoint its kind, whatever it has stored: the v1 endpoint turns away a row that mentions one")
    func accountTypesAreNotWritten() throws {
        let rows = try map(request: [
            Fixtures.storedAccount(derivationIndex: 0, type: .crypto),
            Fixtures.storedAccount(derivationIndex: 1, type: .joint),
        ])

        #expect(rows.count == 2)
        #expect(rows.allSatisfy { !$0.keys.contains("type") })
    }
}

// MARK: - Helpers

private extension CryptoAccountsNetworkMapperTests {
    func map(response json: String) throws -> RemoteCryptoAccountsInfo {
        let response = try JSONDecoder().decode(AccountsDTO.Response.Accounts.self, from: Data(json.utf8))
        let mapper = CryptoAccountsNetworkMapper(supportedBlockchains: [], remoteIdentifierBuilder: { _ in "" })

        return mapper.map(response: response)
    }

    /// - Returns: The account rows as they appear on the wire, so a test can tell a key that is absent from one
    /// encoded as `null` — which is what the hand-written encoder decides.
    func map(request accounts: [StoredCryptoAccount]) throws -> [[String: Any]] {
        let externalParametersProvider = TokenListAddressesProviderStub()
        let mapper = CryptoAccountsNetworkMapper(
            supportedBlockchains: [],
            remoteIdentifierBuilder: { "id-\($0.derivationIdentity.derivationIndex)" }
        )
        mapper.externalParametersProvider = externalParametersProvider

        // The mapper holds the provider weakly and traps without one, so the stub has to be kept alive across the call
        let request = withExtendedLifetime(externalParametersProvider) { mapper.map(request: accounts).accounts }
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]

        return (encoded?["accounts"] as? [[String: Any]]) ?? []
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
            "totalAccounts": 2,
            "totalArchivedAccounts": 0
          },
          "accounts": [
            { "id": "id-0", "name": "Main", "icon": "Star", "iconColor": "Azure", "derivation": 0, "tokens": [] },
            { "id": "id-1", "name": "Family", "icon": "Star", "iconColor": "Azure", "derivation": 1, "type": "joint", "tokens": [] }
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

        /// The shape the endpoint answers in once it counts the kinds apart: each is named, and the total they used
        /// to share is gone.
        static let responseWithoutTotalAccounts = """
        {
          "wallet": {
            "version": 1,
            "group": "network",
            "sort": "manual",
            "totalArchivedAccounts": 0,
            "totalCryptoAccounts": 2,
            "totalJointAccounts": 1
          },
          "accounts": [],
          "unassignedTokens": []
        }
        """

        /// Neither shape: the joint counter alone says nothing about how many of the wallet's own accounts there are.
        static let responseWithoutAnyCounters = """
        {
          "wallet": {
            "version": 1,
            "group": "network",
            "sort": "manual",
            "totalArchivedAccounts": 0,
            "totalJointAccounts": 1
          },
          "accounts": [],
          "unassignedTokens": []
        }
        """

        static func storedAccount(derivationIndex: Int, type: AccountType) -> StoredCryptoAccount {
            StoredCryptoAccount(
                derivationIndex: derivationIndex,
                type: type,
                name: "Account \(derivationIndex)",
                icon: StoredCryptoAccount.Icon(iconName: "Star", iconColor: "Azure"),
                tokens: [],
                grouping: .none,
                sorting: .manual
            )
        }
    }
}
