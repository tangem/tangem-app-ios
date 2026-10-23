//
//  CommonTangemPayAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation
import TangemPay

final class CommonTangemPayAssembly: TangemPayAssembly {
    let customerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver
        = CommonTangemPayCustomerWalletAddressAndSavedTokensResolver()
    let cardTokenizationService: TangemPayCardTokenizationService = CommonTangemPayCardTokenizationService()

    func makeCardDetailsRepository(for card: TangemPayCard) -> TangemPayCardDetailsRepository {
        CommonTangemPayCardDetailsRepository(card: card)
    }

    func makePinReader(for card: TangemPayCard) -> TangemPayPinReader {
        CommonTangemPayPinReader(card: card)
    }

    func makeBiometryAuthorizer() -> TangemPayBiometryAuthorizer {
        CommonTangemPayBiometryAuthorizer()
    }

    func makeTransactionDispatcher(
        userWalletId: UserWalletId,
        withdrawTransactionService: TangemPayWithdrawTransactionService,
        signerFactory: TangemSignerFactory,
        walletPublicKey: Wallet.PublicKey?,
        accountToken: TangemPayAccountToken
    ) -> TransactionDispatcher {
        TangemPayTransactionDispatcher(
            userWalletId: userWalletId,
            withdrawTransactionService: withdrawTransactionService,
            signerFactory: signerFactory,
            walletPublicKey: walletPublicKey,
            accountToken: accountToken
        )
    }
}
