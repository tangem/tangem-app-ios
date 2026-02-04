//
//  TangemPayMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TangemPayMainRoutable: AnyObject {
    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel)

    func openTangemPayAddFundsSheet(input: TangemPayAddFundsSheetViewModel.Input)
    func openTangemPayWithdraw(input: ExpressDependenciesInput)
    func openTangemPayNoDepositAddressSheet()
    func openTangemWithdrawInProgressSheet()
    func openTangemPayFreezeSheet(freezeAction: @escaping () -> Void)
    func openTangemPaySetPin(tangemPayAccount: TangemPayAccount)
    func openTangemPayCheckPin(tangemPayAccount: TangemPayAccount)
    func openTermsAndLimits()

    func openTangemPayTransactionDetailsSheet(
        transaction: TangemPayTransactionRecord,
        userWalletId: String,
        customerId: String
    )

    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        userWalletInfo: UserWalletInfo,
        tokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager
    )
}
