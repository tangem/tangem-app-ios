//
//  AnalyticsStorageKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum AnalyticsStorageKey: String {
    case hasPositiveBalance
    case limitedEvents

    var isPermanent: Bool {
        switch self {
        case .hasPositiveBalance:
            return true
        case .limitedEvents:
            return false
        }
    }
}
