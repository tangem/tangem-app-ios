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
import TangemUI
import struct TangemUIUtils.AlertBinder

final class JointAccountInviteMembersViewModel: ObservableObject {
    @Published private(set) var content: Content
    @Published private(set) var isActivating = false
    @Published var alert: AlertBinder?
    @Published private(set) var isArchiving = false
    @Published var isArchiveConfirmationPresented = false

    private let jointAccount: any JointAccountModel
    private weak var coordinator: JointAccountInviteMembersRoutable?

    private var bag = Set<AnyCancellable>()
    private var frequentUpdatesSubscription: AnyCancellable?

    init(
        jointAccount: any JointAccountModel,
        coordinator: JointAccountInviteMembersRoutable?
    ) {
        self.jointAccount = jointAccount
        self.coordinator = coordinator

        content = Self.makeContent(of: jointAccount, slots: jointAccount.jointAccountMembersService.slots)

        bind()
    }

    func onWillAppear() {
        frequentUpdatesSubscription = jointAccount.jointAccountMembersService.requestFrequentUpdates()
    }

    func onWillDisappear() {
        frequentUpdatesSubscription = nil
    }

    func onInviteTap(inviteURL: URL) {
        coordinator?.shareInvite(url: inviteURL)
    }

    func onSafetyBannerTap() {
        coordinator?.openInviteSafety()
    }

    /// - Note: Everything the details are opened with comes off the row that was tapped, so a composition that has
    /// moved on since it was drawn cannot put another member behind it.
    func onMemberInfoTap(_ viewData: MemberViewData) {
        coordinator?.openMemberDetails(
            name: viewData.name,
            address: viewData.member.address,
            accentColor: viewData.icon.color
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
        isArchiveConfirmationPresented = true
    }

    @MainActor
    func onArchiveConfirmTap() {
        // Raised here rather than inside the task, which reaches the main actor a hop later
        guard !isArchiving else {
            return
        }

        isArchiving = true

        runTask(in: self) { viewModel in
            await viewModel.performArchiving()
        }
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
            try await jointAccount.activate()
        } catch .unknownError(let underlying) where underlying.isCancellationError {
            // The card session was dismissed; the screen stays as it was, with nothing to report
            return
        } catch {
            alert = AccountEditErrorAlertBuilder.makeAlert(for: error)
            return
        }

        // The members are gathered, which is all this screen was for
        // [REDACTED_TODO_COMMENT]
        coordinator?.closeInviteMembers()
    }

    @MainActor
    func performArchiving() async {
        defer { isArchiving = false }

        do throws(AccountArchivationError) {
            try await jointAccount.archive()
        } catch {
            alert = AccountArchivationErrorAlertBuilder.makeAlert(for: error)
            JointAccountsLogger.error("Failed to archive the joint account", error: error)
            return
        }

        coordinator?.closeInviteMembers()

        Toast(view: SuccessToast(text: Localization.accountArchiveSuccessMessage))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary(interval: Constants.toastInterval))
    }

    /// Rebuilt whole rather than patched: every row is worked out from the slots, and a slot is taken on the account
    /// rather than on a model of this screen's own.
    /// - Note: The composition is followed apart from the account, whose own changes say nothing of who joined. It is
    /// a stream of state, so its rows are drawn from what it hands out rather than read back off the service.
    func bind() {
        Publishers
            .CombineLatest(
                // Prepended because the account reports changes rather than state: without a value of its own the
                // combination would wait for one, and the composition would not be drawn until the account moved
                jointAccount.didChangePublisher.prepend(()),
                jointAccount.jointAccountMembersService.slotsPublisher
            )
            .map { _, slots in slots }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, slots in
                viewModel.content = Self.makeContent(of: viewModel.jointAccount, slots: slots)
            }
            .store(in: &bag)
    }

    /// - Note: An account the store no longer holds has no slots, and the screen says so rather than keeping rows
    /// whose invite links and activate button no longer lead anywhere.
    static func makeContent(of jointAccount: any JointAccountModel, slots: [JointAccountSlot]) -> Content {
        let isCreatorDevice = jointAccount.jointAccountMembersService.isCreatorDevice
        let ownAddress = jointAccount.jointAccountMembersService.ownAddress

        let members = slots.enumerated().compactMap { index, slot -> MemberViewData? in
            guard case .member(let member) = slot else {
                return nil
            }

            return MemberViewData(
                member: member,
                // [REDACTED_TODO_COMMENT]
                icon: AddressBookContactNameIconViewData(
                    letter: member.name.prefix(1).uppercased(),
                    color: CompositeIconColorPalette.color(for: iconColor(at: index))
                ),
                role: role(of: member, ownAddress: ownAddress, isCreatorDevice: isCreatorDevice)
            )
        }

        // Taken off the slots rather than off the invites: a slot this wallet holds no invite for is a row all the
        // same, and the count the screen reports is the account's rather than this wallet's share of it
        let freeSlots = slots.enumerated().compactMap { index, slot -> FreeSlotViewData? in
            guard case .empty(let invite) = slot else {
                return nil
            }

            return FreeSlotViewData(id: index, invite: invite)
        }

        return Content(
            members: members,
            freeSlots: freeSlots,
            isActivationAvailable: jointAccount.canActivate,
            canArchive: isCreatorDevice
        )
    }
}

// MARK: - Member appearance

extension JointAccountInviteMembersViewModel {
    static func role(of member: JointAccountMember, ownAddress: String?, isCreatorDevice: Bool) -> String {
        let isOwn: Bool
        if let ownAddress {
            isOwn = member.address.caseInsensitiveEquals(to: ownAddress)
        } else {
            isOwn = member.role == .creator && isCreatorDevice
        }

        switch (member.role, isOwn) {
        case (.creator, true):
            return "\(Localization.jointAccountMembersRoleYou) \(AppConstants.dotSign) \(Localization.jointAccountInviteMembersCreator)"
        case (.creator, false):
            return Localization.jointAccountInviteMembersCreator
        case (.member, true):
            return Localization.jointAccountMembersRoleYou
        case (.member, false):
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
        let isActivationAvailable: Bool
        /// Offered on the creator's device alone — see `JointAccountMembersService.isCreatorDevice`.
        let canArchive: Bool

        var joinedMembersCount: Int { members.count }
        var totalMembersCount: Int { members.count + freeSlots.count }
    }

    struct MemberViewData: Identifiable {
        /// The member's address, which is what tells two members of one name apart.
        var id: String { member.address }
        var name: String { member.name }

        let member: JointAccountMember
        let icon: AddressBookContactNameIconViewData
        let role: String
    }

    struct FreeSlotViewData: Identifiable {
        /// The slot's place in the composition, which is what tells two free slots apart.
        let id: Int
        /// Nil for a slot this wallet holds no invite for.
        let invite: JointAccountInvite?
    }
}

// MARK: - Constants

private extension JointAccountInviteMembersViewModel {
    enum Constants {
        static let toastTopPadding: CGFloat = 24
        static let toastInterval: TimeInterval = 4
    }
}
