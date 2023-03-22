//
//  AnalyticsStorageKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum AnalyticsStorageKey: String {
    case balance
    case scanSource

    var isPermanent: Bool {
        switch self {
        case .balance:
            return true
        case .scanSource:
            return false
        }
    }
}
