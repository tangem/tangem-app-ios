//
//  WCTransactionSimulationFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCTransactionSimulationFactory {
    func makeTransactionSimulationService() -> WCTransactionSimulationService {
        let blockaidFactory = BlockaidFactory()
        let blockaidService = blockaidFactory.makeBlockaidAPIService()
        return CommonWCTransactionSimulationService(blockaidService: blockaidService)
    }
}
