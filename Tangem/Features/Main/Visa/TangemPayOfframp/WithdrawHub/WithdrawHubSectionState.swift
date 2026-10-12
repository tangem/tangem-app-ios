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
    case failed
}

// MARK: - Content identity

extension WithdrawHubSectionState where Item: Identifiable {
    var contentID: ContentID {
        switch self {
        case .loading:
            .loading
        case .loaded(let items):
            .loaded(items.map(\.id))
        case .failed:
            .failed
        }
    }

    enum ContentID: Hashable {
        case loading
        case loaded([Item.ID])
        case failed
    }
}
