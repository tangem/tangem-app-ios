//
//  SwappingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol SwappingRoutable: AnyObject {
    func presentSuccessView(fromCurrency: String, toCurrency: String)
    func presentExchangeableTokenListView(inputModel: SwappingPermissionViewModel.InputModel)
}
