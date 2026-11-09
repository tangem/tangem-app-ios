//
//  CommonJointAccountMembersViewModelContentProviderTests.swift
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

@Suite("Joint account members screen content", .timeLimit(.minutes(1)))
@MainActor
struct CommonJointAccountMembersViewModelContentProviderTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("The title follows the account status and who is looking at it", arguments: TitleCase.allCases)
    func titleFollowsStatusAndRole(titleCase: TitleCase) throws {
        let (provider, _) = makeSUT(status: titleCase.status, viewer: titleCase.viewer)

        #expect(try value(of: provider.titlePublisher) == titleCase.expectedTitle)
    }

    @Test("A member row names the role and adds You to this wallet's own row")
    func memberRowNamesTheRole() throws {
        let (creatorSide, _) = makeSUT(members: [creator, bob], viewer: .creator)
        let (memberSide, _) = makeSUT(members: [creator, bob], viewer: .bob)

        let creatorSideSubtitles = try value(of: creatorSide.slotsPublisher).prefix(2).map(\.content.subtitle)
        let memberSideSubtitles = try value(of: memberSide.slotsPublisher).prefix(2).map(\.content.subtitle)

        #expect(creatorSideSubtitles == [
            "\(Localization.jointAccountInviteMembersCreator) \(AppConstants.dotSign) \(Localization.jointAccountMembersRoleYou)",
            Localization.jointAccountInviteMembersMember,
        ])
        #expect(memberSideSubtitles == [
            Localization.jointAccountInviteMembersCreator,
            "\(Localization.jointAccountInviteMembersMember) \(AppConstants.dotSign) \(Localization.jointAccountMembersRoleYou)",
        ])
    }

    @Test("A member row is marked by how far the account has come", arguments: StatusCase.allCases)
    func memberStatusFollowsTheAccount(statusCase: StatusCase) throws {
        let (provider, _) = makeSUT(status: statusCase.status, membersCount: 2, members: [creator, bob])

        let statuses = try value(of: provider.slotsPublisher).map(\.content.status)

        #expect(statuses == [statusCase.expectedMemberStatus, statusCase.expectedMemberStatus])
    }

    @Test("The creator sees free slots not invited, with the invite this wallet holds behind the button")
    func creatorInvitesIntoFreeSlots() throws {
        let (provider, _) = makeSUT(membersCount: 3, members: [creator], inviteIds: ["AA"], viewer: .creator)

        let freeSlots = try value(of: provider.slotsPublisher).dropFirst()
        let inviteURL = try inviteURL(id: "AA")

        #expect(freeSlots.map(\.content.subtitle) == [
            Localization.jointAccountInviteMembersNotInvited,
            Localization.jointAccountInviteMembersNotInvited,
        ])
        #expect(freeSlots.map(\.content.accessory) == [.invite(url: inviteURL), .empty])
    }

    @Test("A member sees free slots waiting to join, with nothing to invite by")
    func memberWaitsForFreeSlots() throws {
        let (provider, _) = makeSUT(membersCount: 3, members: [creator, bob], inviteIds: ["AA"], viewer: .bob)

        let freeSlot = try #require(try value(of: provider.slotsPublisher).last)

        #expect(freeSlot.content.subtitle == Localization.jointAccountInviteMembersWaitingToJoin)
        #expect(freeSlot.content.accessory == .empty)
        #expect(!freeSlot.isTappable)
    }

    @Test("The footer counts the free slots for whoever is looking", arguments: FooterCase.allCases)
    func footerCountsFreeSlots(footerCase: FooterCase) throws {
        let (provider, _) = makeSUT(
            status: footerCase.status,
            membersCount: 3,
            members: footerCase.members(creator: creator, bob: bob),
            viewer: footerCase.viewer
        )

        #expect(try value(of: provider.footerPublisher) == footerCase.expectedFooter)
    }

    @Test("Confirming the shared address is offered while collecting and taken by the creator once confirming", arguments: ActionsCase.allCases)
    func actionsFollowStatusAndRole(actionsCase: ActionsCase) throws {
        let (provider, _) = makeSUT(
            status: actionsCase.status,
            membersCount: 2,
            members: actionsCase.status == .pending ? [creator] : [creator, bob],
            viewer: actionsCase.viewer
        )

        #expect(try value(of: provider.actionsPublisher) == actionsCase.expectedActions)
    }

    @Test("A member row opens the member's details, the invite button shares the slot's link with the account name")
    func rowTapsReachTheRoutable() throws {
        let (provider, routable) = makeSUT(membersCount: 2, members: [creator], inviteIds: ["AA"], viewer: .creator)
        let slots = try value(of: provider.slotsPublisher)
        let inviteURL = try inviteURL(id: "AA")

        try #require(slots.first).onTap()
        try #require(slots.last).onInviteTap()

        #expect(routable.openedMemberDetails == [MemberDetails(name: creator.name, address: creator.address)])
        #expect(routable.sharedInvites == [SharedInvite(url: inviteURL, accountName: "Mock Account")])
    }

    @Test("A member who joins gets a row of their own, and the rows already shown stay the same objects")
    func joiningMemberKeepsTheShownRows() async throws {
        let repository = JointAccountsRepositoryStub(
            jointAccounts: [JointAccountCompositionFixture.storedAccount(status: .pending, membersCount: 2, members: [creator])]
        )
        let membersService = JointAccountCompositionFixture.makeMembersService(repository: repository)
        let routable = JointAccountMembersViewSlotRoutableSpy()
        let provider = CommonJointAccountMembersViewModelContentProvider(
            jointAccount: makeJointAccount(status: .pending, membersCount: 2, membersService: membersService),
            routable: routable
        )
        defer { withExtendedLifetime(provider) {} }
        let creatorRow = try #require(try value(of: provider.slotsPublisher).first)

        repository.store([
            JointAccountCompositionFixture.storedAccount(status: .pending, membersCount: 2, members: [creator, bob]),
        ])

        let slots = try await provider.slotsPublisher.first { $0.count == 2 && $0.last?.content.title == "Bob" }.async()

        #expect(slots.first === creatorRow)
        #expect(slots.map(\.id) == [.member(address: creator.address.lowercased()), .member(address: bob.address.lowercased())])
    }
}

