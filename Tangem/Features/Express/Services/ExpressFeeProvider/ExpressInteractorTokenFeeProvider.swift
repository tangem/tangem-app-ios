//
//  ExpressInteractorTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ExpressInteractorTokenFeeProvider {
    func tokenFeeManager(providerId: ExpressProvider.Id) -> TokenFeeManager?
    func selectedFeeProvider(providerId: ExpressProvider.Id) -> TokenFeeProvider?
    func feeTokenItems(providerId: ExpressProvider.Id) -> [TokenItem]
    func fees(providerId: ExpressProvider.Id) -> [TokenFee]
}
