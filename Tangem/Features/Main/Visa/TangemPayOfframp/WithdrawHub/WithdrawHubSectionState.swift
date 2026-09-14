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

// MARK: - Content identity

extension WithdrawHubSectionState where Item: Identifiable {
    var contentID: [Item.ID]? {
        switch self {
        case .loading:
            nil
        case .loaded(let items):
            items.map(\.id)
        }
    }
}
