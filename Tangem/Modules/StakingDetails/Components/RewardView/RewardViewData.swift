//
//  RewardViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RewardViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let state: State
}

extension RewardViewData {
    enum State: Hashable {
        case noRewards
        case rewards(fiatFormatted: String, cryptoFormatted: String)
    }
}
