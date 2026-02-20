//
//  SendReceiveToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import struct TangemUI.TokenIconInfo

protocol SendGenericToken {}

protocol SendReceiveToken: SendGenericToken, ExpressDestinationWallet {
    var tokenItem: TokenItem { get }
    var tokenIconInfo: TokenIconInfo { get }
    var fiatItem: FiatItem { get }
}

struct CommonSendReceiveToken: SendReceiveToken {
    let tokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let fiatItem: FiatItem
    let address: String?
    let extraId: String?

    // ExpressDestinationWallet

    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var coinCurrency: ExpressWalletCurrency { tokenItem.expressCoinCurrency }
}
