//
//  TangemPayYourCardIsIssuingSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

struct TangemPayYourCardIsIssuingSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = Localization.tangempayIssuingYourCard
    let subtitle = Localization.tangempayIssuingYourCardDescription

    weak var coordinator: TangemPayYourCardIsIssuingRoutable?

    func close() {
        coordinator?.closeYourCardIsIssuingSheet()
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
