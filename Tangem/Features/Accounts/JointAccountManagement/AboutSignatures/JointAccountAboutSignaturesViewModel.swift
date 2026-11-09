//
//  JointAccountAboutSignaturesViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

final class JointAccountAboutSignaturesViewModel: Identifiable {
    let description: String

    private weak var coordinator: JointAccountAboutSignaturesRoutable?

    init(policy: JointAccountPolicy, coordinator: JointAccountAboutSignaturesRoutable) {
        description = Localization.jointAccountInviteMembersAboutSignaturesDescription(policy.signersCount, policy.membersCount)
        self.coordinator = coordinator
    }

    func onCloseTap() {
        coordinator?.closeAboutSignatures()
    }
}
