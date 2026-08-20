//
//  DogecoinFeeCalculatorTests.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

struct DogecoinFeeCalculatorTests {
    private let calculator = DogecoinFeeCalculator(
        minFee: 0.01,
        minFeePerByte: 0.01 / 1024,
        decimalValue: Blockchain.dogecoin.decimalValue
    )

    @Test
    func calculatesFeeRates() {
        let result = calculator.calculateFeeRates()

        #expect(result.slowSatoshiPerByte == 977)
        #expect(result.marketSatoshiPerByte == 9_770)
        #expect(result.prioritySatoshiPerByte == 97_700)
    }

    @Test
    func appliesMinimumFeeToEachOption() {
        let fees = makeFees(values: [0.001, 0.2, 0.5])

        let result = calculator.applyMinimumFees(fees)

        #expect(result.map(\.amount.value) == [0.01, 0.2, 1])
        #expect(result.compactMap { ($0.parameters as? BitcoinFeeParameters)?.rate } == [1, 10, 100])
    }

    @Test
    func preservesFeesAboveMinimums() {
        let fees = makeFees(values: [0.02, 0.2, 2])

        let result = calculator.applyMinimumFees(fees)

        #expect(result.map(\.amount.value) == fees.map(\.amount.value))
    }

    private func makeFees(values: [Decimal]) -> [Fee] {
        zip(values, [1, 10, 100]).map { value, rate in
            Fee(
                Amount(with: .dogecoin, value: value),
                parameters: BitcoinFeeParameters(rate: rate)
            )
        }
    }
}
