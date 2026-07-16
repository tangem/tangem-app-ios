//
//  TangemPayMaximumCardsIssuedSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayMaximumCardsIssuedSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = Localization.tangempayMaximumCardsIssuedTitle
    let description = Localization.tangempayMaximumCardsIssuedDescription

    let onClose: () -> Void

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonGotIt,
            style: .secondary,
            size: .default,
            action: onClose
        )
    }

    func dismiss() {
        onClose()
    }
}

@MainActor
final class TangemPayMaximumCardsIssuedPopupViewModel: TangemPayPopupViewModel {
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
            action: onClose
        )
    }

    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func dismiss() {
        onClose()
    }
}
