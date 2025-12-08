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
    case failedToIssue
    case active
    case blocked

    case unavailable // 'loadCustomerInfo' failed

    var isActive: Bool {
        switch self {
        case .kycRequired, .readyToIssueOrIssuing, .failedToIssue, .blocked, .unavailable:
            false
        case .active:
            true
        }
    }
}
