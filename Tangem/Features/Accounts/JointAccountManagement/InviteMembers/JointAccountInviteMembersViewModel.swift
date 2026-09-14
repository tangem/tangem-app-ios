//
//  JointAccountInviteMembersViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

final class JointAccountInviteMembersViewModel: ObservableObject {
    @Published private(set) var content: Content
    @Published private(set) var isActivating = false
    @Published var alert: AlertBinder?

    private let jointAccount: any JointAccountModel
    private let accountModelsManager: any AccountModelsManager
    private weak var coordinator: JointAccountInviteMembersRoutable?

    private var bag = Set<AnyCancellable>()

    init(
        jointAccount: any JointAccountModel,
        accountModelsManager: any AccountModelsManager,
        coordinator: JointAccountInviteMembersRoutable?
    ) {
        self.jointAccount = jointAccount
        self.accountModelsManager = accountModelsManager
        self.coordinator = coordinator

        content = Self.makeContent(of: jointAccount)

        bind()
    }

    func onInviteTap(inviteURL: URL) {
        coordinator?.shareInvite(url: inviteURL)
    }

    func onSafetyBannerTap() {
        coordinator?.openInviteSafety()
    }

    func onMemberInfoTap(memberIndex: Int) {
        guard let member = jointAccount.members[safe: memberIndex] else {
            JointAccountsLogger.warning("The tapped row of the joint account holds no member to tell about")
            return
        }

        coordinator?.openMemberDetails(
            name: member.name,
            address: member.address,
            accentColor: CompositeIconColorPalette.color(for: Self.iconColor(at: memberIndex))
        )
    }

    @MainActor
    func onActivateTap() {
        // Raised here rather than inside the task, which reaches the main actor a hop later — by then a second tap
        // would have passed this check and asked for a second card session
        guard !isActivating else {
            return
        }

        coordinator?.openActivationConfirmation { [weak self] in
            self?.activate()
        }
    }

    func onArchiveTap() {
        // [REDACTED_TODO_COMMENT]
    }

    func onCloseTap() {
        coordinator?.closeInviteMembers()
    }
}

// MARK: - Private

private extension JointAccountInviteMembersViewModel {
    @MainActor
    func activate() {
        isActivating = true

        runTask(in: self) { viewModel in
            await viewModel.performActivation()
        }
    }

    @MainActor
    func performActivation() async {
        defer { isActivating = false }

        do throws(AccountEditError) {
            try await accountModelsManager.activateJointAccount(jointAccount)
        } catch .unknownError(let underlying) where underlying.isCancellationError {
            // The card session was dismissed; the screen stays as it was, with nothing to report
            return
        } catch {
            alert = AccountEditErrorAlertBuilder.makeAlert(for: error)
            return
        }

        // The screen exists to gather the members, and they are gathered — the account is a working one from here on
        // [REDACTED_TODO_COMMENT]
        coordinator?.closeInviteMembers()
    }

    /// A slot is taken on the account this screen was opened with rather than on a model of its own, so the rows are
    /// worked out anew whenever it says it has changed.
    func bind() {
        jointAccount
            .didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.content = Self.makeContent(of: viewModel.jointAccount)
            }
            .store(in: &bag)
    }

    static func makeContent(of jointAccount: any JointAccountModel) -> Content {
        Content(
            members: makeMembers(of: jointAccount),
            freeSlots: makeFreeSlots(of: jointAccount),
            isActivationAvailable: jointAccount.canActivate
        )
    }

    static func makeMembers(of jointAccount: any JointAccountModel) -> [MemberViewData] {
        jointAccount.members.enumerated().map { index, member in
            MemberViewData(
                id: member.address,
                // [REDACTED_TODO_COMMENT]
                icon: AddressBookContactNameIconViewData(
                    letter: member.name.prefix(1).uppercased(),
                    color: CompositeIconColorPalette.color(for: iconColor(at: index))
                ),
                name: member.name,
                role: role(of: member, isCreatorDevice: jointAccount.invites.isNotEmpty),
                memberIndex: index
            )
        }
    }

    /// - Note: Every free slot is worth a row, whether or not this wallet holds the invite that opens it.
    static func makeFreeSlots(of jointAccount: any JointAccountModel) -> [FreeSlotViewData] {
        let linkBuilder = JointAccountInviteLinkBuilder()
        let inviteURLs = jointAccount.unusedInvites.compactMap { invite -> URL? in
            guard let url = linkBuilder.buildURL(invite: invite) else {
                // Says nothing of the invite itself: a log is the last place the account's access secret belongs
                JointAccountsLogger.warning("An invite of the joint account cannot be written as a link")
                return nil
            }

            return url
        }

        return (0 ..< jointAccount.freeSlotsCount).map { slotIndex in
            FreeSlotViewData(
                id: slotIndex,
                inviteURL: inviteURLs[safe: slotIndex]
            )
        }
    }

    /// - Note: Told apart by holding an invite, which is the creator's alone — the endpoint names no wallet as this one.
    static func role(of member: JointAccountMember, isCreatorDevice: Bool) -> String {
        switch member.role {
        case .creator where isCreatorDevice:
            return "\(Localization.jointAccountMembersRoleYou) \(AppConstants.dotSign) \(Localization.jointAccountInviteMembersCreator)"
        case .creator:
            return Localization.jointAccountInviteMembersCreator
        case .member:
            return Localization.jointAccountMembersRoleJoined
        }
    }

    /// Taken by the slot rather than by the member, so that two members of one account never share a colour.
    static func iconColor(at index: Int) -> CompositeIconColor {
        let colors = CompositeIconColor.allCases

        return colors[index % colors.count]
    }
}

// MARK: - Auxiliary types

extension JointAccountInviteMembersViewModel {
    struct Content {
        /// The taken slots, in the order they were taken, the creator first.
        let members: [MemberViewData]
        let freeSlots: [FreeSlotViewData]
        /// Only the creator activates, and only once every slot is taken.
        let isActivationAvailable: Bool

        var joinedMembersCount: Int { members.count }
        var totalMembersCount: Int { members.count + freeSlots.count }
    }

    struct MemberViewData: Identifiable {
        /// The member's address, which is what tells two members of one name apart.
        let id: String
        let icon: AddressBookContactNameIconViewData
        let name: String
        let role: String
        let memberIndex: Int
    }

    struct FreeSlotViewData: Identifiable {
        let id: Int
        /// Nil for a slot this wallet holds no invite for: they are handed out once, and to the creator alone.
        let inviteURL: URL?
    }
}
