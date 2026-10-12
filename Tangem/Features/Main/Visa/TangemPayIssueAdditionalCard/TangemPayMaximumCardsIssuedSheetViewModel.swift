//
//  TangemPayMaximumCardsIssuedSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization

protocol TangemPayMaximumCardsIssuedSheetRoutable: AnyObject {
    func closeMaximumCardsIssuedSheet()
}

final class TangemPayMaximumCardsIssuedSheetViewModel: TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Error.regular28.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    var title: AttributedString {
        .init(Localization.tangempayMaximumCardsIssuedTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayMaximumCardsIssuedDescription)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonGotIt,
            style: .primary,
            size: .default,
            action: dismiss
        )
    }

    var primaryButtonAccessibilityIdentifier: String? {
        TangemPayAccessibilityIdentifiers.maximumCardsIssuedConfirmButton
    }

    private weak var coordinator: TangemPayMaximumCardsIssuedSheetRoutable?

    init(coordinator: TangemPayMaximumCardsIssuedSheetRoutable?) {
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeMaximumCardsIssuedSheet()
    }
}
