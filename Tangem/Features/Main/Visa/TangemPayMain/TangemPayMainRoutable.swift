//
//  TangemPayMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

protocol TangemPayMainRoutable: AnyObject {
    func openCardManagement()
    func openCardManagement(entry: TangemPayCardEntry)
    func openCurrentPlan()
    func openFakedoorSheet()
    func openMaximumCardsIssuedSheet()
    func openIssueAdditionalCardCostPopup(offer: TangemPayCustomerOffer, fee: TangemPayCustomerOffer.Fee, issueCard: @escaping () async throws -> Void)
    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel)

    func openTangemPayAddFundsSheet(input: TangemPayAddFundsSheetViewModel.Input)
    func openTangemPayWithdraw(input: PredefinedSwapParameters)
    func openTangemPayNoDepositAddressSheet()
    func openTangemWithdrawInProgressSheet()
    func openTermsAndLimits()
    func renewTangemPaySession()

    func openTangemPayTransactionDetailsSheet(
        transaction: TangemPayTransactionRecord,
        userWalletId: UserWalletId,
        customerId: String,
        cardName: String?,
        cardNumberEnd: String?
    )

    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        userWalletInfo: UserWalletInfo,
        tokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager
    )
}
