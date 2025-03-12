//
//  TransactionValidatorTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Combine
@testable import BlockchainSdk

class TransactionValidatorTests: XCTestCase {
    class BaseTransactionValidator: TransactionValidator {
        var wallet: Wallet
        var walletPublisher: AnyPublisher<Wallet, Never> { Just(wallet).eraseToAnyPublisher() }
        var statePublisher: AnyPublisher<WalletManagerState, Never> { Just(.initial).eraseToAnyPublisher() }

        init(wallet: Wallet) {
            self.wallet = wallet
        }
    }

    var transactionValidator: TransactionValidator!

    override func setUp() {
        transactionValidator = BaseTransactionValidator(wallet: Wallet(blockchain: .bitcoin(testnet: false), addresses: [:]))
        super.setUp()
    }

    func testTxValidation() {
        transactionValidator.wallet.add(coinValue: 10)

        XCTAssertNoThrow(
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 3),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 3))
            )
        )

        assert(
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: -1),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 3))
            ),
            throws: ValidationError.invalidAmount
        )

        assert(
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 1),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: -1))
            ),
            throws: ValidationError.invalidFee
        )

        assert(
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 11),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 1))
            ),
            throws: ValidationError.amountExceedsBalance
        )

        assert(
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 1),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 11))
            ),
            throws: ValidationError.feeExceedsBalance
        )

        assert(
            try transactionValidator.validate(
                amount: Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 3),
                fee: Fee(Amount(with: transactionValidator.wallet.amounts[.coin]!, value: 8))
            ),
            throws: ValidationError.totalExceedsBalance
        )
    }
}
