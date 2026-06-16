//
//  MockTangemPayAssembly.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemPay

final class MockTangemPayAssembly: TangemPayAssembly {
    let customerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver
        = MockTangemPayCustomerWalletAddressAndSavedTokensResolver()

    func makeCardDetailsRepository(for tangemPayAccount: TangemPayAccount) -> TangemPayCardDetailsRepository {
        MockTangemPayCardDetailsRepository()
    }

    func makeExpressCEXTransactionDispatcher(
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        walletPublicKey: Wallet.PublicKey?
    ) -> TransactionDispatcher {
        MockTangemPayExpressCEXTransactionDispatcher()
    }
}
