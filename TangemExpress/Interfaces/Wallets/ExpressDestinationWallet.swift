//
//  ExpressDestinationWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressDestinationWallet {
    var currency: ExpressWalletCurrency { get }
    var address: String? { get }
}
