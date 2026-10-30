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
    let message: String
    let link: String

    private let shareMessage: String
    private let copyHelper = JointAccountCopyHelper()
    private weak var coordinator: JointAccountShareInviteMemberRoutable?

    init(accountName: String, url: URL, coordinator: JointAccountShareInviteMemberRoutable?) {
        self.coordinator = coordinator

        message = Localization.jointAccountInviteMemberMessage(accountName, "").trimmed()
        link = [url.host, url.path].compactMap { $0 }.joined()
        shareMessage = Localization.jointAccountInviteMemberMessage(accountName, url.absoluteString)
    }

    func onShareTap() {
        coordinator?.shareInvite(message: shareMessage)
    }

    func onMessageTap() {
        copyHelper.copy(shareMessage, toast: Localization.commonValueCopied)
    }
}
