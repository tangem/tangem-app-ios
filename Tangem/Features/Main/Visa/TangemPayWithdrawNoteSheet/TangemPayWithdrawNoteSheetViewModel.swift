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
    private let parameters: PredefinedSwapParameters

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
        parameters: PredefinedSwapParameters,
        coordinator: TangemPayWithdrawNoteSheetRoutable
    ) {
        self.parameters = parameters
        self.coordinator = coordinator
    }

    func openWithdrawal() {
        coordinator?.openWithdrawal(parameters: parameters)
    }

    func dismiss() {
        coordinator?.closeWithdrawNoteSheetPopup()
    }
}
