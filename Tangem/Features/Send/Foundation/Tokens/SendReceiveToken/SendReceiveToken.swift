//
//  SendReceiveToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets
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
    var isCustomSlippageAllowed: Bool { get }
}

extension SendReceiveToken {
    var presentation: SendReceiveTokenPresentation? { nil }
}

struct SendReceiveTokenPresentation {
    let currencySymbol: String
    let icon: ImageType
    let balanceDenomination: BalanceDenomination
    let appliesToSendSide: Bool

    init(
        currencySymbol: String,
        icon: ImageType,
        balanceDenomination: BalanceDenomination = .fiat,
        appliesToSendSide: Bool = false
    ) {
        self.currencySymbol = currencySymbol
        self.icon = icon
        self.balanceDenomination = balanceDenomination
        self.appliesToSendSide = appliesToSendSide
    }

    enum BalanceDenomination {
        case fiat
        case token
    }
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
