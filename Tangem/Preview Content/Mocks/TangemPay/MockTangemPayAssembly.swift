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
    let cardTokenizationService: TangemPayCardTokenizationService = MockTangemPayCardTokenizationService()

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository {
        MockTangemPayCardDetailsRepository(card: card)
    }

    func makePinReader(for card: TangemPayCard) -> TangemPayPinReader {
        MockTangemPayPinReader()
    }

    func makeBiometryAuthorizer() -> TangemPayBiometryAuthorizer {
        MockTangemPayBiometryAuthorizer()
    }

    /// Deliberately the real dispatcher: a hot wallet can sign once the session is renewed, so withdrawals reach the mocked backend.
    func makeTransactionDispatcher(
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        signerFactory: TangemSignerFactory,
        walletPublicKey: Wallet.PublicKey?,
        withdrawEligibility: TangemPayWithdrawEligibility
    ) -> TransactionDispatcher {
        TangemPayTransactionDispatcher(
            withdrawTransactionService: withdrawTransactionService,
            signerFactory: signerFactory,
            walletPublicKey: walletPublicKey,
            withdrawEligibility: withdrawEligibility
        )
    }
}
