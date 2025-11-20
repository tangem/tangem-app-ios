//
//  TangemPayCardDetailsState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemPayCardDetailsState {
    case hidden(isFrozen: Bool)
    case loading(isFrozen: Bool)
    case loaded(TangemPayCardDetailsData)

    var isLoaded: Bool {
        switch self {
        case .loaded:
            true
        case .hidden, .loading:
            false
        }
    }

    var isFrozen: Bool {
        switch self {
        case .loaded:
            false
        case .hidden(let isFrozen), .loading(let isFrozen):
            isFrozen
        }
    }

    var showDetailsButtonVisible: Bool {
        switch self {
        case .hidden(isFrozen: false):
            true
        default:
            false
        }
    }
}
