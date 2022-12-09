//
//  SwappingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

protocol SwappingRoutable: AnyObject {
    func presentSwappingTokenList(sourceCurrency: Currency, userCurrencies: [Currency])
    func presentSuccessView(fromCurrency: String, toCurrency: String)
    func presentPermissionView(inputModel: SwappingPermissionViewModel.InputModel)
}
