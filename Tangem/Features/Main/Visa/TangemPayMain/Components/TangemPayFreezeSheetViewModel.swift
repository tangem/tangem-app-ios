//
//  TangemPayFreezeSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers

protocol TangemPayFreezeSheetRoutable: AnyObject {
    func closeFreezeSheet()
}

final class TangemPayFreezeSheetViewModel: FloatingSheetContentViewModel, TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Snowflake.regular24.image
    }

    var title: AttributedString {
        .init(Localization.tangemPayFreezeCardAlertTitle)
    }

    var description: AttributedString {
        .init(Localization.tangemPayFreezeCardAlertBody)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: isRedesigned ? Localization.tangempayCardDetailsFreezeCard : Localization.tangemPayFreezeCardFreeze,
            style: .primary,
            size: .default,
            action: freeze
        )
    }

    var primaryButtonAccessibilityIdentifier: String? {
        TangemPayAccessibilityIdentifiers.freezeSheetConfirmButton
    }

    var secondaryButton: MainButton.Settings? {
        guard isRedesigned else {
            return nil
        }

        return MainButton.Settings(
            title: Localization.commonCancel,
            style: .secondary,
            size: .default,
            action: dismiss
        )
    }

    private var isRedesigned: Bool {
        FeatureProvider.isAvailable(.tangemPaySpendRedesign)
    }

    let userWalletId: UserWalletId
    weak var coordinator: TangemPayFreezeSheetRoutable?
    let freezeAction: () -> Void

    init(
        userWalletId: UserWalletId,
        coordinator: TangemPayFreezeSheetRoutable,
        freezeAction: @escaping () -> Void
    ) {
        self.userWalletId = userWalletId
        self.coordinator = coordinator
        self.freezeAction = freezeAction

        Analytics.log(.visaScreenFreezeCardConfirmShown, contextParams: .userWallet(userWalletId))
    }

    func dismiss() {
        coordinator?.closeFreezeSheet()
    }

    func freeze() {
        Analytics.log(.visaScreenFreezeCardConfirmClicked, contextParams: .userWallet(userWalletId))
        freezeAction()
        dismiss()
    }
}
