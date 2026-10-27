//
//  TangemPayAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation
import TangemPay

protocol TangemPayAssembly {
    var customerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver { get }
    var cardTokenizationService: TangemPayCardTokenizationService { get }

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository

    func makePinReader(for card: TangemPayCard) -> TangemPayPinReader

    func makeBiometryAuthorizer() -> TangemPayBiometryAuthorizer

    func makeTransactionDispatcher(
        userWalletId: UserWalletId,
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        signerFactory: TangemSignerFactory,
        walletPublicKey: Wallet.PublicKey?,
        accountToken: TangemPayAccountToken
    ) -> TransactionDispatcher
}
