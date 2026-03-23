//
//  CommonSendTransferableToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct CommonSendTransferableToken: SendTransferableToken {
    let transactionValidator: any BlockchainSdk.TransactionValidator
    let transactionCreator: any BlockchainSdk.TransactionCreator
    let tokenFeeProvidersManager: any TokenFeeProvidersManager

    let sourceToken: SendSourceToken

    let tokenItem: TokenItem
    let fiatItem: FiatItem

    let currency: TangemExpress.ExpressWalletCurrency
    let coinCurrency: TangemExpress.ExpressWalletCurrency
    let address: String?
    let extraId: String?

    // MARK: - SendSourceToken proxy properties

    var userWalletInfo: UserWalletInfo { sourceToken.userWalletInfo }
    var id: WalletModelId { sourceToken.id }
    var header: TokenHeader { sourceToken.header }
    var feeTokenItem: TokenItem { sourceToken.feeTokenItem }
    var isFixedFee: Bool { sourceToken.isFixedFee }
    var isCustom: Bool { sourceToken.isCustom }
    var defaultAddressString: String { sourceToken.defaultAddressString }

    var availableBalanceProvider: any TokenBalanceProvider { sourceToken.availableBalanceProvider }
    var fiatAvailableBalanceProvider: any TokenBalanceProvider { sourceToken.fiatAvailableBalanceProvider }
    var allowanceService: (any AllowanceService)? { sourceToken.allowanceService }
    var withdrawalNotificationProvider: (any BlockchainSdk.WithdrawalNotificationProvider)? { sourceToken.withdrawalNotificationProvider }
    var emailDataCollectorBuilder: any EmailDataCollectorBuilder { sourceToken.emailDataCollectorBuilder }

    var transactionDispatcherProvider: any TransactionDispatcherProvider { sourceToken.transactionDispatcherProvider }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { sourceToken.accountModelAnalyticsProvider }
}
