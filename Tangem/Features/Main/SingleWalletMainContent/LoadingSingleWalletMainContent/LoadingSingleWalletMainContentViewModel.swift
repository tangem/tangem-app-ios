//
//  LoadingSingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct LoadingSingleWalletMainContentViewModel {
    let buttonsInfo: [FixedSizeButtonWithIconInfo] = TokenActionAvailabilityProvider
        .buildActionsForLockedSingleWallet()
        .map {
            FixedSizeButtonWithIconInfo(
                title: $0.title,
                icon: $0.icon,
                disabled: true,
                style: .disabled,
                action: {}
            )
        }
}
