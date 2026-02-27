//
//  CommonSendSourceToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct CommonSendSourceToken: SendSourceToken {
    let userWalletInfo: UserWalletInfo
    let id: WalletModelId
    let header: TokenHeader
    let feeTokenItem: TokenItem
    let isFixedFee: Bool
    let isCustom: Bool
    let defaultAddressString: String

    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let allowanceService: (any AllowanceService)?
    let withdrawalNotificationProvider: (any BlockchainSdk.WithdrawalNotificationProvider)?
    let emailDataCollectorBuilder: any EmailDataCollectorBuilder

    let transactionDispatcherProvider: any TransactionDispatcherProvider
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?

    // MARK: - SendReceiveToken

    let tokenItem: TokenItem
    let fiatItem: FiatItem

    // MARK: - ExpressDestinationWallet

    let address: String?
    let extraId: String?
}
