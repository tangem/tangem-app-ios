//
//  PolymarketWalletStatus.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketWalletStatus: String, Hashable, Sendable {
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

extension PolymarketWalletStatus: Decodable {
    public init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = PolymarketWalletStatus(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Convenience extensions

public extension PolymarketWalletStatus {
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
