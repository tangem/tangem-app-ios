//
//  TangemPayErrorRetryPopupViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

@MainActor
final class TangemPayErrorRetryPopupViewModel: TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Error.regular28.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    var title: AttributedString {
        .init(Localization.commonSomethingWentWrong)
    }

    var description: AttributedString {
        .init(Localization.commonTryAgainLater)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonRetry,
            style: .primary,
            size: .default,
            action: onRetry
        )
    }

    var secondaryButton: MainButton.Settings? {
        MainButton.Settings(
            title: Localization.commonClose,
            style: .secondary,
            size: .default,
            action: onClose
        )
    }

    private let onRetry: () -> Void
    private let onClose: () -> Void

    init(onRetry: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.onRetry = onRetry
        self.onClose = onClose
    }

    func dismiss() {
        onClose()
    }
}
