//
//  ValidatorTests.swift
//  ValidatorTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import BitcoinCore
import TangemSdk
@testable import BlockchainSdk
import Testing

struct ValidatorTests {
    @Test
    func txValidation() {
        let wallet = Wallet(
            blockchain: .bitcoin(testnet: false),
            addresses: [.default: PlainAddress(
                value: "adfjbajhfaldfh",
                publicKey: .init(seedKey: Data(), derivationType: .none),
                type: .default
            )]
        )

        let walletManager: TransactionValidator = BaseManager(wallet: wallet)
        walletManager.wallet.add(coinValue: 10)

        #expect(throws: Never.self) {
            try walletManager.validate(
                amount: Amount(with: walletManager.wallet.amounts[.coin]!, value: 3),
                fee: Fee(Amount(with: walletManager.wallet.amounts[.coin]!, value: 3))
            )
        }

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

    private func assert(
        _ expression: @autoclosure () throws -> Void,
        throws error: ValidationError
    ) {
        var thrownError: Error?

        #expect(
            performing: { try expression() },
            throws: { error in
                thrownError = error
                return true
            }
        )
        #expect(thrownError as? ValidationError == error)
    }
}
