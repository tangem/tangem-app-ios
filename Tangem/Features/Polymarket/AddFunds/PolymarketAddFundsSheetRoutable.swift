//
//  PolymarketAddFundsSheetRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketAddFundsSheetRoutable: AnyObject {
    func openReceiveSheet(viewModel: ReceiveMainViewModel)

    func openSwapFlow(parameters: PredefinedSwapParameters)

    func closeAddFundsSheet()
}
