//
//  EarnNetworkFilterType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum EarnNetworkFilterType: String, CaseIterable, Identifiable {
    case all

    var id: String {
        rawValue
    }

    var description: String {
        switch self {
        case .all: return Localization.earnFilterAllNetworks
        }
    }
}
