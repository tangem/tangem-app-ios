//
//  PsbtSwapTransactionValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

/// How a swap out of a Bitcoin-like coin gets validated:
///
/// 1. `SendTransactionValidatorFactory` looks at the coin and builds this validator instead of `BSDKTransactionValidator`.
/// 2. Whoever validates says who assembled the transaction — `SwapModel` names the provider on a DEX quote.
/// 3. Assembled by us: the coin's own rules apply, exactly as before.
/// 4. Assembled by the provider: only the balances are checked. The provider decides which coins to spend
///    and what change to leave, so our rules would describe a transaction we never send.
struct PsbtSwapTransactionValidator: SendTransactionValidator {
    let transactionValidator: any BlockchainSdk.TransactionValidator

    func validate(amount: Amount) throws {
        try transactionValidator.validate(amount: amount)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try transactionValidator.validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee, builtBy: SendTransactionBuilder) throws {
        switch builtBy {
        case .wallet:
            try transactionValidator.validate(amount: amount, fee: fee)
        case .provider:
            try transactionValidator.validateAmounts(amount: amount, fee: fee)
        }
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try await transactionValidator.validate(amount: amount, fee: fee, destination: destination)
    }
}
