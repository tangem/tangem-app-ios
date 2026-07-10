//
//  TangemPayVirtualAccountBankDetailsErrorPopupViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

@MainActor
final class TangemPayVirtualAccountBankDetailsErrorPopupViewModel: TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Error.regular28.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    // [REDACTED_TODO_COMMENT]
    var title: AttributedString {
        .init("Couldn't load banking details")
    }

    // [REDACTED_TODO_COMMENT]
    var description: AttributedString {
        .init("Please try again or contact support if the issue persists")
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
            title: Localization.commonContactSupport,
            style: .secondary,
            size: .default,
            action: onContactSupport
        )
    }

    private let onRetry: () -> Void
    private let onContactSupport: () -> Void
    private let onClose: () -> Void

    init(
        onRetry: @escaping () -> Void,
        onContactSupport: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onRetry = onRetry
        self.onContactSupport = onContactSupport
        self.onClose = onClose
    }

    func dismiss() {
        onClose()
    }
}
