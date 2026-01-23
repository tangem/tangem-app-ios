//
//  TangemPayFreezeSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import TangemLocalization

protocol TangemPayFreezeSheetRoutable: AnyObject {
    func closeFreezeSheet()
}

struct TangemPayFreezeSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = Localization.tangemPayFreezeCardAlertTitle
    let subtitle = Localization.tangemPayFreezeCardAlertBody

    weak var coordinator: TangemPayFreezeSheetRoutable?
    let freezeAction: () -> Void

    func close() {
        coordinator?.closeFreezeSheet()
    }

    func freeze() {
        Analytics.log(.visaScreenFreezeCardConfirmClicked)
        freezeAction()
        close()
    }

    func onAppear() {
        Analytics.log(.visaScreenFreezeCardConfirmShown)
    }

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangemPayFreezeCardFreeze,
            style: .primary,
            size: .default,
            action: freeze
        )
    }
}
