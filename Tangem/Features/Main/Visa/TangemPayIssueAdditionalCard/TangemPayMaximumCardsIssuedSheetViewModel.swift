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

protocol TangemPayMaximumCardsIssuedSheetRoutable: AnyObject {
    func closeMaximumCardsIssuedSheet()
}

@MainActor
final class TangemPayMaximumCardsIssuedSheetViewModel: FloatingSheetContentViewModel {
    nonisolated var id: String { String(describing: Self.self) }

    let title = Localization.tangempayMaximumCardsIssuedTitle
    let description = Localization.tangempayMaximumCardsIssuedDescription

    private weak var coordinator: TangemPayMaximumCardsIssuedSheetRoutable?

    init(coordinator: TangemPayMaximumCardsIssuedSheetRoutable) {
        self.coordinator = coordinator
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonGotIt,
            style: .secondary,
            size: .default,
            action: dismiss
        )
    }

    func dismiss() {
        coordinator?.closeMaximumCardsIssuedSheet()
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
