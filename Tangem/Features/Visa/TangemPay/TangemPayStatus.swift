//
//  TangemPayStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemPayStatus {
    case kycRequired
    case readyToIssue
    case didTapIssueCard
    case issuing
    case active

    var isIssuingInProgress: Bool {
        switch self {
        case .didTapIssueCard, .issuing:
            true
        case .kycRequired, .readyToIssue, .active:
            false
        }
    }
}
