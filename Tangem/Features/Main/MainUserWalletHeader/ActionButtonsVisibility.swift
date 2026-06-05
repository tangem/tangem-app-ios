//
//  ActionButtonsVisibility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct ActionButtonsVisibility {
    let isExchangeVisible: Bool
    let isSwappingVisible: Bool

    var hasVisibleButtons: Bool {
        isExchangeVisible || isSwappingVisible
    }

    init(config: UserWalletConfig) {
        isExchangeVisible = config.isFeatureVisible(.exchange)
        isSwappingVisible = config.isFeatureVisible(.swapping)
    }
}
