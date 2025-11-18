//
//  TangemPayStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemPayStatus {
    case kycRequired
    case readyToIssueOrIssuing
    case active

    var isActive: Bool {
        switch self {
        case .kycRequired, .readyToIssueOrIssuing:
            false
        case .active:
            true
        }
    }
}
