//
//  CommonJointAccountMembersServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import Tangem

@Suite("Tests for what a joint account's members service says about its slots")
struct CommonJointAccountMembersServiceTests {
    // MARK: - Slots

    @Test("Every slot left free is a slot of its own, with no invite to offer")
    func freeSlotsCarryNoInvite() {
        let sut = Self.makeSUT(membersCount: 3, members: [Self.creator])

        #expect(sut.slots == [.member(Self.creator), .empty(invite: nil), .empty(invite: nil)])
    }

    @Test("More members than the count says leaves no free slots rather than a negative number of them")
    func freeSlotsNeverGoNegative() {
        let sut = Self.makeSUT(membersCount: 2, members: [Self.creator, Self.member(named: "Bob"), Self.member(named: "Carol")])

        #expect(sut.slots.count == 3)
        #expect(sut.slots.allSatisfy { $0.member != nil })
    }

    @Test("An account the store does not hold has no slots to speak of, this wallet's own included")
    func unknownAccountHasNoSlots() {
        let sut = JointAccountCompositionFixture.makeMembersService(repository: JointAccountsRepositoryStub())

        #expect(sut.slots.isEmpty)
        #expect(sut.userRole == .outsider)
    }

    // MARK: - This wallet's own slot

    /// What the role service answers is its own suite's to check; this one is about the composition it is asked
    /// about being the slots of this account.
    @Test("The slot the wallet holds is looked for among the account's own members")
    func ownSlotIsLookedForAmongTheAccountsMembers() {
        let own = JointAccountMember(name: "Me", address: Self.derivedAddress, role: .creator)
        let sut = Self.makeSUT(membersCount: 2, members: [own, Self.member(named: "Bob")], storedKeyPath: Self.ownPath)

        #expect(sut.userRole == .member(own))
        #expect(sut.userRole.isCreator)
    }

    @Test("A composition this wallet holds no slot of leaves it outside")
    func ownSlotIsAbsentFromAForeignComposition() {
        let sut = Self.makeSUT(membersCount: 2, members: [Self.creator], storedKeyPath: Self.ownPath)

        #expect(sut.userRole == .outsider)
    }
}

// MARK: - Helpers

private extension CommonJointAccountMembersServiceTests {
    static var creator: JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0xcreator", role: .creator)
    }

    static func member(named name: String) -> JointAccountMember {
        JointAccountMember(name: name, address: "0x\(name.lowercased())", role: .member)
    }

    static func makeSUT(membersCount: Int, members: [JointAccountMember]) -> CommonJointAccountMembersService {
        JointAccountCompositionFixture.makeMembersService(membersCount: membersCount, members: members)
    }

    static let derivedAddress = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"

    static var ownPath: DerivationPath {
        JointAccountKeyPath.derivationPath(forAccountAtIndex: JointAccountCompositionFixture.derivationIdentity.derivationIndex)
    }

    static func makeSUT(
        membersCount: Int,
        members: [JointAccountMember],
        storedKeyPath: DerivationPath
    ) -> CommonJointAccountMembersService {
        JointAccountCompositionFixture.makeMembersService(
            membersCount: membersCount,
            members: members,
            keysProvider: KeysRepositoryTestsMock(keys: [masterKey(storedKeyPath: storedKeyPath)])
        )
    }

    static func masterKey(storedKeyPath: DerivationPath) -> KeyInfo {
        let derivedKey = ExtendedPublicKey(
            publicKey: Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45"),
            chainCode: Data(repeating: 0x11, count: 32)
        )
        return KeyInfo(
            publicKey: Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798"),
            chainCode: Data(repeating: 0x11, count: 32),
            curve: .secp256k1,
            isImported: false,
            derivedKeys: [storedKeyPath: derivedKey]
        )
    }
}
