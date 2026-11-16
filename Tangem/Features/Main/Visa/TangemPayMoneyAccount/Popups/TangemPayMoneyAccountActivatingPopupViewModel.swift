//
//  TangemPayMoneyAccountActivatingPopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

final class TangemPayMoneyAccountActivatingPopupViewModel: TangemPayPopupViewModel {
    private weak var coordinator: TangemPayMoneyAccountPopupRoutable?

    var title: AttributedString {
        .init(Localization.moneyAccountMainStatusDialogActivatingTitle)
    }

    var description: AttributedString {
        .init(Localization.moneyAccountMainStatusDialogActivatingDescription)
    }

    var icon: Image {
        DesignSystem.Icons.Clock.regular28.image
    }

    var primaryButton: MainButton.Settings {
        .init(title: Localization.commonGotIt, style: .primary, action: dismiss)
    }

    init(coordinator: TangemPayMoneyAccountPopupRoutable) {
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeTangemPayMoneyAccountPopup()
    }
}
