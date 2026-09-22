//
//  PsbtSwapTransactionValidatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

/// Pinned on a real `DustRestrictable` chain validator rather than on an app-level stub: on the very
/// same amounts the transaction we build must be refused and the one the provider builds must pass,
/// and neither of them may skip the balances.
@Suite("PsbtSwapTransactionValidator")
struct PsbtSwapTransactionValidatorTests {
    @Test("A transaction built by the provider keeps the dust rules out")
    func providerTransactionKeepsTheDustRulesOut() throws {
        let sut = makeSUT()

        try sut.validate(amount: makeAmount(Constants.amount), fee: makeFee(), builtBy: .provider)
    }

    @Test("A transaction we build is refused on the same amounts")
    func ourOwnTransactionIsRefusedOnTheSameAmounts() throws {
        let sut = makeSUT()

        do {
            try sut.validate(amount: makeAmount(Constants.amount), fee: makeFee(), builtBy: .wallet)
            Issue.record("Expected the dust change to be rejected")
        } catch ValidationError.dustChange {
            // The change left on the wallet is below the dust value
        }
    }

    @Test("The entry that doesn't name the builder stays the strict one")
    func theEntryWithoutABuilderStaysTheStrictOne() throws {
        let sut = makeSUT()

        do {
            try sut.validate(amount: makeAmount(Constants.amount), fee: makeFee())
            Issue.record("Expected the dust change to be rejected")
        } catch ValidationError.dustChange {
            // Every flow that doesn't name the builder — sending, staking, the fee-included calculator — keeps the chain rules
        }
    }

    @Test("A balance that cannot cover the amount and the fee is refused for the provider as well")
    func anUncoveredBalanceIsRefusedForTheProviderAsWell() throws {
        let sut = makeSUT()

        do {
            try sut.validate(amount: makeAmount(Constants.balance), fee: makeFee(), builtBy: .provider)
            Issue.record("Expected the amount and the fee not to fit into the balance")
        } catch ValidationError.totalExceedsBalance {
            // Skipping the dust rules must not skip the balances
        }
    }
}

// MARK: - SUT

private extension PsbtSwapTransactionValidatorTests {
    func makeSUT() -> PsbtSwapTransactionValidator {
        var wallet = try! WalletFactory(blockchain: Constants.blockchain).makeWallet(publicKey: Constants.publicKey)
        wallet.add(coinValue: Constants.balance)

        let chainValidator = DustRestrictableValidatorStub(wallet: wallet, dustValue: makeAmount(Constants.dustValue))
        return PsbtSwapTransactionValidator(transactionValidator: chainValidator)
    }

    func makeAmount(_ value: Decimal) -> Amount {
        Amount(with: Constants.blockchain, type: .coin, value: value)
    }

    func makeFee() -> Fee {
        Fee(makeAmount(Constants.fee))
    }

    /// The amounts of a real Bitcoin swap: the change left after the amount and the fee is below the dust value.
    enum Constants {
        static let blockchain = Blockchain.bitcoin(testnet: false)
        static let balance = Decimal(stringValue: "0.00012265")!
        static let amount = Decimal(stringValue: "0.00011557")!
        static let fee = Decimal(stringValue: "0.00000286")!
        static let dustValue = Decimal(stringValue: "0.00001")!

        /// The secp256k1 generator point — a valid compressed key, so the address derivation succeeds.
        static let publicKey = Wallet.PublicKey(
            seedKey: Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798"),
            derivationType: .none
        )
    }
}

// MARK: - Stubs

private final class DustRestrictableValidatorStub: TransactionValidator, DustRestrictable {
    var wallet: Wallet
    let dustValue: Amount

    var walletPublisher: AnyPublisher<Wallet, Never> { Just(wallet).eraseToAnyPublisher() }

    init(wallet: Wallet, dustValue: Amount) {
        self.wallet = wallet
        self.dustValue = dustValue
    }
}
