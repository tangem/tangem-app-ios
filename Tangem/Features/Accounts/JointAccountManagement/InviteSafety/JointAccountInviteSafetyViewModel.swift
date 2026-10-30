//
//  JointAccountInviteSafetyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

final class JointAccountInviteSafetyViewModel: Identifiable {
    private weak var coordinator: JointAccountInviteSafetyRoutable?

    init(coordinator: JointAccountInviteSafetyRoutable?) {
        self.coordinator = coordinator
    }

    func onCloseTap() {
        coordinator?.closeInviteSafety()
    }
}
