//
//  ExpressTokenFeeManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import Combine
import TangemFoundation

protocol ExpressTokenFeeManager {
    func tokenFeeManager(providerId: ExpressProvider.Id) -> TokenFeeManager?
    func selectedFeeProvider(providerId: ExpressProvider.Id) -> (any TokenFeeProvider)?
    func fees(providerId: ExpressProvider.Id) -> TokenFeesList
    func feeTokenItems(providerId: ExpressProvider.Id) -> [TokenItem]

    func updateSelectedFeeTokenItem(tokenItem: TokenItem)
}
