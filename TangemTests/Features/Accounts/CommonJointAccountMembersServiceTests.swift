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

@Suite("Tests for what a joint account's members service says about its slots", .timeLimit(.minutes(1)))
struct CommonJointAccountMembersServiceTests {
    // MARK: - Slots

    @Test("The members come first, then a free slot per one left, numbered after them while the slots are not told")
    func freeSlotsFollowTheMembers() {
        let sut = Self.makeSUT(membersCount: 3, members: [Self.creator])

        #expect(sut.slots == [.member(Self.me(Self.creator), .joined), Self.freeSlot(1), Self.freeSlot(2)])
    }

    @Test("The creator is told the members' slots, so a free slot keeps its own number")
    func freeSlotsKeepTheirNumbers() {
        let sut = Self.makeSUT(membersCount: 3, members: [Self.creator, Self.member], memberSlots: [0, 2])

        #expect(sut.slots == [.member(Self.me(Self.creator), .joined), Self.freeSlot(1), .member(Self.member, .joined)])
    }

    @Test("A free slot carries the expiry of the invite issued on it")
    func freeSlotCarriesItsInvite() {
        let sut = Self.makeSUT(
            membersCount: 3,
            members: [Self.creator],
            memberSlots: [0],
            invites: [StoredJointAccount.Invite(slot: JointAccountMemberSlotID(2), expiresAt: Self.later)]
        )

        #expect(sut.slots == [.member(Self.me(Self.creator), .joined), Self.freeSlot(1), Self.freeSlot(2, inviteExpiresAt: Self.later)])
    }

    @Test("A free slot takes no invite from a wallet that is not the creator's, whatever the listing says of it")
    func freeSlotsTakeNoInviteFromAMember() {
        let sut = Self.makeSUT(
            membersCount: 3,
            members: [Self.creator, Self.member],
            invites: [StoredJointAccount.Invite(slot: JointAccountMemberSlotID(2), expiresAt: Self.later)],
            viewer: Self.member
        )

        #expect(sut.slots == [.member(Self.creator, .joined), .member(Self.me(Self.member), .joined), .empty(JointAccountMemberSlotID(2), .notInvitable)])
    }

    @Test("A member who confirmed the address is told by their signature from one still to confirm it")
    func confirmationIsReadOffTheSignature() {
        let sut = Self.makeSUT(
            status: .confirming(safeAddress: "0xsafe"),
            membersCount: 2,
            members: [Self.creator, Self.member],
            memberSignatures: ["0xsignature", nil]
        )

        #expect(sut.slots == [.member(Self.me(Self.creator), .confirmed), .member(Self.member, .awaitingConfirmation)])
    }

    @Test("Every member of an active account is active, whatever the listing says of their signatures")
    func membersOfAnActiveAccountAreActive() {
        let sut = Self.makeSUT(status: .active(safeAddress: "0xsafe"), membersCount: 2, members: [Self.creator, Self.member])

        #expect(sut.slots == [.member(Self.me(Self.creator), .active), .member(Self.member, .active)])
    }

    @Test("More members than the count says leaves no free slots rather than a negative number of them")
    func freeSlotsNeverGoNegative() {
        let sut = Self.makeSUT(membersCount: 2, members: [Self.creator, Self.member, Self.otherMember])

        #expect(sut.slots.count == 3)
        #expect(sut.slots.allSatisfy { $0.member != nil })
    }

    @Test("An account the store does not hold has no slots to speak of")
    func unknownAccountHasNoSlots() {
        let sut = JointAccountCompositionFixture.makeMembersService(repository: JointAccountsRepositoryStub())

        #expect(sut.slots.isEmpty)
    }

    // MARK: - Issuing invites

