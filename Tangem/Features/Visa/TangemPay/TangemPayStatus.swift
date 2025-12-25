//
//  TangemPayStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemPayStatus {
    case unavailable
    case active
    case blocked

    var isActive: Bool {
        switch self {
        case .active:
            true
        case .unavailable, .blocked:
            false
        }
    }
}
