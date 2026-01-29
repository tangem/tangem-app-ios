//
//  EarnNetworkInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnNetworkInfo: Identifiable, Hashable {
    let networkId: String

    var id: String {
        networkId
    }
}
