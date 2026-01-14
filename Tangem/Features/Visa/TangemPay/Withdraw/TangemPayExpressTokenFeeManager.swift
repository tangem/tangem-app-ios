//
//  TangemPayExpressTokenFeeManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct TangemPayExpressTokenFeeManager: ExpressTokenFeeManager {
    func tokenFeeManager(providerId: ExpressProvider.Id) -> TokenFeeManager? { nil }

    func selectedFeeProvider(providerId: ExpressProvider.Id) -> (any TokenFeeProvider)? { nil }

    func fees(providerId: ExpressProvider.Id) -> TokenFeesList { [] }

    func feeTokenItems(providerId: ExpressProvider.Id) -> [TokenItem] { [] }

    func updateSelectedFeeTokenItemInAllManagers(tokenItem: TokenItem) {}
}
