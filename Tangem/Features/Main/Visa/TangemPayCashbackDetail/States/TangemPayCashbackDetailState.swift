//
//  TangemPayCashbackDetailState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TangemPayCashbackDetailState {
    case idle
    case loading
    case loaded(TangemPayCashbackDetailViewData)
    case failed
}

extension TangemPayCashbackDetailState: Equatable {
    static func == (
        lhs: TangemPayCashbackDetailState,
        rhs: TangemPayCashbackDetailState
    ) -> Bool {
        lhs.id == rhs.id
    }

    var id: String {
        switch self {
        case .idle: "idle"
        case .loading: "loading"
        case .loaded: "loaded"
        case .failed: "failed"
        }
    }
}
