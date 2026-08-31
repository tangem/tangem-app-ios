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

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository {
        MockTangemPayCardDetailsRepository(card: card)
    }

    func makePinReader(for card: TangemPayCard) -> TangemPayPinReader {
        MockTangemPayPinReader()
    }

    func makeBiometryAuthorizer() -> TangemPayBiometryAuthorizer {
        MockTangemPayBiometryAuthorizer()
    }

    func makeTransactionDispatcher(
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        signerFactory: TangemSignerFactory,
        walletPublicKey: Wallet.PublicKey?,
        withdrawEligibility: TangemPayWithdrawEligibility
    ) -> TransactionDispatcher {
        MockTangemPayTransactionDispatcher()
    }
}
