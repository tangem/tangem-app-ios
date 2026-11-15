//
//  TangemPayEnrollmentState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum TangemPayEnrollmentState: Equatable, Sendable {
    case kycRequired
    case kycInProgress
    case kycDeclined
    case enrolled
    case cardDeactivated
    case failedToIssueCard
    case planSelectNeeded
    case verified
    case cardNotOpened
    case unavailable
}
