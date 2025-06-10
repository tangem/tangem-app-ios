//
//  OnrampAmountInputOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

protocol OnrampAmountInput: AnyObject {
    var fiatCurrency: OnrampFiatCurrency? { get }
    var fiatCurrencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> { get }

    var amountPublisher: AnyPublisher<Decimal?, Never> { get }
}

protocol OnrampAmountOutput: AnyObject {
    func amountDidChanged(fiat: Decimal?)
}
