//
//  PolymarketDepositWalletStatus.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketDepositWalletStatus: String, Hashable, Sendable {
    case notCreated = "NOT_CREATED"
    case deploymentInProgress = "DEPLOYMENT_IN_PROGRESS"
    case deploymentFailed = "DEPLOYMENT_FAILED"
    case deployed = "DEPLOYED"
    case approvalsInProgress = "APPROVALS_IN_PROGRESS"
    case approvalsFailed = "APPROVALS_FAILED"
    case readyToTrade = "READY_TO_TRADE"

    case unknown
}

// MARK: - Decodable protocol conformance

extension PolymarketDepositWalletStatus: Decodable {
    public init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = PolymarketDepositWalletStatus(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Convenience extensions

public extension PolymarketDepositWalletStatus {
    var isInProgress: Bool {
        switch self {
        case .deploymentInProgress, .approvalsInProgress, .unknown:
            true
        case .notCreated, .deploymentFailed, .deployed, .approvalsFailed, .readyToTrade:
            false
        }
    }

    var isFailed: Bool {
        switch self {
        case .deploymentFailed, .approvalsFailed:
            true
        case .notCreated, .deploymentInProgress, .deployed, .approvalsInProgress, .readyToTrade, .unknown:
            false
        }
    }
}

public extension PolymarketDepositWalletStatus {
    var isKnownAccount: Bool {
        switch self {
        case .notCreated: false
        case .deploymentInProgress, .deploymentFailed, .deployed, .approvalsInProgress, .approvalsFailed, .readyToTrade, .unknown: true
        }
    }
}
