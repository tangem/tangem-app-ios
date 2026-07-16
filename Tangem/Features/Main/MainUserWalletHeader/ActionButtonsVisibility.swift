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

    let forcesRow: Bool

    var isAddFundsVisible: Bool { isExchangeVisible || forcesRow }
    var isTransferVisible: Bool { isExchangeVisible || forcesRow }

    var hasVisibleButtons: Bool {
        isAddFundsVisible || isSwappingVisible || isTransferVisible
    }

    init(config: UserWalletConfig) {
        isExchangeVisible = config.isFeatureVisible(.exchange)
        isSwappingVisible = config.isFeatureVisible(.swapping)
        forcesRow = config.makeActionButtonsRole().forcesActionButtonsRow
    }
}
