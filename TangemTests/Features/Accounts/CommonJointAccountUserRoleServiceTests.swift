//
//  CommonJointAccountUserRoleServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import Tangem

@Suite("Tests for what a wallet is in a joint account")
struct CommonJointAccountUserRoleServiceTests {
    @Test("The wallet is the creator when the creator's slot is the one its stored key resolves to")
    func creatorIsTheOwnerOfTheCreatorsSlot() throws {
        #expect(try Self.makeSUT(members: [Self.own(role: .creator), Self.other(role: .member)]).isCreator())
        #expect(try !Self.makeSUT(members: [Self.other(role: .creator), Self.own(role: .member)]).isCreator())
    }

    /// The endpoint keeps the addresses in lower case while the app computes the checksummed form.
    @Test("The wallet finds its slot regardless of how either address is cased")
    func slotIsMatchedCaseInsensitively() throws {
        let lowercased = JointAccountMember(name: "Me", address: Self.derivedAddress.lowercased(), role: .creator, isMe: false)

        #expect(try Self.makeSUT(members: [lowercased]).isCreator())
        #expect(try Self.makeSUT(members: nil).isMe(member: Self.stored(lowercased)))
    }

    @Test("A wallet outside the account, or without the account in the store, is no creator")
    func outsiderIsNoCreator() throws {
        #expect(try !Self.makeSUT(members: [Self.other(role: .creator)]).isCreator())
        #expect(try !Self.makeSUT(members: nil).isCreator())
        #expect(try !Self.makeSUT(members: nil, storedKeyPath: Self.otherPath).isCreator())
    }

    @Test("The own address is the one the stored key resolves to, and another member's is not")
    func ownAddressIsTheDerivedOne() throws {
        let sut = Self.makeSUT(members: nil)

        #expect(try sut.ownAddress() == Self.derivedAddress)
        #expect(try !sut.isMe(member: Self.stored(Self.other(role: .creator))))
    }

    @Test("Without a key stored for this account the wallet needs a derivation first, and says so")
    func walletWithoutTheStoredKeyNeedsDerivation() {
        let sut = Self.makeSUT(members: [Self.own(role: .creator)], storedKeyPath: Self.otherPath)

        #expect(throws: JointAccountUserRoleServiceError.derivationNeeded) { try sut.isCreator() }
        #expect(throws: JointAccountUserRoleServiceError.derivationNeeded) { try sut.ownAddress() }
        #expect(throws: JointAccountUserRoleServiceError.derivationNeeded) { try sut.isMe(member: Self.stored(Self.own(role: .creator))) }
    }
}

// MARK: - Helpers

private extension CommonJointAccountUserRoleServiceTests {
    static let derivedAddress = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"

    static var ownPath: DerivationPath {
        JointAccountKeyPath.derivationPath(forAccountAtIndex: JointAccountCompositionFixture.derivationIdentity.derivationIndex)
    }

    static var otherPath: DerivationPath {
        JointAccountKeyPath.derivationPath(forAccountAtIndex: JointAccountCompositionFixture.derivationIdentity.derivationIndex + 1)
    }

    static func other(role: JointAccountMember.Role) -> JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c", role: role, isMe: false)
    }

    static func own(role: JointAccountMember.Role) -> JointAccountMember {
        JointAccountMember(name: "Me", address: derivedAddress, role: role, isMe: false)
    }

    static func stored(_ member: JointAccountMember) -> StoredJointAccount.Member {
        StoredJointAccount.Member(
            name: member.name,
            address: member.address,
            role: member.role == .creator ? .creator : .member,
            slot: nil,
            signature: nil
        )
    }

    /// - Parameter members: The account's members, or nil for a store that does not hold the account.
    static func makeSUT(members: [JointAccountMember]?, storedKeyPath: DerivationPath = ownPath) -> CommonJointAccountUserRoleService {
        let derivedKey = ExtendedPublicKey(
            publicKey: Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45"),
            chainCode: Data(repeating: 0x11, count: 32)
        )
        let masterKey = KeyInfo(
            publicKey: Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798"),
            chainCode: Data(repeating: 0x11, count: 32),
            curve: .secp256k1,
            isImported: false,
            derivedKeys: [storedKeyPath: derivedKey]
        )
        let repository = JointAccountsRepositoryStub(
            jointAccounts: members.map { [JointAccountCompositionFixture.storedAccount(status: .pending, membersCount: $0.count, members: $0)] } ?? []
        )

        return JointAccountCompositionFixture.makeUserRoleService(repository: repository, keysProvider: KeysRepositoryTestsMock(keys: [masterKey]))
    }
}
