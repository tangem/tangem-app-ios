//
//  PolymarketAddFundsSheetRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketAddFundsSheetRoutable: AnyObject {
    func openChooseNetworkSheet(networks: [PolymarketDepositNetwork])

    func openSwapFlow(parameters: PredefinedSwapParameters)

    func closeAddFundsSheet()
}
