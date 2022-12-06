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
    func presentExchangeableTokenListView(sourceCurrency: Currency, userCurrencies: [Currency])
    func presentSuccessView(fromCurrency: String, toCurrency: String)
    func presentPermissionView(inputModel: SwappingPermissionViewModel.InputModel)
}
