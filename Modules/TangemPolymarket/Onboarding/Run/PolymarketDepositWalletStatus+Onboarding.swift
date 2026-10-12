//
//  PolymarketDepositWalletStatus+Onboarding.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension PolymarketDepositWalletStatus {
    var owesApprovals: Bool {
        switch self {
        case .readyToTrade, .approvalsInProgress: false
        case .notCreated, .deploymentInProgress, .deploymentFailed, .deployed, .approvalsFailed, .unknown: true
        }
    }

    var needsDeploy: Bool {
        switch self {
        case .notCreated, .deploymentFailed: true
        case .deploymentInProgress, .deployed, .approvalsInProgress, .approvalsFailed, .readyToTrade, .unknown: false
        }
    }

    var isDeployComplete: Bool {
        switch self {
        case .deployed, .approvalsFailed, .approvalsInProgress, .readyToTrade: true
        case .notCreated, .deploymentInProgress, .deploymentFailed, .unknown: false
        }
    }

    var onboardingFailure: PolymarketOnboardingError? {
        switch self {
        case .deploymentFailed: .deploymentFailed
        case .approvalsFailed: .approvalsFailed
        default: nil
        }
    }

    func satisfies(_ target: PolymarketDepositWalletStatus) -> Bool {
        switch target {
        case .deployed: isDeployComplete
        default: self == target
        }
    }
}