// MARK: - Helpers

private extension CommonJointAccountMembersViewModelContentProviderTests {
    var creator: JointAccountMember {
        JointAccountMember(name: "Isaac", address: "0xCreator", role: .creator)
    }

    var bob: JointAccountMember {
        JointAccountMember(name: "Bob", address: "0xBob", role: .member)
    }

    func makeSUT(
        status: JointAccountStatus = .pending,
        membersCount: Int = 3,
        members: [JointAccountMember]? = nil,
        inviteIds: [String] = [],
        viewer: Viewer = .creator
    ) -> (provider: CommonJointAccountMembersViewModelContentProvider, routable: JointAccountMembersViewSlotRoutableSpy) {
        let members = members ?? [creator]
        let freeSlots = (0 ..< max(0, membersCount - members.count)).map { index -> JointAccountSlot in
            let invite = inviteIds[safe: index].flatMap { id in
                URL(string: "https://tangem.com/joint-account/join/\(id)").map { JointAccountInvite(id: id, url: $0) }
            }

            return .empty(invite: invite)
        }

        let membersService = JointAccountMembersServiceMock(
            slots: members.map(JointAccountSlot.member) + freeSlots,
            userRole: viewer.userRole(creator: creator, bob: bob)
        )
        let routable = JointAccountMembersViewSlotRoutableSpy()
        let provider = CommonJointAccountMembersViewModelContentProvider(
            jointAccount: makeJointAccount(status: status, membersCount: membersCount, membersService: membersService),
            routable: routable
        )

        return (provider, routable)
    }

    func makeJointAccount(
        status: JointAccountStatus,
        membersCount: Int,
        membersService: any JointAccountMembersService
    ) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: JointAccountCompositionFixture.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: membersCount, signersCount: 2),
            accountStatus: status,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: membersService,
            delegate: delegate
        )
    }

    func value<Output>(of publisher: AnyPublisher<Output, Never>) throws -> Output {
        var output: Output?
        publisher.sink { output = $0 }.cancel()

        return try #require(output)
    }

    func inviteURL(id: String) throws -> URL {
        try #require(URL(string: "https://tangem.com/joint-account/join/\(id)"))
    }
}

// MARK: - Cases

extension CommonJointAccountMembersViewModelContentProviderTests {
    enum Viewer: Sendable {
        case creator
        case bob

        func userRole(creator: JointAccountMember, bob: JointAccountMember) -> JointAccountUserRole {
            switch self {
            case .creator: .member(creator)
            case .bob: .member(bob)
            }
        }
    }

    enum AccountStage: Sendable {
        case pending
        case confirming
        case active

        var status: JointAccountStatus {
            switch self {
            case .pending: .pending
            case .confirming: .confirming(safeAddress: "0xSafe")
            case .active: .active(safeAddress: "0xSafe")
            }
        }
    }

