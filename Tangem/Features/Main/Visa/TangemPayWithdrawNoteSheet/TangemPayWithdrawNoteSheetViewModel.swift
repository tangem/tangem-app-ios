//
//  TangemPayWithdrawNoteSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

final class TangemPayWithdrawNoteSheetViewModel: TangemPayPopupViewModel {
    @Injected(\.alertPresenterViewModel)
    private var alertPresenterViewModel: AlertPresenterViewModel

    private weak var coordinator: TangemPayWithdrawNoteSheetRoutable?
    private let openWithdrawal: () -> Void

    var primaryButton: MainButton.Settings {
        .init(
            title: Localization.commonGotIt,
            style: .primary,
            action: openWithdrawal
        )
    }

    var secondaryButton: MainButton.Settings? = nil

    var title: AttributedString {
        .init(Localization.tangempayWithdrawalNoteTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayWithdrawalNoteDescription)
    }

    var icon: Image {
        Assets.warningIcon.image
    }

    init(
        coordinator: TangemPayWithdrawNoteSheetRoutable,
        openWithdrawal: @escaping () -> Void
    ) {
        self.coordinator = coordinator
        self.openWithdrawal = openWithdrawal
    }

    func dismiss() {
        coordinator?.closeWithdrawNoteSheetPopup()
    }
}
