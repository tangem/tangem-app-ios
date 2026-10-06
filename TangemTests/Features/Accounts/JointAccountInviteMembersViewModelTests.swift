//
//  JointAccountInviteMembersViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import Testing
import TangemFoundation
import TangemLocalization
@testable import Tangem

@Suite("Tests for the rows the joint account composition is shown by")
@MainActor
struct JointAccountInviteMembersViewModelTests {
    /// Kept by the suite because the accounts hold it weakly, and a new one is made per test the way every stored
    /// property of a suite is.
    private let delegate = JointAccountModelDelegateMock()

    @Test("Everyone who has taken a slot has a row of their own")
    func everyMemberIsShown() {
        let viewModel = makeViewModel(
            membersCount: 3,
            members: [creator, member(name: "Bob", inviteId: "AA")],
            inviteIds: ["AA", "BB"]
        )

        #expect(viewModel.content.members.map(\.name) == ["Isaac", "Bob"])
        #expect(viewModel.content.joinedMembersCount == 2)
        #expect(viewModel.content.totalMembersCount == 3)
    }

    @Test("The wallet holding the invites is the creator's, and its own row says so")
    func creatorRowNamesThisWallet() {
        let creatorSide = makeViewModel(membersCount: 2, members: [creator], inviteIds: ["AA"])
        let memberSide = makeViewModel(membersCount: 2, members: [creator], inviteIds: nil)

        #expect(creatorSide.content.members.first?.role.contains(Localization.jointAccountMembersRoleYou) == true)
        #expect(memberSide.content.members.first?.role == Localization.jointAccountInviteMembersCreator)
    }

    @Test("The row of this wallet's own address says You, whether it created the account or joined it")
    func ownRowIsToldByAddress() {
        let bob = member(name: "Bob", inviteId: "AA")

        #expect(role(of: bob, ownAddress: bob.address.uppercased()) == Localization.jointAccountMembersRoleYou)
        #expect(role(of: creator, ownAddress: bob.address) == Localization.jointAccountInviteMembersCreator)
        #expect(role(of: creator, ownAddress: creator.address.uppercased()).contains(Localization.jointAccountMembersRoleYou))
        #expect(role(of: bob, ownAddress: creator.address, isCreatorDevice: true) == Localization.jointAccountMembersRoleJoined)
    }

    @Test("A member of an account not yet activated finds their own row by the address the members service derives")
    func joinerOwnRowOfPendingAccount() {
        let bob = member(name: "Bob", inviteId: "AA")
        let membersService = JointAccountMembersServiceMock(
            slots: [.member(creator), .member(bob), .empty(invite: nil)],
            ownAddress: bob.address
        )

        let viewModel = makeViewModel(membersCount: 3, membersService: membersService)

        #expect(viewModel.content.members.map(\.role) == [Localization.jointAccountInviteMembersCreator, Localization.jointAccountMembersRoleYou])
    }

    @Test("Without an address of its own, the wallet holding the invites still tells the creator's row apart")
    func ownRowFallsBackToInvites() {
        let bob = member(name: "Bob", inviteId: "AA")

        #expect(role(of: creator, ownAddress: nil, isCreatorDevice: true).contains(Localization.jointAccountMembersRoleYou))
        #expect(role(of: creator, ownAddress: nil) == Localization.jointAccountInviteMembersCreator)
        #expect(role(of: bob, ownAddress: nil, isCreatorDevice: true) == Localization.jointAccountMembersRoleJoined)
    }

    @Test("A slot somebody was invited into is a member rather than an invitation waiting to be sent")
    func joinedMemberIsNotAFreeSlot() {
        let viewModel = makeViewModel(
            membersCount: 2,
            members: [creator, member(name: "Bob", inviteId: "AA")],
            inviteIds: ["AA"]
        )

        #expect(viewModel.content.members.count == 2)
        #expect(viewModel.content.freeSlots.isEmpty)
    }

