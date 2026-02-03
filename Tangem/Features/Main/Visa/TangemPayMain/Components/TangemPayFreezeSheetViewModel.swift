//
//  TangemPayFreezeSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

protocol TangemPayFreezeSheetRoutable: AnyObject {
    func closeFreezeSheet()
}

final class TangemPayFreezeSheetViewModel: FloatingSheetContentViewModel, TangemPayPopupViewModel {
    var icon: Image {
        Image(systemName: "snowflake")
    }

    var title: AttributedString {
        .init(Localization.tangemPayFreezeCardAlertTitle)
    }

    var description: AttributedString {
        .init(Localization.tangemPayFreezeCardAlertBody)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangemPayFreezeCardFreeze,
            style: .primary,
            size: .default,
            action: freeze
        )
    }

    weak var coordinator: TangemPayFreezeSheetRoutable?
    let freezeAction: () -> Void

    init(
        coordinator: TangemPayFreezeSheetRoutable,
        freezeAction: @escaping () -> Void
    ) {
        self.coordinator = coordinator
        self.freezeAction = freezeAction

        Analytics.log(.visaScreenFreezeCardConfirmShown)
    }

    func dismiss() {
        coordinator?.closeFreezeSheet()
    }

    func freeze() {
        Analytics.log(.visaScreenFreezeCardConfirmClicked)
        freezeAction()
        dismiss()
    }
}
