//
//  TangemPayWithdrawNoteSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI
import TangemLocalization

final class TangemPayWithdrawNoteSheetViewModel {
    @Injected(\.alertPresenterViewModel)
    private var alertPresenterViewModel: AlertPresenterViewModel

    private weak var coordinator: TangemPayWithdrawNoteSheetRoutable?
    private let openWithdrawal: () -> Void

    init(
        coordinator: TangemPayWithdrawNoteSheetRoutable,
        openWithdrawal: @escaping () -> Void
    ) {
        self.coordinator = coordinator
        self.openWithdrawal = openWithdrawal
    }

    var gotItButton: MainButton.Settings {
        .init(
            title: Localization.commonGotIt,
            style: .primary,
            action: openWithdrawal
        )
    }

    func close() {
        coordinator?.closeWithdrawNoteSheetPopup()
    }
}

extension TangemPayWithdrawNoteSheetViewModel: FloatingSheetContentViewModel {
    var id: String {
        String(describing: self)
    }
}
