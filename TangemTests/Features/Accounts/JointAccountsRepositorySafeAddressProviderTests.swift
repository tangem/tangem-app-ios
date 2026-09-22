//
//  JointAccountsRepositorySafeAddressProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
@testable import Tangem

// MARK: - Tests

/// Where the tokens of a joint account learn the address they live at.
@Suite("Tests for reading a joint account's Safe address off its record")
struct JointAccountsRepositorySafeAddressProviderTests {
    @Test("There is no address until the account is activated, and then it reaches the subscribers once")
    func addressAppearsWithActivation() {
        // The address is announced at this stage already, and reading it off the record before activation is exactly
        // what the provider must not do
        let repository = JointAccountsRepositoryStub(jointAccounts: [
            Self.storedAccount(status: .confirming(safeAddress: Self.safeAddress)),
        ])
        let sut = Self.makeSUT(repository: repository)
        var emitted: [String?] = []
        let subscription = sut.safeAddressPublisher.sink { emitted.append($0) }

        #expect(sut.safeAddress == nil)

        repository.store([Self.storedAccount(status: .active(safeAddress: Self.safeAddress))])

        #expect(sut.safeAddress == Self.safeAddress)
        #expect(emitted == [nil, Self.safeAddress])
        withExtendedLifetime(subscription) {}
    }

    @Test("A record change that leaves the address alone is not repeated to the subscribers")
    func unchangedAddressIsNotRepeated() {
        let repository = JointAccountsRepositoryStub(jointAccounts: [
            Self.storedAccount(status: .active(safeAddress: Self.safeAddress), memberNames: ["Alice"]),
        ])
        let sut = Self.makeSUT(repository: repository)
        var emissionsCount = 0
        let subscription = sut.safeAddressPublisher.sink { _ in emissionsCount += 1 }

        repository.store([Self.storedAccount(status: .active(safeAddress: Self.safeAddress), memberNames: ["Alice", "Bob"])])

        #expect(emissionsCount == 1)
        withExtendedLifetime(subscription) {}
    }
}

// MARK: - Helpers

private extension JointAccountsRepositorySafeAddressProviderTests {
    static let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))
    static let derivationIdentity = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)
    static let safeAddress = "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"

    static func makeSUT(repository: JointAccountsRepository) -> JointAccountsRepositorySafeAddressProvider {
        JointAccountsRepositorySafeAddressProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: repository
        )
    }

    /// Stored under the identifier with the case of every letter flipped: the endpoint spells it its own way, and
    /// the provider has to find the record regardless.
    static func storedAccount(status: JointAccountStatus, memberNames: [String] = ["Alice", "Bob"]) -> StoredJointAccount {
        let identifier = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString
        let caseFlippedIdentifier = String(identifier.map { $0.isUppercase ? Character($0.lowercased()) : Character($0.uppercased()) })

        return StoredJointAccount(
            cryptoAccountId: caseFlippedIdentifier,
            membersCount: 2,
            threshold: 2,
            status: status,
            members: memberNames.enumerated().map { index, name in
                StoredJointAccount.Member(
                    name: name,
                    address: "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21\(index)",
                    role: index == 0 ? .creator : .member,
                    inviteId: nil
                )
            }
        )
    }
}
