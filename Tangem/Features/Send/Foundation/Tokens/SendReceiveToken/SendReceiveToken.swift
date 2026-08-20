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

    /// When set, the receive side is rendered abstractly (e.g. a payment account with a fixed
    /// currency symbol). `nil` keeps the standard token rendering.
    var presentation: SendReceiveTokenPresentation? { get }
}

extension SendReceiveToken {
    var presentation: SendReceiveTokenPresentation? { nil }
}

/// Overrides how a receive token is presented on the swap screen for account funding flows:
/// a fixed currency symbol, the payment account icon, and a fiat-denominated balance.
struct SendReceiveTokenPresentation {
    /// Currency symbol shown on the receive pill (e.g. "USD" for a Visa Payment account).
    let currencySymbol: String
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
