//
//  JointAccountJoinConfirmationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol TangemUI.FloatingSheetContentViewModel

final class JointAccountJoinConfirmationViewModel: FloatingSheetContentViewModel {
    /// The wallet picked on the invite screen, carried through so the sheet hands it back on confirmation.
    private let userWalletModel: any UserWalletModel
    private weak var coordinator: JointAccountJoinConfirmationRoutable?

    init(userWalletModel: any UserWalletModel, coordinator: JointAccountJoinConfirmationRoutable?) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    func onContinueTap() {
        coordinator?.confirmJoin(userWalletModel: userWalletModel)
    }

    func onCancelTap() {
        coordinator?.cancelJoin()
    }
}
