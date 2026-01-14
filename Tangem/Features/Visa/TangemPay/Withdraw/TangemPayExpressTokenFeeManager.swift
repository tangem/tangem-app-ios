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

    func feeTokenProviders(providerId: ExpressProvider.Id) -> [any TokenFeeProvider] { [] }

    func updateSelectedFeeTokenProviderInAllManagers(tokenFeeProvider: any TokenFeeProvider) {}
}
