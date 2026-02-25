//
//  ExpressInteractorDestinationWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

protocol ExpressInteractorDestinationWallet: ExpressDestinationWallet {
    var id: WalletModelId { get }
    var userWalletId: UserWalletId { get }
    var tokenItem: TokenItem { get }
    var isCustom: Bool { get }
    var tokenHeader: ExpressInteractorTokenHeader? { get }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { get }
}
