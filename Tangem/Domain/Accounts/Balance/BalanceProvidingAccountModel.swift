//
//  BalanceProvidingAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol BalanceProvidingAccountModel {
    var fiatTotalBalanceProvider: AccountBalanceProvider { get }
    var rateProvider: AccountRateProvider { get }
}
