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
    func updateSelectedFeeTokenProviderInAllManagers(tokenFeeProvider: any TokenFeeProvider)
}
