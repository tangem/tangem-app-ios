//
//  TangemPayFreezeSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

protocol TangemPayFreezeSheetRoutable: AnyObject {
    func closeFreezeSheet()
}

struct TangemPayFreezeSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = "Freeze your card?"
    let subtitle = "Keep your money safe if your card is lost or stolen. You can unfreeze anytime."
    let buttonTitle = "Freeze"

    weak var coordinator: TangemPayFreezeSheetRoutable?
    let freezeAction: () -> Void

    func close() {
        coordinator?.closeFreezeSheet()
    }

    func freeze() {
        freezeAction()
        close()
    }

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(title: buttonTitle, style: .primary, size: .default, action: freeze)
    }
}
