//
//  JointAccountInviteMembersViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class JointAccountInviteMembersViewModel: ObservableObject {
    var joinedMembersCount: Int {
        jointAccount.members.count
    }

    var totalMembersCount: Int {
        jointAccount.jointAccountConfig.membersCount
    }

    var invitableSlotsCount: Int {
        jointAccount.freeSlotsCount
    }

    var creatorName: String {
        jointAccount.creator?.name ?? ""
    }

    var creatorIconViewData: AddressBookContactNameIconViewData {
        // [REDACTED_TODO_COMMENT]
        AddressBookContactNameIconViewData(
            letter: creatorName.prefix(1).uppercased(),
            color: CompositeIconColorPalette.color(for: .azure)
        )
    }

    private let jointAccount: any JointAccountModel
    private weak var coordinator: JointAccountInviteMembersRoutable?

    init(
        jointAccount: any JointAccountModel,
        coordinator: JointAccountInviteMembersRoutable?
    ) {
        self.jointAccount = jointAccount
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
