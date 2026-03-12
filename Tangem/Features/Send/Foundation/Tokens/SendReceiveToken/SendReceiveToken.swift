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
    var destination: SendReceiveTokenDestination? { get }
}

struct SendReceiveTokenDestination {
    let destination: SendDestination.Destination
    let destinationTag: String?
}

// MARK: ExpressDestinationWallet + SendReceiveToken

extension ExpressDestinationWallet where Self: SendReceiveToken {
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var coinCurrency: ExpressWalletCurrency { tokenItem.expressCoinCurrency }

    var address: String? { destination?.destination.transactionAddress }
    var extraId: String? { destination?.destinationTag }
}

// MARK: SendReceiveToken + SendSourceToken

extension SendReceiveToken where Self: SendSourceToken {
    var destination: SendReceiveTokenDestination? {
        SendReceiveTokenDestination(destination: .plain(defaultAddressString), destinationTag: nil)
    }
}
