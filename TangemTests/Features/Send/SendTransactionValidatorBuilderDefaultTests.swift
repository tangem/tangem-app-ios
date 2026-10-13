//
//  SendTransactionValidatorBuilderDefaultTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemFoundation
import Testing
@testable import Tangem

/// Only the PSBT validator reacts to the builder. Every other validator takes the protocol default, and
/// the default must stay "the builder changes nothing" — these pin that a provider-built transaction can
/// never become a quieter validation for an account whose rules don't depend on it.
@Suite("SendTransactionValidator builder default")
struct SendTransactionValidatorBuilderDefaultTests {
    @Test("The Polymarket deposit validator refuses a provider transaction as well")
    func polymarketDepositValidatorRefusesAProviderTransaction() throws {
        let sut = PolymarketDepositTransactionValidator()

        do {
            try sut.validate(amount: makeAmount(), fee: makeFee(), builtBy: .provider)
            Issue.record("Expected the validator to refuse sending")
        } catch PolymarketDepositSendingUnsupportedError.sendingUnsupported {
            // The refusal matches the one `validate(amount:fee:)` raises
        }
    }

    @Test("The TangemPay validator runs its own balance check for a provider transaction")
    func tangemPayValidatorRunsItsOwnBalanceCheck() throws {
        let sut = TangemPaySendTransactionValidator(availableBalanceProvider: TokenBalanceProviderStub())

        do {
            try sut.validate(amount: makeAmount(), fee: makeFee(), builtBy: .provider)
            Issue.record("Expected the validator to report the missing balance")
        } catch ValidationError.balanceNotFound {
            // Same error `validate(amount:fee:)` raises on a balance that hasn't loaded
        }
    }

    @Test("The Polymarket withdraw validator runs its own balance check for a provider transaction")
    func polymarketWithdrawValidatorRunsItsOwnBalanceCheck() throws {
        let sut = PolymarketWithdrawTransactionValidator(
            availableBalanceProvider: TokenBalanceProviderStub(),
            minimum: PolymarketUSDAmount(usd: 2)
        )

        do {
            try sut.validate(amount: makeAmount(), fee: makeFee(), builtBy: .provider)
            Issue.record("Expected the validator to report the missing balance")
        } catch ValidationError.balanceNotFound {
            // Same error `validate(amount:fee:)` raises on a balance that hasn't loaded
        }
    }
}

// MARK: - Fixtures

private extension SendTransactionValidatorBuilderDefaultTests {
    func makeAmount() -> Amount {
        Amount(with: .polygon(testnet: false), type: .coin, value: 1)
    }

    func makeFee() -> Fee {
        Fee(Amount(with: .polygon(testnet: false), type: .coin, value: Decimal(stringValue: "0.01")!))
    }
}
