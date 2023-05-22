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
    private(set) var state: State
    let isShowingDisclaimer: BindingValue<Bool>

    init(state: State, isShowingDisclaimer: BindingValue<Bool>) {
        self.state = state
        self.isShowingDisclaimer = isShowingDisclaimer
    }

    mutating func update(state: State) {
        self.state = state
    }
}

extension SwappingFeeRowViewModel {
    enum State: Hashable {
        case idle
        case loading
        case fee(fee: String)
        case policy(title: String, fiat: String)

        var isLoading: Bool {
            if case .loading = self {
                return true
            }

            return false
        }
    }
}
