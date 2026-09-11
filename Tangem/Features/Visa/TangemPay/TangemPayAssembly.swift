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

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository

    func makePinReader(for card: TangemPayCard) -> TangemPayPinReader

    func makeBiometryAuthorizer() -> TangemPayBiometryAuthorizer

    func makeTransactionDispatcher(
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        signerFactory: TangemSignerFactory,
        walletPublicKey: Wallet.PublicKey?,
        withdrawEligibility: TangemPayWithdrawEligibility
    ) -> TransactionDispatcher
}
