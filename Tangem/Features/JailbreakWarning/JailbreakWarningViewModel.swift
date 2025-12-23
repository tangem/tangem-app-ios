//
//  JailbreakWarningViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemLocalization

class JailbreakWarningViewModel: ObservableObject {
    let title = Localization.jailbreakWarningTitle
    let subtitle = Localization.jailbreakWarningMessage

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonUnderstandContinue,
            style: .primary,
            size: .default,
            action: close
        )
    }

    weak var coordinator: JailbreakWarningRoutable?

    private let jailbreakWarningUtil = JailbreakWarningUtil()

    init(coordinator: JailbreakWarningRoutable?) {
        self.coordinator = coordinator
    }

    deinit {
        AppLogger.debug("JailbreakWarningViewModel deinit")
    }

    func close() {
        jailbreakWarningUtil.setWarningShown()
        coordinator?.closeJailbreakWarning()
    }
}
