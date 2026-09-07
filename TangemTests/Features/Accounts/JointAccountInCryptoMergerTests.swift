//
//  JointAccountInCryptoMergerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

/// The halves a joint account is kept in — the entry the wallet's account list holds and the record of its own — put
/// back together the way the list reads them.
@Suite("Tests for putting a joint account back together out of its halves")
struct JointAccountInCryptoMergerTests {
    private let merger = JointAccountInCryptoMerger()

    @Test("An activated account, which the endpoint describes without its invites, still reaches the list")
    func activatedAccountWithoutInvitesIsMerged() {
        let cryptoAccount = Self.cryptoAccount()
        let stored = Self.storedAccount(
            cryptoAccountId: cryptoAccount.id.rawValue.hexString,
            status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
            inviteIds: [nil, nil]
        )

        let accounts = merger.merge([cryptoAccount], with: [stored], invites: [])

        #expect(accounts.count == 1)
        #expect(accounts.first?.members.map(\.role) == [.creator, .member(inviteId: nil)])
    }

    @Test("While the slots are still filling up, the member carries the invite that let them in")
    func fillingAccountKeepsTheInvites() {
        let cryptoAccount = Self.cryptoAccount()
        let stored = Self.storedAccount(
            cryptoAccountId: cryptoAccount.id.rawValue.hexString,
            status: .pending,
            inviteIds: [nil, "F0E1D2C3A4B5C6D7"]
        )

        let accounts = merger.merge([cryptoAccount], with: [stored], invites: [])

        #expect(accounts.first?.members.map(\.role) == [.creator, .member(inviteId: "F0E1D2C3A4B5C6D7")])
    }

    @Test("An account whose record has not arrived yet is left out rather than shown half-built")
    func accountWithoutRecordIsLeftOut() {
        let accounts = merger.merge([Self.cryptoAccount()], with: [], invites: [])

        #expect(accounts.isEmpty)
    }
}

// MARK: - Fixtures

private extension JointAccountInCryptoMergerTests {
    static func cryptoAccount() -> CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
    }

    /// - Parameter inviteIds: One per taken slot, the creator's first — theirs is always nil, since they opened the
    /// account rather than being invited into it.
    static func storedAccount(
        cryptoAccountId: String,
        status: JointAccountStatus,
        inviteIds: [String?]
    ) -> StoredJointAccount {
        StoredJointAccount(
            cryptoAccountId: cryptoAccountId,
            membersCount: inviteIds.count,
            threshold: 2,
            status: status,
            members: inviteIds.enumerated().map { index, inviteId in
                StoredJointAccount.Member(
                    name: "Member \(index + 1)",
                    address: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91\(index)",
                    role: index == 0 ? .creator : .member,
                    inviteId: inviteId
                )
            }
        )
    }
}
