//
//  JointAccountJoinConfirmationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol TangemUI.FloatingSheetContentViewModel

final class JointAccountJoinConfirmationViewModel: FloatingSheetContentViewModel {
    /// The wallet and the invite picked on the invite screen, carried through so the sheet hands them back on confirmation.
    private let userWalletModel: any UserWalletModel
    private let preview: JointAccountInvitePreview
    private weak var coordinator: JointAccountJoinConfirmationRoutable?

    init(
        userWalletModel: any UserWalletModel,
        preview: JointAccountInvitePreview,
        coordinator: JointAccountJoinConfirmationRoutable?
    ) {
        self.userWalletModel = userWalletModel
        self.preview = preview
        self.coordinator = coordinator
    }

    func onContinueTap() {
        coordinator?.confirmJoin(userWalletModel: userWalletModel, preview: preview)
    }

    func onCancelTap() {
        coordinator?.cancelJoin()
    }
}
