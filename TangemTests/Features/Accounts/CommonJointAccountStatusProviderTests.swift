//
//  CommonJointAccountStatusProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import Tangem

@Suite("Tests for the status a joint account is read with")
struct CommonJointAccountStatusProviderTests {
    @Test("A wallet among the members keeps the status the record carries", arguments: Self.statuses)
    func memberKeepsTheStatus(status: JointAccountStatus) {
        let sut = Self.makeSUT(account: Signed.account(status: status))

        #expect(sut.status == status)
    }

    @Test("A wallet finds itself among the members regardless of how either address is cased")
    func membershipIgnoresCase() {
        let sut = Self.makeSUT(account: Signed.account(status: Self.active), ownAddress: Self.ownAddress.lowercased())

        #expect(sut.status == Self.active)
    }

    @Test("A wallet outside the members is untrusted, whatever stage the record is at", arguments: Self.statuses)
    func nonMemberIsUntrusted(status: JointAccountStatus) {
        let sut = Self.makeSUT(account: Self.record(status: status, memberAddresses: [Self.strangerAddress]))

        #expect(sut.status == .untrusted)
    }

    @Test("An active account whose members have not all signed its composition is held untrusted")
    func activeAccountWithUnverifiedCompositionIsUntrusted() {
        let sut = Self.makeSUT(
            account: Self.record(status: Self.active, memberAddresses: [Signed.member1Address, Signed.member2Address, Signed.member3Address])
        )

        #expect(sut.status == .untrusted)
    }

    @Test("An active account with no name has no composition to check its signatures against, so it is held untrusted")
    func namelessAccountIsUntrusted() {
        let sut = Self.makeSUT(account: Signed.account(status: Self.active), cryptoAccounts: [Signed.cryptoAccount(name: nil)])

        #expect(sut.status == .untrusted)
    }

    @Test("A record dropping this wallet reaches the subscribers, and one leaving the status alone does not")
    func recordChangesReachTheSubscribersOnce() {
        let repository = JointAccountsRepositoryStub(jointAccounts: [Signed.account(status: Self.active)])
        let sut = JointAccountCompositionFixture.makeStatusProvider(
            repository: repository,
            userRoleService: JointAccountUserRoleServiceMock(address: Self.ownAddress)
        )
        var emitted: [JointAccountStatus] = []
        let subscription = sut.statusPublisher.sink { emitted.append($0) }

        repository.store([Signed.account(status: Self.active)])
        repository.store([Self.record(status: Self.active, memberAddresses: [Self.strangerAddress])])

        #expect(emitted == [Self.active, .untrusted])
        withExtendedLifetime(subscription) {}
    }

    @Test("A change to the account's own entry reaches the subscribers, as a change to its record does")
    func accountEntryChangesReachTheSubscribers() {
        let cryptoAccountsRepository = CryptoAccountsRepositoryStub(cryptoAccounts: [Signed.cryptoAccount()])
        let sut = JointAccountCompositionFixture.makeStatusProvider(
            repository: JointAccountsRepositoryStub(jointAccounts: [Signed.account(status: Self.active)]),
            userRoleService: JointAccountUserRoleServiceMock(address: Self.ownAddress),
            cryptoAccountsRepository: cryptoAccountsRepository
        )
        var emitted: [JointAccountStatus] = []
        let subscription = sut.statusPublisher.sink { emitted.append($0) }

        cryptoAccountsRepository.store([Signed.cryptoAccount(name: "Renamed")])

        #expect(emitted == [Self.active, .untrusted])
        withExtendedLifetime(subscription) {}
    }
}

// MARK: - Helpers

private extension CommonJointAccountStatusProviderTests {
    typealias Signed = JointAccountCompositionFixture.Signed

    static let ownAddress = JointAccountCompositionFixture.ownAddress
    static let strangerAddress = JointAccountCompositionFixture.strangerAddress
    static let active = JointAccountStatus.active(safeAddress: Signed.safeAddress)
    static let statuses: [JointAccountStatus] = [.pending, .confirming(safeAddress: Signed.safeAddress), active]

    static func makeSUT(
        account: StoredJointAccount,
        ownAddress: String = ownAddress,
        cryptoAccounts: [StoredCryptoAccount] = [Signed.cryptoAccount()]
    ) -> CommonJointAccountStatusProvider {
        JointAccountCompositionFixture.makeStatusProvider(
            repository: JointAccountsRepositoryStub(jointAccounts: [account]),
            userRoleService: JointAccountUserRoleServiceMock(address: ownAddress),
            cryptoAccountsRepository: CryptoAccountsRepositoryStub(cryptoAccounts: cryptoAccounts)
        )
    }

    static func record(status: JointAccountStatus, memberAddresses: [String]) -> StoredJointAccount {
        JointAccountCompositionFixture.storedAccount(
            status: status,
            membersCount: memberAddresses.count,
            members: memberAddresses.map { JointAccountCompositionFixture.member(address: $0) }
        )
    }
}