    @Test("An invite is issued for the slot of the account and handed on as a link, with its expiry")
    func inviteIsIssuedForTheAccount() async throws {
        let inviteURL = try #require(URL(string: "https://tangem.com/joint-account/join/A1B2C3"))
        let (sut, repository) = Self.makeIssuingSUT(
            answer: .success(JointAccountIssuedInvite(id: "A1B2C3", slot: JointAccountMemberSlotID(2), expiresAt: Self.later))
        )

        let invite = try await sut.issueInvite(slot: JointAccountMemberSlotID(2))

        #expect(invite == JointAccountInvite(id: "A1B2C3", url: inviteURL, expiresAt: Self.later))
        #expect(repository.issuedInviteRequests == [
            JointAccountsRepositoryStub.IssueInviteRequest(
                cryptoAccountId: CryptoAccountModelId(
                    userWalletId: JointAccountCompositionFixture.userWalletId,
                    derivationIdentity: JointAccountCompositionFixture.derivationIdentity
                ).rawValue.hexString,
                slot: JointAccountMemberSlotID(2)
            ),
        ])
    }

    @Test(
        "A slot the endpoint no longer issues an invite for is reported as unavailable, and the account is read again",
        arguments: [TangemAPIError.ErrorCode.forbidden, .notFound, .conflict]
    )
    func unavailableSlotReadsTheAccountAgain(code: TangemAPIError.ErrorCode) async {
        let (sut, repository) = Self.makeIssuingSUT(answer: .failure(TangemAPIError(code: code)))

        await #expect {
            _ = try await sut.issueInvite(slot: JointAccountMemberSlotID(2))
        } throws: { error in
            guard case .slotUnavailable = error as? JointAccountInviteIssueError else {
                return false
            }

            return true
        }

        #expect(repository.loadJointAccountsFromRemoteCallsCount == 1)
    }

    @Test("Any other failure is handed on as it is, with nothing read again")
    func otherFailureIsHandedOn() async {
        let (sut, repository) = Self.makeIssuingSUT(answer: .failure(TangemAPIError(code: .badRequest)))

        await #expect {
            _ = try await sut.issueInvite(slot: JointAccountMemberSlotID(2))
        } throws: { error in
            guard case .failed(let underlyingError) = error as? JointAccountInviteIssueError else {
                return false
            }

            return (underlyingError as? TangemAPIError)?.code == .badRequest
        }

        #expect(repository.loadJointAccountsFromRemoteCallsCount == 0)
    }

    // MARK: - This wallet's own slot

    /// What the role service answers is its own suite's to check; this one is about the composition it is asked
    /// about being the slots of this account.
    @Test("The slot the wallet holds is marked as its own, and a free slot then takes its invite")
    func ownSlotIsLookedForAmongTheAccountsMembers() {
        let own = JointAccountMember(name: "Me", address: Self.derivedAddress, role: .creator, isMe: false)
        let sut = Self.makeSUT(membersCount: 3, members: [own, Self.member], storedKeyPath: Self.ownPath)

        #expect(sut.slots.members.map(\.isMe) == [true, false])
        #expect(sut.slots.last == Self.freeSlot(2))
    }

    @Test("A composition this wallet holds no slot of marks no slot as its own and takes no invite")
    func ownSlotIsAbsentFromAForeignComposition() {
        let sut = Self.makeSUT(membersCount: 2, members: [Self.creator], storedKeyPath: Self.ownPath)

        #expect(sut.slots.members.allSatisfy { !$0.isMe })
        #expect(sut.slots.last == .empty(JointAccountMemberSlotID(1), .notInvitable))
    }
}

// MARK: - Helpers

private extension CommonJointAccountMembersServiceTests {
    static let later = Date(timeIntervalSince1970: 1_793_286_400)

    static var creator: JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0xcreator", role: .creator, isMe: false)
    }

    static var member: JointAccountMember {
        JointAccountMember(name: "Bob", address: "0xbob", role: .member, isMe: false)
    }

    static var otherMember: JointAccountMember {
        JointAccountMember(name: "Carol", address: "0xcarol", role: .member, isMe: false)
    }

    static func me(_ member: JointAccountMember) -> JointAccountMember {
        JointAccountMember(name: member.name, address: member.address, role: member.role, isMe: true)
    }

    static func freeSlot(_ slot: Int, inviteExpiresAt: Date? = nil) -> JointAccountSlot {
        let id = JointAccountMemberSlotID(slot)

        return .empty(id, inviteExpiresAt.map { .reinvitable(previousInviteExpiresAt: $0) } ?? .invitable)
    }

    static func makeSUT(
        status: JointAccountStatus = .pending,
        membersCount: Int,
        members: [JointAccountMember],
        memberSlots: [Int]? = nil,
        memberSignatures: [String?]? = nil,
        invites: [StoredJointAccount.Invite] = [],
        viewer: JointAccountMember = Self.creator
    ) -> CommonJointAccountMembersService {
        JointAccountCompositionFixture.makeMembersService(
            status: status,
            membersCount: membersCount,
            members: members,
            memberSlots: memberSlots,
            memberSignatures: memberSignatures,
            invites: invites,
            userRoleService: JointAccountUserRoleServiceMock(creator: viewer.role == .creator, address: viewer.address)
        )
    }

    static func makeIssuingSUT(
        answer: Result<JointAccountIssuedInvite, Error>
    ) -> (sut: CommonJointAccountMembersService, repository: JointAccountsRepositoryStub) {
        let repository = JointAccountsRepositoryStub(
            jointAccounts: [
                JointAccountCompositionFixture.storedAccount(status: .pending, membersCount: 3, members: [creator], memberSlots: [0]),
            ],
            issuedInviteAnswer: answer
        )
        let sut = JointAccountCompositionFixture.makeMembersService(repository: repository)

        return (sut, repository)
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