    @Test("Every free slot is shown, and the invite it is opened with goes to it alone")
    func freeSlotsCarryAnInviteEach() {
        let viewModel = makeViewModel(membersCount: 4, members: [creator], inviteIds: ["AA", "BB", "CC"])

        #expect(
            viewModel.content.freeSlots.map { $0.invite?.url.absoluteString } == [
                "https://tangem.com/joint-account/join/AA",
                "https://tangem.com/joint-account/join/BB",
                "https://tangem.com/joint-account/join/CC",
            ]
        )
    }

    @Test("A slot this wallet holds no invite for is shown all the same, with nothing to invite anybody by")
    func freeSlotWithoutAnInviteIsStillShown() {
        let viewModel = makeViewModel(membersCount: 3, members: [creator], inviteIds: nil)

        #expect(viewModel.content.freeSlots.count == 2)
        #expect(viewModel.content.freeSlots.allSatisfy { $0.invite?.url == nil })
        // The count the screen reports is the account's own, rather than this wallet's share of it
        #expect(viewModel.content.totalMembersCount == 3)
    }

    /// The rows follow the composition itself rather than the account, whose own changes say nothing of who joined.
    /// - Note: Time-limited because the wait below has no bound of its own: a screen that stops following the
    /// composition would hang the whole test run rather than report itself.
    @Test("A member who joins while the screen is open gets a row without the account changing", .timeLimit(.minutes(1)))
    func joiningMemberIsShownAsTheCompositionMovesOn() async throws {
        let repository = JointAccountsRepositoryStub(
            jointAccounts: [JointAccountCompositionFixture.storedAccount(status: .pending, membersCount: 2, members: [creator])],
            invites: [
                StoredJointAccountInvites(
                    cryptoAccountId: JointAccountCompositionFixture.caseFlippedCryptoAccountId,
                    invites: [StoredJointAccountInvite(id: "AA")]
                ),
            ]
        )
        let viewModel = makeViewModel(
            membersCount: 2,
            membersService: JointAccountCompositionFixture.makeMembersService(repository: repository)
        )

        repository.store([
            JointAccountCompositionFixture.storedAccount(
                status: .pending,
                membersCount: 2,
                members: [creator, member(name: "Bob", inviteId: "AA")]
            ),
        ])

        let content = try await viewModel.$content.first { $0.members.count == 2 }.async()

        #expect(content.members.map(\.name) == ["Isaac", "Bob"])
        #expect(content.freeSlots.isEmpty)
        // The view model holds the subscription the awaited value comes through, and nothing below uses it — without
        // this ARC may release it mid-await, leaving the test to wait on a publisher nobody feeds
        withExtendedLifetime(viewModel) {}
    }

    @Test("Activating opens the confirmation with the signer's own way of signing", arguments: [true, false])
    func activationConfirmationKnowsTheSigner(hasNFCInteraction: Bool) {
        let coordinator = JointAccountInviteMembersRoutableSpy()
        let viewModel = makeViewModel(
            membersCount: 2,
            membersService: JointAccountCompositionFixture.makeMembersService(
                membersCount: 2,
                members: [creator],
                inviteIds: ["AA"]
            ),
            hasNFCInteraction: hasNFCInteraction,
            coordinator: coordinator
        )

        viewModel.onActivateTap()

        #expect(coordinator.activationConfirmationNFCInteractions == [hasNFCInteraction])
    }

    // MARK: - Helpers

    private var creator: JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0xcreator", role: .creator)
    }

    private func member(name: String, inviteId: String) -> JointAccountMember {
        JointAccountMember(name: name, address: "0x\(name)", role: .member(inviteId: inviteId))
    }

    private func role(of member: JointAccountMember, ownAddress: String?, isCreatorDevice: Bool = false) -> String {
        JointAccountInviteMembersViewModel.role(of: member, ownAddress: ownAddress, isCreatorDevice: isCreatorDevice)
    }

    /// - Parameter inviteIds: Nil on a wallet that was handed no invites at all, which is anyone's but the creator's.
    private func makeViewModel(
        membersCount: Int,
        members: [JointAccountMember],
        inviteIds: [String]?
    ) -> JointAccountInviteMembersViewModel {
        makeViewModel(
            membersCount: membersCount,
            membersService: JointAccountCompositionFixture.makeMembersService(
                membersCount: membersCount,
                members: members,
                inviteIds: inviteIds
            )
        )
    }

    private func makeViewModel(
        membersCount: Int,
        membersService: any JointAccountMembersService,
        hasNFCInteraction: Bool = false,
        coordinator: JointAccountInviteMembersRoutable? = nil
    ) -> JointAccountInviteMembersViewModel {
        let jointAccount = CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: JointAccountCompositionFixture.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: membersCount, signersCount: 2),
            accountStatus: .pending,
            operationsService: JointAccountOperationsServiceMock(hasNFCInteraction: hasNFCInteraction),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: membersService,
            delegate: delegate
        )

        return JointAccountInviteMembersViewModel(
            jointAccount: jointAccount,
            coordinator: coordinator
        )
    }
}

// MARK: - Doubles

private final class JointAccountInviteMembersRoutableSpy: JointAccountInviteMembersRoutable {
    private(set) var activationConfirmationNFCInteractions: [Bool] = []

    func closeInviteMembers() {}

    func shareInvite(url: URL, accountName: String) {}

    func openInviteSafety() {}

    func openMemberDetails(name: String, address: String, accentColor: Color) {}

    func openActivationConfirmation(hasNFCInteraction: Bool, onConfirm: @escaping () -> Void) {
        activationConfirmationNFCInteractions.append(hasNFCInteraction)
    }
}
