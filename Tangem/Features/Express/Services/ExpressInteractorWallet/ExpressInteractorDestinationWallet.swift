//
//  ExpressInteractorDestinationWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ExpressInteractorDestinationWallet: ExpressDestinationWallet {
    var id: WalletModelId { get }
    var tokenItem: TokenItem { get }
    var isCustom: Bool { get }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { get }
}
