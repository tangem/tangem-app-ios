//
//  TangemPayNoDepositAddressSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

protocol TangemPayNoDepositAddressSheetRoutable {
    func closeNoDepositAddressSheet()
}

struct TangemPayNoDepositAddressSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = Localization.tangempayServiceUnavailableTitle
    let subtitle = Localization.tangempayCardDetailsReceiveErrorDescription

    let coordinator: TangemPayNoDepositAddressSheetRoutable

    func close() {
        coordinator.closeNoDepositAddressSheet()
    }

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonGotIt,
            style: .secondary,
            size: .default,
            action: close
        )
    }
}

@MainActor
final class TangemPayNoDepositAddressPopupViewModel: TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.Clock.regular32.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    var title: AttributedString {
        .init(Localization.tangempayServiceUnavailableTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayCardDetailsReceiveErrorDescription)
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
