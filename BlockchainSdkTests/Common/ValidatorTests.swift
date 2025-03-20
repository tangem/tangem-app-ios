//
//  ValidatorTests.swift
//  ValidatorTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct ValidatorTests {
    class BaseTransactionValidator: TransactionValidator {
        var wallet: Wallet
        var walletPublisher: AnyPublisher<Wallet, Never> { Just(wallet).eraseToAnyPublisher() }
        var statePublisher: AnyPublisher<WalletManagerState, Never> { Just(.initial).eraseToAnyPublisher() }

        init(wallet: Wallet) {
            self.wallet = wallet
        }
    }

    @Test
    func txValidation() {
        let transactionValidator = BaseTransactionValidator(wallet: Wallet(blockchain: .bitcoin(testnet: false), addresses: [:]))
        transactionValidator.wallet.add(coinValue: 10)

        #expect(throws: Never.self) {
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 3),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 3))
            )
        }

        #expect(throws: ValidationError.invalidAmount) {
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: -1),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 3))
            )
        }

        #expect(throws: ValidationError.invalidFee) {
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 1),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: -1))
            )
        }

        #expect(throws: ValidationError.amountExceedsBalance) {
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 11),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 1))
            )
        }

        #expect(throws: ValidationError.feeExceedsBalance) {
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 1),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 11))
            )
        }

        #expect(throws: ValidationError.totalExceedsBalance) {
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 3),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 8))
            )
        }
    }
}
