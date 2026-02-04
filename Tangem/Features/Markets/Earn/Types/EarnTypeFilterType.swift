//
//  EarnTypeFilterType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum EarnTypeFilterType: String, CaseIterable, Identifiable {
    case all

    var id: String {
        rawValue
    }

    var description: String {
        switch self {
        case .all: return Localization.earnFilterAllTypes
        }
    }
}

// MARK: - EarnFilterOption

enum EarnFilterOption: Hashable {
    case network(EarnNetworkFilterType)
    case type(EarnTypeFilterType)

    var title: String {
        switch self {
        case .network(let value): return value.description
        case .type(let value): return value.description
        }
    }
}
