//
//  EarnNetworkFilterType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum EarnNetworkFilterType: Hashable, Identifiable {
    case all
    case my
    case network(networkId: String)

    var id: String {
        switch self {
        case .all: return "all"
        case .my: return "my"
        case .network(let networkId): return networkId
        }
    }

    var description: String {
        switch self {
        case .all: return Localization.earnFilterAllNetworks
        case .my: return "My networks"
        case .network: return "" // Section 2 rows use blockchain displayName
        }
    }

    /// Preset options for the first section (All networks, My networks).
    static var presetCases: [EarnNetworkFilterType] {
        [.all, .my]
    }
}
