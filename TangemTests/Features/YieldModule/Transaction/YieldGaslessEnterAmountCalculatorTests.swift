//
//  YieldGaslessEnterAmountCalculatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Yield gasless enter amount")
struct YieldGaslessEnterAmountCalculatorTests {
    typealias SUT = YieldGaslessEnterAmountCalculator

    @Test("The supplied amount is the balance minus the fee in token units")
    func enterAmountSubtractsFee() {
        let token = makeToken()

        let amount = SUT().enterAmount(balance: 100, fee: makeFee(value: Decimal(string: "1.25")!, token: token), token: token)

        #expect(amount == BigUInt(98_750_000))
    }

    @Test("The fee is rounded up to the smallest token unit, as the signed max fee is")
    func feeRoundsUp() {
        let token = makeToken()

        let amount = SUT().enterAmount(balance: 10, fee: makeFee(value: Decimal(string: "0.0000001")!, token: token), token: token)

        #expect(amount == BigUInt(9_999_999))
    }

    @Test("Nothing is supplied when the fee takes the whole balance", arguments: [Decimal(10), Decimal(11)])
    func feeCoveringBalanceLeavesNothing(feeValue: Decimal) {
        let token = makeToken()

        let amount = SUT().enterAmount(balance: 10, fee: makeFee(value: feeValue, token: token), token: token)

        #expect(amount == nil)
    }

    @Test("A fee in the supplied token is recognised regardless of the address case")
    func suppliedTokenFeeIsRecognised() {
        let token = makeToken()
        let uppercasedToken = makeToken(contractAddress: token.contractAddress.uppercased())

        #expect(SUT().isPaidWithSuppliedToken(fee: makeFee(value: 1, token: uppercasedToken), token: token))
    }

    @Test("A fee in another token is not treated as the supplied token")
    func otherTokenFeeIsNotSuppliedToken() {
        let token = makeToken()
        let otherToken = makeToken(contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7")

        #expect(!SUT().isPaidWithSuppliedToken(fee: makeFee(value: 1, token: otherToken), token: token))
    }
}

// MARK: - Helpers

private extension YieldGaslessEnterAmountCalculatorTests {
    func makeToken(contractAddress: String = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48") -> Token {
        Token(name: "USD Coin", symbol: "USDC", contractAddress: contractAddress, decimalCount: 6, id: "usd-coin")
    }

    func makeFee(value: Decimal, token: Token) -> Fee {
        Fee(Amount(with: .ethereum(testnet: false), type: .token(value: token), value: value))
    }
}