    enum TitleCase: CaseIterable, Sendable {
        case creatorCollecting
        case memberCollecting
        case confirming
        case active

        var status: JointAccountStatus {
            switch self {
            case .creatorCollecting, .memberCollecting: AccountStage.pending.status
            case .confirming: AccountStage.confirming.status
            case .active: AccountStage.active.status
            }
        }

        var viewer: Viewer {
            switch self {
            case .memberCollecting: .bob
            case .creatorCollecting, .confirming, .active: .creator
            }
        }

        var expectedTitle: JointAccountMembersViewModel.Title {
            switch self {
            case .creatorCollecting:
                .header(text: Localization.jointAccountInviteMembersTitle, subtitle: nil)
            case .memberCollecting:
                .header(text: Localization.jointAccountInviteMembersWaitingTitle, subtitle: nil)
            case .confirming:
                .header(text: Localization.jointAccountConfirmAccountTitle, subtitle: Localization.jointAccountConfirmAccountSubtitle)
            case .active:
                .navigationBar(text: Localization.jointAccountMembersTitle)
            }
        }
    }

    enum StatusCase: CaseIterable, Sendable {
        case pending
        case confirming
        case active

        var status: JointAccountStatus {
            switch self {
            case .pending: AccountStage.pending.status
            case .confirming: AccountStage.confirming.status
            case .active: AccountStage.active.status
            }
        }

        var expectedMemberStatus: JointAccountMembersViewSlotViewModel.Status? {
            switch self {
            case .pending: .joined
            case .confirming: .notConfirmed
            case .active: nil
            }
        }
    }

    enum FooterCase: CaseIterable, Sendable {
        case creatorAlone
        case creatorWithMember
        case member
        case confirming
        case active

        var status: JointAccountStatus {
            switch self {
            case .creatorAlone, .creatorWithMember, .member: AccountStage.pending.status
            case .confirming: AccountStage.confirming.status
            case .active: AccountStage.active.status
            }
        }

        var viewer: Viewer {
            switch self {
            case .member: .bob
            case .creatorAlone, .creatorWithMember, .confirming, .active: .creator
            }
        }

        func members(creator: JointAccountMember, bob: JointAccountMember) -> [JointAccountMember] {
            switch self {
            case .creatorAlone: [creator]
            case .creatorWithMember, .member: [creator, bob]
            case .confirming, .active: [creator, bob, JointAccountMember(name: "Carol", address: "0xCarol", role: .member)]
            }
        }

        var expectedFooter: String? {
            switch self {
            case .creatorAlone: Localization.jointAccountInviteMembersInviteCount(2)
            case .creatorWithMember: Localization.jointAccountInviteMembersInviteMore(1)
            case .member: Localization.jointAccountInviteMembersAwaitingToJoin(1)
            case .confirming, .active: nil
            }
        }
    }

    enum ActionsCase: CaseIterable, Sendable {
        case creatorCollecting
        case memberCollecting
        case creatorConfirming
        case memberConfirming
        case active

        var status: JointAccountStatus {
            switch self {
            case .creatorCollecting, .memberCollecting: AccountStage.pending.status
            case .creatorConfirming, .memberConfirming: AccountStage.confirming.status
            case .active: AccountStage.active.status
            }
        }

        var viewer: Viewer {
            switch self {
            case .memberCollecting, .memberConfirming: .bob
            case .creatorCollecting, .creatorConfirming, .active: .creator
            }
        }

        var expectedActions: [JointAccountMembersViewModel.Action] {
            switch self {
            case .creatorCollecting, .memberCollecting: [.confirmSharedAddress(isEnabled: false)]
            case .creatorConfirming: [.confirmSharedAddress(isEnabled: true)]
            case .memberConfirming, .active: []
            }
        }
    }
}

// MARK: - Stubs

private struct MemberDetails: Equatable {
    let name: String
    let address: String
}

private struct SharedInvite: Equatable {
    let url: URL
    let accountName: String
}

private final class JointAccountMembersViewSlotRoutableSpy: JointAccountMembersViewSlotRoutable {
    private(set) var openedMemberDetails: [MemberDetails] = []
    private(set) var sharedInvites: [SharedInvite] = []

    func shareInvite(url: URL, accountName: String) {
        sharedInvites.append(SharedInvite(url: url, accountName: accountName))
    }

    func openMemberDetails(name: String, address: String, accentColor: Color) {
        openedMemberDetails.append(MemberDetails(name: name, address: address))
    }
}
