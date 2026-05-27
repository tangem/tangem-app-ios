//
//  TangemPayMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol TangemPayMainRoutable: AnyObject {
    func openCardManagement()
    func openFakedoorSheet()
    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel)

    func openTangemPayAddFundsSheet(input: TangemPayAddFundsSheetViewModel.Input)
    func openTangemPayWithdraw(input: PredefinedSwapParameters)
    func openTangemPayNoDepositAddressSheet()
    func openTangemWithdrawInProgressSheet()
    func openTermsAndLimits()

    func openTangemPayTransactionDetailsSheet(
        transaction: TangemPayTransactionRecord,
        userWalletId: UserWalletId,
        customerId: String
    )

    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        userWalletInfo: UserWalletInfo,
        tokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager
    )
}
