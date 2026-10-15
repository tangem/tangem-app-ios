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
import TangemUI

protocol SendSourceToken: SendReceiveToken {
    var userWalletInfo: UserWalletInfo { get }

    var id: WalletModelId { get }
    var header: TokenHeader { get }
    var feeTokenItem: TokenItem { get }
    var isCustom: Bool { get }
    var defaultAddressString: String { get }

    var availableBalanceProvider: TokenBalanceProvider { get }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }
    var allowanceService: (any AllowanceService)? { get }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { get }
    var scaledUIAmountMultiplierResolver: ScaledUIAmountMultiplierResolver? { get }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { get }
    var transactionHistoryEnricher: TransactionHistoryExpressDataEnriching? { get async }

    // Common providers
    var transactionDispatcherProvider: any TransactionDispatcherProvider { get }
    var transactionSummaryDescriptionBuilderProvider: any TransactionSummaryDescriptionBuilderProvider { get }
    var blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper { get }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { get }

    /// Whether the source token belongs to a Tangem Pay (Visa Payment) account.
    var isTangemPayAccount: Bool { get }
    var jointAccountPolicy: JointAccountPolicy? { get }
}

extension SendSourceToken {
    var walletTokenItem: WalletTokenItem { WalletTokenItem(userWalletId: userWalletInfo.id, tokenItem: tokenItem) }
    var possibleToConvertToFiat: Bool { fiatAvailableBalanceProvider.balanceType.value != .none }
    var signingActionButtonType: SigningActionButtonViewType { SigningActionButtonViewTypeBuilder().build(userWalletInfo: userWalletInfo) }
}
