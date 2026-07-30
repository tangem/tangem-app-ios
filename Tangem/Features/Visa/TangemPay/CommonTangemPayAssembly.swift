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

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository {
        CommonTangemPayCardDetailsRepository(card: card)
    }

    func makeTransactionDispatcher(
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        signerFactory: TangemSignerFactory,
        walletPublicKey: Wallet.PublicKey?
    ) -> TransactionDispatcher {
        TangemPayTransactionDispatcher(
            withdrawTransactionService: withdrawTransactionService,
            signerFactory: signerFactory,
            walletPublicKey: walletPublicKey
        )
    }
}
