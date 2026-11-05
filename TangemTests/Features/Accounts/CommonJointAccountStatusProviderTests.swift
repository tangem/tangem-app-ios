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
        let sut = Self.makeSUT(status: status, memberAddresses: [Self.ownAddress, Self.strangerAddress])

        #expect(sut.status == status)
    }

    @Test("A wallet finds itself among the members regardless of how either address is cased")
    func membershipIgnoresCase() {
        let sut = Self.makeSUT(status: Self.active, memberAddresses: [Self.ownAddress.lowercased()])

        #expect(sut.status == Self.active)
    }

    @Test("A wallet outside the members is untrusted, whatever stage the record is at", arguments: Self.statuses)
    func nonMemberIsUntrusted(status: JointAccountStatus) {
        let sut = Self.makeSUT(status: status, memberAddresses: [Self.strangerAddress])

        #expect(sut.status == .untrusted)
    }

    @Test("A record dropping this wallet reaches the subscribers, and one leaving the status alone does not")
    func recordChangesReachTheSubscribersOnce() {
        let repository = Self.repository(status: Self.active, memberAddresses: [Self.ownAddress, Self.strangerAddress])
        let sut = JointAccountCompositionFixture.makeStatusProvider(
            repository: repository,
            userRoleService: JointAccountUserRoleServiceMock(address: Self.ownAddress)
        )
        var emitted: [JointAccountStatus] = []
        let subscription = sut.statusPublisher.sink { emitted.append($0) }

        repository.store([Self.record(status: Self.active, memberAddresses: [Self.ownAddress])])
        repository.store([Self.record(status: Self.active, memberAddresses: [Self.strangerAddress])])

        #expect(emitted == [Self.active, .untrusted])
        withExtendedLifetime(subscription) {}
    }
}

// MARK: - Helpers

private extension CommonJointAccountStatusProviderTests {
    static let ownAddress = JointAccountCompositionFixture.ownAddress
    static let strangerAddress = JointAccountCompositionFixture.strangerAddress
    static let safeAddress = "0x9295a5836685C5F5f42242f9B64d23E46F8c259F"
    static let active = JointAccountStatus.active(safeAddress: safeAddress)
    static let statuses: [JointAccountStatus] = [.pending, .confirming(safeAddress: safeAddress), active]

    static func makeSUT(status: JointAccountStatus, memberAddresses: [String]) -> CommonJointAccountStatusProvider {
        JointAccountCompositionFixture.makeStatusProvider(
            repository: repository(status: status, memberAddresses: memberAddresses),
            userRoleService: JointAccountUserRoleServiceMock(address: ownAddress)
        )
    }

    static func repository(status: JointAccountStatus, memberAddresses: [String]) -> JointAccountsRepositoryStub {
        JointAccountsRepositoryStub(jointAccounts: [record(status: status, memberAddresses: memberAddresses)])
    }

    static func record(status: JointAccountStatus, memberAddresses: [String]) -> StoredJointAccount {
        JointAccountCompositionFixture.storedAccount(
            status: status,
            membersCount: memberAddresses.count,
            members: memberAddresses.map { JointAccountCompositionFixture.member(address: $0) }
        )
    }
}
