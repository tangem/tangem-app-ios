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
            Self.storedAccount(status: .active(safeAddress: Self.safeAddress), memberNames: ["Alice", "Bob", "Carol"]),
        ])
        let sut = Self.makeSUT(repository: repository)
        var emissionsCount = 0
        let subscription = sut.safeAddressPublisher.sink { _ in emissionsCount += 1 }

        repository.store([Self.storedAccount(status: .active(safeAddress: Self.safeAddress), memberNames: ["Alice", "Bob", "Dave"])])

        #expect(emissionsCount == 1)
        withExtendedLifetime(subscription) {}
    }

    /// A member who did not activate the account learns its address off a refresh alone, so a refresh is where an
    /// address the composition does not resolve to has to be turned away.
    @Test("An address the members and the threshold do not resolve to is not handed out, whenever it arrives")
    func addressOfAnotherCompositionIsWithheld() {
        let repository = JointAccountsRepositoryStub(jointAccounts: [
            Self.storedAccount(status: .active(safeAddress: Self.safeAddress)),
        ])
        let sut = Self.makeSUT(repository: repository)
        var emitted: [String?] = []
        let subscription = sut.safeAddressPublisher.sink { emitted.append($0) }

        repository.store([Self.storedAccount(status: .active(safeAddress: Self.foreignSafeAddress))])

        #expect(sut.safeAddress == nil)
        #expect(emitted == [Self.safeAddress, nil])
        withExtendedLifetime(subscription) {}
    }

    /// The endpoint keeps addresses in lower case, and the wallet is built around the form the app computes.
    @Test("The address is handed out in the form the composition resolves to, not in the case it was stored in")
    func addressIsHandedOutChecksummed() {
        let repository = JointAccountsRepositoryStub(jointAccounts: [
            Self.storedAccount(status: .active(safeAddress: Self.safeAddress.lowercased())),
        ])
        let sut = Self.makeSUT(repository: repository)

        #expect(sut.safeAddress == Self.safeAddress)
    }
}

// MARK: - Helpers

private extension JointAccountsRepositorySafeAddressProviderTests {
    static let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))
    static let derivationIdentity = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)
    /// What `memberAddresses` resolve to under a threshold of two — see `JointAccountSafeAddressVerifierTests`.
    static let safeAddress = "0x9295a5836685C5F5f42242f9B64d23E46F8c259F"
    static let foreignSafeAddress = "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"
    static let memberAddresses = [
        "0xa9936482d7d056d6f843f5C6088Ff0123b796bCC",
        "0xB8C09e7abE7e0F70f4F4cAf48eED46cc8BfdA120",
        "0xD048326c01787c475Af00C51eb0221d2557bfEc2",
    ]

    static func makeSUT(repository: JointAccountsRepository) -> JointAccountsRepositorySafeAddressProvider {
        JointAccountsRepositorySafeAddressProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: repository
        )
    }

    /// Stored under the identifier with the case of every letter flipped: the endpoint spells it its own way, and
    /// the provider has to find the record regardless.
    static func storedAccount(status: JointAccountStatus, memberNames: [String] = ["Alice", "Bob", "Carol"]) -> StoredJointAccount {
        let identifier = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString
        let caseFlippedIdentifier = String(identifier.map { $0.isUppercase ? Character($0.lowercased()) : Character($0.uppercased()) })

        return StoredJointAccount(
            cryptoAccountId: caseFlippedIdentifier,
            membersCount: memberAddresses.count,
            threshold: 2,
            status: status,
            members: zip(memberNames, memberAddresses).enumerated().map { index, member in
                StoredJointAccount.Member(
                    name: member.0,
                    address: member.1,
                    role: index == 0 ? .creator : .member,
                    inviteId: nil
                )
            }
        )
    }
}
