//
//  SwappingFeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SwappingFeeRowViewModel: Identifiable, Hashable {
    var id: Int { hashValue }

    var isLoading: Bool {
        state.isLoading
    }

    var formattedFee: String {
        state.formattedFee
    }

    private var state: State

    init(state: State) {
        self.state = state
    }

    mutating func update(state: State) {
        self.state = state
    }
}

extension SwappingFeeRowViewModel {
    enum State: Hashable {
        case idle
        case loading
        case fee(fee: String, symbol: String, fiat: String)

        var isLoading: Bool {
            if case .loading = self {
                return true
            }

            return false
        }

        var formattedFee: String {
            switch self {
            case .idle, .loading:
                return ""
            case let .fee(fee, symbol, fiat):
                return "\(fee) \(symbol) (\(fiat))"
            }
        }
    }
}
