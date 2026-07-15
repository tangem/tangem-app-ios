//
//  GaslessTransactionsAPIType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum GaslessTransactionsAPIType: String, CaseIterable {
    case dev
    case stage
    case prod
    case mock

    public var title: String {
        rawValue
    }
}
