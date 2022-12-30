//
//  SwappingTokenIconViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SwappingTokenIconViewModel: Identifiable, Hashable {
    var id: Int { hashValue }

    private(set) var state: State

    init(state: State = .loading) {
        self.state = state
    }

    mutating func update(state: State) {
        self.state = state
    }
}

extension SwappingTokenIconViewModel {
    enum State: Hashable {
        case loading
        case loaded(imageURL: URL, networkURL: URL? = nil, symbol: String)
    }
}
