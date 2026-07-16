//
//  TangemPayCardDetailsState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemPayCardDetailsState: Equatable {
    case hidden(isFrozen: Bool)
    case loading(isFrozen: Bool)
    case loaded(LoadedState)
    case issuing

    var isLoaded: Bool {
        switch self {
        case .loaded(.revealed):
            true
        case .hidden, .loading, .loaded(.unrevealed), .issuing:
            false
        }
    }

    var isFrozen: Bool {
        switch self {
        case .loaded, .issuing:
            false
        case .hidden(let isFrozen), .loading(let isFrozen):
            isFrozen
        }
    }

    var isIssuing: Bool {
        if case .issuing = self { return true }
        return false
    }

    var showDetailsButtonVisible: Bool {
        switch self {
        case .hidden(isFrozen: false), .loaded(.unrevealed):
            true
        default:
            false
        }
    }

    var details: TangemPayCardDetailsData? {
        switch self {
        case .loaded(.revealed(let data)), .loaded(.unrevealed(let data, _)):
            return data
        case .loading, .hidden, .issuing:
            return nil
        }
    }

    var isFlipped: Bool {
        switch self {
        case .loaded:
            true
        default:
            false
        }
    }
}

extension TangemPayCardDetailsState {
    enum LoadedState: Equatable {
        case unrevealed(details: TangemPayCardDetailsData, isLoading: Bool)
        case revealed(TangemPayCardDetailsData)

        var isRevealed: Bool {
            switch self {
            case .revealed:
                true
            case .unrevealed:
                false
            }
        }
    }
}
