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
        let wallet: Wallet
        var walletPublisher: AnyPublisher<Wallet, Never> { .justWithError(output: wallet) }
        var statePublisher: AnyPublisher<WalletManagerState, Never> { .justWithError(output: .initial) }

        init(wallet: Wallet) {
            self.wallet = wallet
        }
    }

    func testTxValidation() {
        let wallet = Wallet(
            blockchain: .bitcoin(testnet: false),
            addresses: [.default: PlainAddress(
                value: "adfjbajhfaldfh",
                publicKey: .init(seedKey: Data(), derivationType: .none),
                type: .default
            )]
        )

        let walletManager: TransactionValidator = BaseTransactionValidator(wallet: wallet)
        walletManager.wallet.add(coinValue: 10)

        XCTAssertNoThrow(
            try walletManager.validate(
                amount: Amount(with: walletManager.wallet.amounts[.coin]!, value: 3),
                fee: Fee(Amount(with: walletManager.wallet.amounts[.coin]!, value: 3))
            )
        )

        assert(
            try walletManager.validate(
                amount: Amount(with: walletManager.wallet.amounts[.coin]!, value: -1),
                fee: Fee(Amount(with: walletManager.wallet.amounts[.coin]!, value: 3))
            ),
            throws: ValidationError.invalidAmount
        )

        assert(
            try walletManager.validate(
                amount: Amount(with: walletManager.wallet.amounts[.coin]!, value: 1),
                fee: Fee(Amount(with: walletManager.wallet.amounts[.coin]!, value: -1))
            ),
            throws: ValidationError.invalidFee
        )

        assert(
            try walletManager.validate(
                amount: Amount(with: walletManager.wallet.amounts[.coin]!, value: 11),
                fee: Fee(Amount(with: walletManager.wallet.amounts[.coin]!, value: 1))
            ),
            throws: ValidationError.amountExceedsBalance
        )

        assert(
            try walletManager.validate(
                amount: Amount(with: walletManager.wallet.amounts[.coin]!, value: 1),
                fee: Fee(Amount(with: walletManager.wallet.amounts[.coin]!, value: 11))
            ),
            throws: ValidationError.feeExceedsBalance
        )

        assert(
            try walletManager.validate(
                amount: Amount(with: walletManager.wallet.amounts[.coin]!, value: 3),
                fee: Fee(Amount(with: walletManager.wallet.amounts[.coin]!, value: 8))
            ),
            throws: ValidationError.totalExceedsBalance
        )
    }
}
