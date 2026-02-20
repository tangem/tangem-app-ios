//
//  TangemElasticContainerState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TangemElasticContainerState: Equatable {
    case expanded
    case collapsing(ratio: CGFloat)
    case collapsed
    case expanding(ratio: CGFloat)

    var ratio: CGFloat {
        switch self {
        case .expanded: 1
        case .collapsing(let ratio): 1 - ratio
        case .collapsed: 0
        case .expanding(let ratio): ratio
        }
    }
}
