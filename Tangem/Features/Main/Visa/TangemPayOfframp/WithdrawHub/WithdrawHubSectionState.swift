//
//  WithdrawHubSectionState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum WithdrawHubSectionState<Item> {
    case loading
    case loaded([Item])
}
