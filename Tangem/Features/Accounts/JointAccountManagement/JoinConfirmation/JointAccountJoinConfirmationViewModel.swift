//
//  JointAccountJoinConfirmationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol TangemUI.FloatingSheetContentViewModel

final class JointAccountJoinConfirmationViewModel: FloatingSheetContentViewModel {
    private weak var coordinator: JointAccountJoinConfirmationRoutable?

    init(coordinator: JointAccountJoinConfirmationRoutable?) {
        self.coordinator = coordinator
    }

    func onContinueTap() {
        coordinator?.confirmJoin()
    }

    func onCancelTap() {
        coordinator?.cancelJoin()
    }
}
