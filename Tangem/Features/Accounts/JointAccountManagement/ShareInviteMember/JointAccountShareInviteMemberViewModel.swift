//
//  JointAccountShareInviteMemberViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class JointAccountShareInviteMemberViewModel: Identifiable {
    var message: String { inviteActivityItemSource.message }
    var link: String { [inviteActivityItemSource.url.host, inviteActivityItemSource.url.path].compactMap { $0 }.joined() }

    private let inviteActivityItemSource: JointAccountInviteActivityItemSource
    private let copyHelper = JointAccountCopyHelper()
    private weak var coordinator: JointAccountShareInviteMemberRoutable?

    init(
        inviteActivityItemSource: JointAccountInviteActivityItemSource,
        coordinator: JointAccountShareInviteMemberRoutable?
    ) {
        self.inviteActivityItemSource = inviteActivityItemSource
        self.coordinator = coordinator
    }

    func onShareTap() {
        coordinator?.shareInvite(item: inviteActivityItemSource)
    }

    func onMessageTap() {
        copyHelper.copy(inviteActivityItemSource.shareMessage, toast: Localization.commonValueCopied)
    }
}
