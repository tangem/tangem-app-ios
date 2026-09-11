//
//  EthereumEIP1559FeeParametersMapperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
import Foundation
import Testing
@testable import BlockchainSdk

struct EthereumEIP1559FeeParametersMapperTests {
    @Test
    func arcAppliesMinimumMaxFeeAndFixedPriorityFee() {
        let gasLimit = BigUInt(21_000)
        let response = EthereumEIP1559FeeResponse(
            gasLimit: gasLimit,
            fees: (
                low: .init(max: gwei(10), priority: gwei(1)),
                market: .init(max: gwei(20), priority: gwei(2)),
                fast: .init(max: gwei(30), priority: gwei(3))
            )
        )

        let parameters = EthereumEIP1559FeeParametersMapper.map(
            response: response,
            blockchain: .arc(testnet: false)
        )

        #expect(parameters.map(\.gasLimit) == [gasLimit, gasLimit, gasLimit])
        #expect(parameters.map(\.maxFeePerGas) == [gwei(20), gwei(20), gwei(30)])
        #expect(parameters.map(\.priorityFee) == [gwei(5), gwei(5), gwei(5)])
        let decimalValue = Decimal(1_000_000_000) * Decimal(1_000_000_000)
        #expect(parameters[0].calculateFee(decimalValue: decimalValue) == Decimal(42) / Decimal(100_000))
    }

    @Test
    func otherEIP1559ChainsKeepEstimatedFees() {
        let response = EthereumEIP1559FeeResponse(
            gasLimit: 21_000,
            fees: (
                low: .init(max: gwei(10), priority: gwei(1)),
                market: .init(max: gwei(20), priority: gwei(2)),
                fast: .init(max: gwei(30), priority: gwei(3))
            )
        )

        let parameters = EthereumEIP1559FeeParametersMapper.map(
            response: response,
            blockchain: .ethereum(testnet: false)
        )

        #expect(parameters.map(\.maxFeePerGas) == [gwei(10), gwei(20), gwei(30)])
        #expect(parameters.map(\.priorityFee) == [gwei(1), gwei(2), gwei(3)])
    }

    @Test
    func arcFeeRulesPreserveGasLimitAndNonce() {
        let parameters = EthereumEIP1559FeeParameters(
            gasLimit: 42_000,
            maxFeePerGas: gwei(10),
            priorityFee: gwei(1),
            nonce: 7
        )
        .applyingFeeRules(for: .arc(testnet: true))

        #expect(parameters.gasLimit == 42_000)
        #expect(parameters.maxFeePerGas == gwei(20))
        #expect(parameters.priorityFee == gwei(5))
        #expect(parameters.nonce == 7)
    }

    private func gwei(_ value: UInt64) -> BigUInt {
        BigUInt(value) * BigUInt(1_000_000_000)
    }
}
