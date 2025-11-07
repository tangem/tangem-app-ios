//
//  TangemPayNoDepositAddressSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

protocol TangemPayNoDepositAddressSheetRoutable {
    func closeNoDepositAddressSheet()
}

// [REDACTED_TODO_COMMENT]
struct TangemPayNoDepositAddressSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let title = "Service temporarily unavailable"
    let subtitle = "We’re fixing a technical issue. Please try again later."
    let buttonTitle = "Got it"

    let coordinator: TangemPayNoDepositAddressSheetRoutable

    func close() {
        coordinator.closeNoDepositAddressSheet()
    }

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(title: buttonTitle, style: .secondary, size: .default, action: close)
    }
}
