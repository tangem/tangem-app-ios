//
//  JointAccountActivationConfirmationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol TangemUI.FloatingSheetContentViewModel

final class JointAccountActivationConfirmationViewModel: FloatingSheetContentViewModel {
    private weak var coordinator: JointAccountActivationConfirmationRoutable?

    init(coordinator: JointAccountActivationConfirmationRoutable?) {
        self.coordinator = coordinator
    }

    func onActivateTap() {
        coordinator?.confirmActivation()
    }

    func onCancelTap() {
        coordinator?.cancelActivation()
    }
}
