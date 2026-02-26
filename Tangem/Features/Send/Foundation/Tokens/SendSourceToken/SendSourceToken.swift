//
//  SendSourceToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemFoundation

protocol SendSourceToken: SendReceiveToken {
    var userWalletInfo: UserWalletInfo { get }

    var id: WalletModelId { get }
    var header: TokenHeader { get }
    var feeTokenItem: TokenItem { get }
    var isFixedFee: Bool { get }
    var isCustom: Bool { get }
    var defaultAddressString: String { get }

    var availableBalanceProvider: TokenBalanceProvider { get }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }
    var allowanceService: (any AllowanceService)? { get }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { get }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { get }

    // Common providers
    var transactionDispatcherProvider: any TransactionDispatcherProvider { get }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { get }
}

extension SendSourceToken {
    var possibleToConvertToFiat: Bool { fiatAvailableBalanceProvider.balanceType.value != .none }
}
