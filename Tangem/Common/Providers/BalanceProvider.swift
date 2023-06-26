//
//  BalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol BalanceProvider: AnyObject {
    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> { get }
}

struct BalanceInfo {
    let balance: Decimal
    let currencyCode: String
}
