//
//  ForceUpdateViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemLocalization

final class ForceUpdateViewModel: ObservableObject {
    let title = Localization.forceUpdateWarningTitle
    let subtitle = Localization.forceUpdateWarningMessage

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(
            title: Localization.forceUpdateButton,
            style: .primary,
            size: .default,
            action: openAppStore
        )
    }

    weak var coordinator: ForceUpdateRoutable?

    init(coordinator: ForceUpdateRoutable?) {
        self.coordinator = coordinator
    }

    deinit {
        AppLogger.debug("ForceUpdateViewModel deinit")
    }

    func openAppStore() {
        coordinator?.openAppStore()
    }
}
