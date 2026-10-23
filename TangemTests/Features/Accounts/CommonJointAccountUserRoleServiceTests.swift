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

@Suite("Tests for the slot a wallet holds in a joint account")
struct CommonJointAccountUserRoleServiceTests {
    @Test("The slot the stored key resolves to is the one the wallet holds")
    func slotIsTheOneTheStoredKeyResolvesTo() {
        let sut = Self.makeSUT()
        let own = Self.own(role: .member(inviteId: "AA"))

        #expect(sut.role(among: [Self.other, own]) == .member(own))
    }

    @Test("The slot carries the role it was taken in, so the creator is told apart by it")
    func creatorIsToldApartByTheSlotsOwnRole() {
        let sut = Self.makeSUT()

        #expect(sut.role(among: [Self.own(role: .creator)]).isCreator)
        #expect(!sut.role(among: [Self.own(role: .member(inviteId: "AA"))]).isCreator)
    }

    /// The endpoint keeps the addresses in lower case while the app computes the checksummed form.
    @Test("The wallet finds its slot regardless of how either address is cased")
    func slotIsMatchedCaseInsensitively() {
        let sut = Self.makeSUT()
        let lowercased = JointAccountMember(name: "Me", address: Self.derivedAddress.lowercased(), role: .creator)

        #expect(sut.role(among: [lowercased]) == .member(lowercased))
    }

    @Test("A wallet whose address holds no slot of the account is outside its composition")
    func walletOutsideTheCompositionIsOutsider() {
        let sut = Self.makeSUT()

        #expect(sut.role(among: [Self.other]) == .outsider)
    }

    @Test("With no composition to look in the wallet is outside it, whether or not it holds the key")
    func walletWithoutACompositionIsOutsider() {
        #expect(Self.makeSUT().role(among: []) == .outsider)
        #expect(Self.makeSUT(storedKeyPath: Self.otherPath).role(among: []) == .outsider)
    }

    @Test("Without a key stored for this account the wallet needs a derivation first, and says so rather than calling itself an outsider")
    func walletWithoutTheStoredKeyNeedsDerivation() {
        let sut = Self.makeSUT(storedKeyPath: Self.otherPath)

        #expect(sut.role(among: [Self.own(role: .creator)]) == .derivationNeeded)
    }

    @Test("A wallet that holds no slot, or still needs the derivation to tell which one it holds, is no creator")
    func neitherOutsiderNorDerivationNeededIsCreator() {
        #expect(!Self.makeSUT().role(among: [Self.other]).isCreator)
        #expect(!Self.makeSUT(storedKeyPath: Self.otherPath).role(among: [Self.own(role: .creator)]).isCreator)
    }
}

// MARK: - Helpers

private extension CommonJointAccountUserRoleServiceTests {
    static let derivationIdentity = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)
    static let derivedAddress = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"

    static var ownPath: DerivationPath {
        JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIdentity.derivationIndex)
    }

    static var otherPath: DerivationPath {
        JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIdentity.derivationIndex + 1)
    }

    static var other: JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c", role: .creator)
    }

    static func own(role: JointAccountMember.Role) -> JointAccountMember {
        JointAccountMember(name: "Me", address: derivedAddress, role: role)
    }

    static func makeSUT(storedKeyPath: DerivationPath = ownPath) -> CommonJointAccountUserRoleService {
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

        return CommonJointAccountUserRoleService(
            derivationIdentity: derivationIdentity,
            keysProvider: KeysRepositoryTestsMock(keys: [masterKey])
        )
    }
}
