//
//  TangemPayCardDetailsState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemPayCardDetailsState {
    case hidden
    case loading
    case loaded(TangemPayCardDetailsData)

    var isHidden: Bool {
        switch self {
        case .hidden:
            true
        case .loading, .loaded:
            false
        }
    }

    var isLoading: Bool {
        switch self {
        case .loading:
            true
        case .hidden, .loaded:
            false
        }
    }

    var isLoaded: Bool {
        switch self {
        case .loaded:
            true
        case .hidden, .loading:
            false
        }
    }
}
