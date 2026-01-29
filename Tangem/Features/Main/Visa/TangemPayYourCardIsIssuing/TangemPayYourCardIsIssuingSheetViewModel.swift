//
//  TangemPayYourCardIsIssuingSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

final class TangemPayYourCardIsIssuingSheetViewModel: TangemPayPopupViewModel {
    var icon: Image {
        Assets.warningIcon.image
    }

    var title: AttributedString {
        .init(Localization.tangempayIssuingYourCard)
    }

    var description: AttributedString {
        .init(Localization.tangempayIssuingYourCardDescription)
    }

    var primaryButton: MainButton.Settings {
        .init(
            title: Localization.commonGotIt,
            style: .secondary,
            size: .default,
            action: dismiss
        )
    }

    weak var coordinator: TangemPayYourCardIsIssuingRoutable?

    init(coordinator: TangemPayYourCardIsIssuingRoutable?) {
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeYourCardIsIssuingSheet()
    }
}
