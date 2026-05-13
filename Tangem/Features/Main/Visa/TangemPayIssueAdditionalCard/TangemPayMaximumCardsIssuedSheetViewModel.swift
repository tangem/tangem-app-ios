//
//  TangemPayMaximumCardsIssuedSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI
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
