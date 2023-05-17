//
//  SwappingFeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SwappingFeeRowViewModel: Identifiable, Hashable {
    var id: Int { hashValue }
    var state: State
    let isDisclaimerOpened: BindingValue<Bool>

    init(state: State, isDisclaimerOpened: BindingValue<Bool>) {
        self.state = state
        self.isDisclaimerOpened = isDisclaimerOpened
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

        var formattedFee: String? {
            switch self {
            case .idle, .loading:
                return nil
            case .fee(let fee, let symbol, let fiat):
                return "\(fee) \(symbol) (\(fiat))"
            }
        }
    }
}
