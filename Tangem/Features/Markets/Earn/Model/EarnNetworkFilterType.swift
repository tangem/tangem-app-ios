//
//  EarnNetworkFilterType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum EarnNetworkFilterType: Hashable, Equatable {
    case all
    case userNetworks
    case specific(networkIds: Set<String>)

    var displayTitle: String {
        switch self {
        case .all:
            return "All"
        case .userNetworks:
            return "Networks"
        case .specific(let networkIds):
            return "All networks"
        }
    }

    var apiNetworkIds: [String]? {
        switch self {
        case .all:
            return nil
        case .userNetworks:
            return nil
        case .specific(let networkIds):
            return Array(networkIds)
        }
    }
}
