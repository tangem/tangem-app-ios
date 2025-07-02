//
//  TransactionSimulationState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Represents the state of a transaction simulation
enum TransactionSimulationState: Equatable {
    case notStarted
    case loading
    case simulationFailed(error: String)
    case simulationSucceeded(result: BlockaidChainScanResult)

    static func == (lhs: TransactionSimulationState, rhs: TransactionSimulationState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            true
        case (.loading, .loading):
            true
        case (.simulationFailed(let lhsError), .simulationFailed(let rhsError)):
            lhsError == rhsError
        case (.simulationSucceeded(let lhsResult), .simulationSucceeded(let rhsResult)):
            lhsResult == rhsResult
        default:
            false
        }
    }
}
