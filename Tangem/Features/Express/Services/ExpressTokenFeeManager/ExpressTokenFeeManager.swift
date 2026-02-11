//
//  ExpressTokenFeeProvidersManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import Combine
import TangemFoundation

protocol ExpressTokenFeeProvidersManager {
    func tokenFeeProvidersManager(providerId: ExpressProvider.Id) -> TokenFeeProvidersManager

    func updateSelectedFeeOptionInAllManagers(feeOption: FeeOption)
    func updateSelectedFeeTokenItemInAllManagers(feeTokenItem: TokenItem)
}
