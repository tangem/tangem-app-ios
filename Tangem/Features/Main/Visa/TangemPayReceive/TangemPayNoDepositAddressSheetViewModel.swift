//
//  TangemPayNoDepositAddressSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

// [REDACTED_TODO_COMMENT]
struct TangemPayNoDepositAddressSheetViewModel {
    let title = "Service temporarily unavailable"
    let subtitle = "We’re fixing a technical issue. Please try again later."
    let buttonTitle = "Got it"

    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(
            title: buttonTitle,
            subtitle: nil,
            icon: nil,
            style: .secondary,
            size: .default,
            isLoading: false,
            isDisabled: false,
            action: close
        )
    }

    let close: () -> Void
}

extension TangemPayNoDepositAddressSheetViewModel: FloatingSheetContentViewModel {
    var id: String {
        String(describing: Self.self)
    }
}
