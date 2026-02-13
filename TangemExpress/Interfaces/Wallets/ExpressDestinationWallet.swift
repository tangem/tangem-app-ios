//
//  ExpressDestinationWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public typealias ExpressGenericWallet = ExpressDestinationWallet

public protocol ExpressDestinationWallet {
    /// Sending / Receiving token currency
    var currency: ExpressWalletCurrency { get }

    /// Need for `txValue` or `otherNativeFee` calculation
    var coinCurrency: ExpressWalletCurrency { get }

    var address: String? { get }
    var extraId: String? { get }
}
