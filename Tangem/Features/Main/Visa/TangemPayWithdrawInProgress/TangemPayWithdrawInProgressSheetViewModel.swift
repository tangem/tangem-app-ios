//
//  TangemPayWithdrawInProgressSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

protocol TangemPayWithdrawInProgressSheetRoutable {
    func closeWithdrawInProgressSheet()
}

struct TangemPayWithdrawInProgressSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let coordinator: TangemPayWithdrawInProgressSheetRoutable

    func close() {
        coordinator.closeWithdrawInProgressSheet()
    }
}

@MainActor
final class TangemPayWithdrawInProgressPopupViewModel: TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Clock.regular32.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    var title: AttributedString {
        .init(Localization.tangempayCardDetailsWithdrawInProgressTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayCardDetailsWithdrawInProgressDescription)
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
