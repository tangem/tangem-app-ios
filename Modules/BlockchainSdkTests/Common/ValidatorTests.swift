//
//  ValidatorTests.swift
//  ValidatorTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Combine
import Testing
@testable import BlockchainSdk

struct ValidatorTests {
    class BaseTransactionValidator: TransactionValidator {
        var wallet: Wallet
        var state: WalletManagerState
        var walletPublisher: AnyPublisher<Wallet, Never> { Just(wallet).eraseToAnyPublisher() }
        var statePublisher: AnyPublisher<WalletManagerState, Never> { Just(state).eraseToAnyPublisher() }

        init(wallet: Wallet, state: WalletManagerState = .initial) {
            self.wallet = wallet
            self.state = state
        }
    }

    @Test
    func txValidation() throws {
        let blockchain = Blockchain.bitcoin(testnet: false)
        let transactionValidator = BaseTransactionValidator(wallet: Wallet(blockchain: .bitcoin(testnet: false), publicKey: .empty, addressesProvider: EmptyAddressesProvider()))
        transactionValidator.wallet.add(coinValue: 10)
        let coinAmount = try #require(transactionValidator.wallet.amounts[.coin])

        #expect(throws: Never.self) {
            try transactionValidator.validate(
                amount: Amount(with: coinAmount, value: 3),
                fee: Fee(Amount(with: coinAmount, value: 3))
            )
        }

        #expect(throws: ValidationError.invalidAmount) {
            try transactionValidator.validate(
                amount: Amount(with: coinAmount, value: -1),
                fee: Fee(Amount(with: coinAmount, value: 3))
            )
        }

        #expect(throws: ValidationError.invalidFee) {
            try transactionValidator.validate(
                amount: Amount(with: coinAmount, value: 1),
                fee: Fee(Amount(with: coinAmount, value: -1))
            )
        }

        #expect(throws: ValidationError.amountExceedsBalance) {
            try transactionValidator.validate(
                amount: Amount(with: coinAmount, value: 11),
                fee: Fee(Amount(with: coinAmount, value: 1))
            )
        }

        #expect(
            throws: ValidationError.feeExceedsBalance(
                Fee(Amount(with: coinAmount, value: 11)),
                blockchain: blockchain,
                isFeeCurrency: true,
                feeCurrencyBalance: coinAmount.value
            )
        ) {
            try transactionValidator.validate(
                amount: Amount(with: coinAmount, value: 1),
                fee: Fee(Amount(with: coinAmount, value: 11))
            )
        }

        #expect(throws: ValidationError.totalExceedsBalance) {
            try transactionValidator.validate(
                amount: Amount(with: coinAmount, value: 3),
                fee: Fee(Amount(with: coinAmount, value: 8))
            )
        }
    }
}
