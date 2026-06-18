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
import TangemAccessibilityIdentifiers

final class TangemPayWithdrawNoteSheetViewModel: TangemPayPopupViewModel {
    private weak var coordinator: TangemPayWithdrawNoteSheetRoutable?
    private let openWithdrawal: () -> Void

    var primaryButton: MainButton.Settings {
        .init(
            title: Localization.commonGotIt,
            style: .primary,
            action: openWithdrawal
        )
    }

    var secondaryButton: MainButton.Settings?

    var primaryButtonAccessibilityIdentifier: String? {
        TangemPayAccessibilityIdentifiers.withdrawNoteSheetPrimaryButton
    }

    var title: AttributedString {
        .init(Localization.tangempayWithdrawalNoteTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayWithdrawalNoteDescription)
    }

    var icon: Image {
        FeatureProvider.isAvailable(.tangemPaySpendRedesign)
            ? DesignSystem.Icons.Error.regular28.image
            : Assets.warningIcon.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
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
