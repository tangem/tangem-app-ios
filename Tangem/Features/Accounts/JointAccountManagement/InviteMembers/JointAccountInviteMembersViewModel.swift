//
//  JointAccountInviteMembersViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class JointAccountInviteMembersViewModel: ObservableObject {
    /// Only the creator is in so far, the invites are what fills the remaining slots.
    let joinedMembersCount = 1

    var totalMembersCount: Int {
        creationContext.membersCount ?? joinedMembersCount
    }

    var invitableSlotsCount: Int {
        totalMembersCount - joinedMembersCount
    }

    var creatorName: String {
        creationContext.creatorName ?? ""
    }

    var creatorIconViewData: AddressBookContactNameIconViewData {
        // [REDACTED_TODO_COMMENT]
        AddressBookContactNameIconViewData(
            letter: creatorName.prefix(1).uppercased(),
            color: CompositeIconColorPalette.color(for: .azure)
        )
    }

    private let creationContext: JointAccountCreationHelper
    private weak var coordinator: JointAccountInviteMembersRoutable?

    init(
        creationContext: JointAccountCreationHelper,
        coordinator: JointAccountInviteMembersRoutable?
    ) {
        self.creationContext = creationContext
        self.coordinator = coordinator
    }

    func onInviteTap() {
        coordinator?.shareInvite()
    }

    func onSafetyBannerTap() {
        coordinator?.openInviteSafety()
    }

    func onCreatorInfoTap() {
        coordinator?.openMemberDetails()
    }

    func onArchiveTap() {
        // [REDACTED_TODO_COMMENT]
    }

    func onCloseTap() {
        coordinator?.closeInviteMembers()
    }
}
