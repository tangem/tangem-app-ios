//
//  CollectiblesAddFundsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol CollectiblesAddFundsRoutable: AnyObject {
    func openSwap(parameters: PredefinedSwapParameters)
    func openReceive(address: String, tokenItem: TokenItem)
    func closeAddFunds()
}
