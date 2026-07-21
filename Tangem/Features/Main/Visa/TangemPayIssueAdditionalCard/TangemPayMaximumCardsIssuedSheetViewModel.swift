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

    let cardsCount: Int
    let onClose: () -> Void

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

    // [REDACTED_TODO_COMMENT]
    var description: AttributedString {
        .init("You have \(cardsCount) cards. Delete one to add a new card.")
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonGotIt,
            style: .primary,
            size: .default,
            action: onClose
        )
    }

    private let cardsCount: Int
    private let onClose: () -> Void

    init(cardsCount: Int, onClose: @escaping () -> Void) {
        self.cardsCount = cardsCount
        self.onClose = onClose
    }

    func dismiss() {
        onClose()
    }
}
