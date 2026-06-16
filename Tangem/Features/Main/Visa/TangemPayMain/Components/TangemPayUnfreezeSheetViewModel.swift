//
//  TangemPayUnfreezeSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers

protocol TangemPayUnfreezeSheetRoutable: AnyObject {
    func closeUnfreezeSheet()
}

final class TangemPayUnfreezeSheetViewModel: FloatingSheetContentViewModel, TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Sun.regular24.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    var title: AttributedString {
        .init(Localization.tangemPayUnfreezeCardAlertTitle)
    }

    var description: AttributedString {
        .init(Localization.tangemPayUnfreezeCardAlertBody)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangempayCardDetailsUnfreezeCard,
            style: .primary,
            size: .default,
            action: unfreeze
        )
    }

    var secondaryButton: MainButton.Settings? {
        MainButton.Settings(
            title: Localization.commonCancel,
            style: .secondary,
            size: .default,
            action: dismiss
        )
    }

    var primaryButtonAccessibilityIdentifier: String? {
        TangemPayAccessibilityIdentifiers.unfreezeSheetConfirmButton
    }

    let userWalletId: UserWalletId
    weak var coordinator: TangemPayUnfreezeSheetRoutable?
    let unfreezeAction: () -> Void

    init(
        userWalletId: UserWalletId,
        coordinator: TangemPayUnfreezeSheetRoutable,
        unfreezeAction: @escaping () -> Void
    ) {
        self.userWalletId = userWalletId
        self.coordinator = coordinator
        self.unfreezeAction = unfreezeAction

        Analytics.log(.visaScreenUnfreezeCardConfirmShown, contextParams: .userWallet(userWalletId))
    }

    func dismiss() {
        coordinator?.closeUnfreezeSheet()
    }

    func unfreeze() {
        Analytics.log(.visaScreenUnfreezeCardConfirmClicked, contextParams: .userWallet(userWalletId))
        unfreezeAction()
        dismiss()
    }
}
