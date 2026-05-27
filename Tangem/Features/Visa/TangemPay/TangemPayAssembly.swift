//
//  TangemPayAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemPay

protocol TangemPayAssembly {
    var customerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver { get }

    func makeCardDetailsRepository(for tangemPayAccount: TangemPayAccount) -> TangemPayCardDetailsRepository

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository

    func makeExpressCEXTransactionDispatcher(
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        walletPublicKey: Wallet.PublicKey?
    ) -> TransactionDispatcher
}
