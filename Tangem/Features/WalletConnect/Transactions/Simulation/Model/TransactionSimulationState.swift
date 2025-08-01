//
//  TransactionSimulationState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum TransactionSimulationState: Equatable {
    case notStarted
    case loading
    case simulationNotSupported(method: String)
    case simulationFailed(error: String)
    case simulationSucceeded(result: BlockaidChainScanResult)
}
