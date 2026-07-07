//
//  TangemPayVirtualAccountPreparingPopupViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

@MainActor
final class TangemPayVirtualAccountPreparingPopupViewModel: TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Clock.regular32.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .info
    }

    var title: AttributedString {
        .init(Localization.tangempayBankTransferSuccessTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayBankTransferSuccessSubtitle)
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
