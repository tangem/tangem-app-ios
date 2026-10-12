//
//  JointAccountInviteSafetyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol TangemUI.FloatingSheetContentViewModel

final class JointAccountInviteSafetyViewModel: FloatingSheetContentViewModel {
    private weak var coordinator: JointAccountInviteSafetyRoutable?

    init(coordinator: JointAccountInviteSafetyRoutable?) {
        self.coordinator = coordinator
    }

    func onCloseTap() {
        coordinator?.closeInviteSafety()
    }
}
