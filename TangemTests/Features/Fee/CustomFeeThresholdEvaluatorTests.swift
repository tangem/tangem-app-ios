//
//  CustomFeeThresholdEvaluatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("CustomFeeThresholdEvaluator")
struct CustomFeeThresholdEvaluatorTests {
    private let tokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    private func fee(_ value: Decimal) -> BSDKFee {
        BSDKFee(BSDKAmount(with: .ethereum(testnet: false), value: value))
    }

    private func tokenFee(_ option: FeeOption, _ value: Decimal) -> TokenFee {
        TokenFee(option: option, tokenItem: tokenItem, value: .success(fee(value)))
    }

    private func feeValues(slow: Decimal, market: Decimal, fast: Decimal) -> [TokenFee] {
        [tokenFee(.slow, slow), tokenFee(.market, market), tokenFee(.fast, fast)]
    }

    @Test("Non-custom option yields no warning")
    func nonCustomOption_noWarning() {
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFee(.market, 100),
            feeValues: feeValues(slow: 1, market: 2, fast: 3)
        )
        #expect(result == nil)
    }

    @Test("Loading custom fee yields no warning")
    func loadingCustomFee_noWarning() {
        let selected = TokenFee(option: .custom, tokenItem: tokenItem, value: .loading)
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: selected,
            feeValues: feeValues(slow: 1, market: 2, fast: 3)
        )
        #expect(result == nil)
    }

    @Test("Custom fee above 5x fast is too high")
    func aboveFiveTimesFast_tooHigh() {
        // fast = 2, custom = 12 → 12 > 10, order = 12 / 2 = 6
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFee(.custom, 12),
            feeValues: feeValues(slow: 1, market: 1.5, fast: 2)
        )
        #expect(result == .tooHigh(orderOfMagnitude: 6))
    }

    @Test("Order of magnitude is rounded to the nearest integer")
    func tooHighOrder_isRounded() {
        // fast = 2, custom = 11 → 11 > 10, 11 / 2 = 5.5 → .plain → 6
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFee(.custom, 11),
            feeValues: feeValues(slow: 1, market: 1.5, fast: 2)
        )
        #expect(result == .tooHigh(orderOfMagnitude: 6))
    }

    @Test("Custom fee exactly 5x fast is not too high")
    func exactlyFiveTimesFast_noWarning() {
        // fast = 2, custom = 10 → 10 > 10 is false
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFee(.custom, 10),
            feeValues: feeValues(slow: 1, market: 1.5, fast: 2)
        )
        #expect(result == nil)
    }

    @Test("Custom fee below slow is too low")
    func belowSlow_tooLow() {
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFee(.custom, 0.5),
            feeValues: feeValues(slow: 1, market: 2, fast: 3)
        )
        #expect(result == .tooLow)
    }

    @Test("Custom fee equal to slow is not too low")
    func equalToSlow_noWarning() {
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFee(.custom, 1),
            feeValues: feeValues(slow: 1, market: 2, fast: 3)
        )
        #expect(result == nil)
    }

    @Test("Missing fast option suppresses too-high")
    func missingFastOption_noTooHigh() {
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFee(.custom, 1000),
            feeValues: [tokenFee(.slow, 1), tokenFee(.market, 2)]
        )
        #expect(result == nil)
    }

    @Test("Missing slow option suppresses too-low")
    func missingSlowOption_noTooLow() {
        let result = CustomFeeThresholdEvaluator.evaluate(
            selectedFee: tokenFee(.custom, 0.0001),
            feeValues: [tokenFee(.market, 2), tokenFee(.fast, 3)]
        )
        #expect(result == nil)
    }
}
