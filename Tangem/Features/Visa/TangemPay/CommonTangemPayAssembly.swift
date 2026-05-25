//
//  CommonTangemPayAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemPay

final class CommonTangemPayAssembly: TangemPayAssembly {
    let customerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver
        = CommonTangemPayCustomerWalletAddressAndSavedTokensResolver()

    func makeCardDetailsRepository(for tangemPayAccount: TangemPayAccount) -> TangemPayCardDetailsRepository {
        CommonTangemPayCardDetailsRepository(tangemPayAccount: tangemPayAccount)
    }

    func makeTransactionDispatcher(
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        walletPublicKey: Wallet.PublicKey?
    ) -> TransactionDispatcher {
        TangemPayTransactionDispatcher(
            sender: TangemPayWithdrawSender(
                withdrawTransactionService: withdrawTransactionService,
                walletPublicKey: walletPublicKey
            )
        )
    }
}
