//
//  SendReceiveToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol SendGenericToken {}

protocol SendReceiveToken: SendGenericToken, ExpressDestinationWallet {
    var tokenItem: TokenItem { get }
    var isCustom: Bool { get }
    var fiatItem: FiatItem { get }
}

// MARK: ExpressDestinationWallet + SendReceiveToken

extension ExpressDestinationWallet where Self: SendReceiveToken {
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var coinCurrency: ExpressWalletCurrency { tokenItem.expressCoinCurrency }
}
