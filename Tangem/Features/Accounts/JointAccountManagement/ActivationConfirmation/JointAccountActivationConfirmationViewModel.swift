//
//  JointAccountActivationConfirmationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol TangemUI.FloatingSheetContentViewModel

final class JointAccountActivationConfirmationViewModel: FloatingSheetContentViewModel {
    let hasNFCInteraction: Bool

    /// What activating the account takes, carried through so the sheet hands it back on confirmation.
    private let onConfirm: () -> Void
    private weak var coordinator: JointAccountActivationConfirmationRoutable?

    init(
        hasNFCInteraction: Bool,
        onConfirm: @escaping () -> Void,
        coordinator: JointAccountActivationConfirmationRoutable?
    ) {
        self.hasNFCInteraction = hasNFCInteraction
        self.onConfirm = onConfirm
        self.coordinator = coordinator
    }

    func onActivateTap() {
        coordinator?.confirmActivation(onConfirm)
    }

    func onCancelTap() {
        coordinator?.cancelActivation()
    }
}
