//
//  ApproveWithSwapFeeParametersTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import BigInt
@testable import Tangem

@Suite("ApproveWithSwapFeeParameters")
struct ApproveWithSwapFeeParametersTests {
    @Test("combinedFee sums swap and approve amounts and preserves the swap parameters")
    func combinedFee_sumsAmountsAndPreservesSwapParameters() throws {
        let swapParameters = EthereumLegacyFeeParameters(gasLimit: 200_000, gasPrice: 30_000_000_000)
        let swapFee = makeFee("0.002", parameters: swapParameters)
        let approveFee = makeFee("0.0005", parameters: EthereumLegacyFeeParameters(gasLimit: 50_000, gasPrice: 20_000_000_000))

        let combined = try ApproveWithSwapFeeParameters.combinedFee(swapFee: swapFee, approveFee: approveFee)

        #expect(combined.amount.value == Decimal(string: "0.0025")!)
        #expect(combined.amount.currencySymbol == swapFee.amount.currencySymbol)
        #expect(combined.amount.type == swapFee.amount.type)

        let parameters = try #require(combined.parameters as? ApproveWithSwapFeeParameters)
        let wrappedSwapParameters = try #require(parameters.swapParameters as? EthereumLegacyFeeParameters)
        #expect(wrappedSwapParameters.gasLimit == swapParameters.gasLimit)
        #expect(wrappedSwapParameters.gasPrice == swapParameters.gasPrice)
        #expect(parameters.approveFee.amount.value == approveFee.amount.value)
    }

    @Test("calculateFee adds the approve amount on top of the swap parameters fee")
    func calculateFee_addsApproveAmountToSwapFee() {
        let swapParameters = EthereumLegacyFeeParameters(gasLimit: 100_000, gasPrice: 2_000_000_000)
        let approveFee = makeFee("0.0003")
        let parameters = ApproveWithSwapFeeParameters(swapParameters: swapParameters, approveFee: approveFee)

        let decimalValue = Blockchain.ethereum(testnet: false).decimalValue
        let combined = parameters.calculateFee(decimalValue: decimalValue)
        let swapOnly = swapParameters.calculateFee(decimalValue: decimalValue)

        #expect(combined == swapOnly + approveFee.amount.value)
        #expect(combined == Decimal(string: "0.0005")!)
    }

    /// Bumping the gas limit rebuilds only the swap parameters; the approve fee is carried through unchanged.
    /// parametersType is proxied from the (updated) swap leg.
    @Test("changingGasLimit updates only the swap parameters and keeps the approve fee")
    func changingGasLimit_updatesSwapParametersOnly() throws {
        let swapParameters = EthereumLegacyFeeParameters(gasLimit: 100_000, gasPrice: 2_000_000_000)
        let approveFee = makeFee("0.0003")
        let parameters = ApproveWithSwapFeeParameters(swapParameters: swapParameters, approveFee: approveFee)

        let updated = parameters.changingGasLimit(to: 250_000)

        let updatedSwapParameters = try #require(updated.swapParameters as? EthereumLegacyFeeParameters)
        #expect(updatedSwapParameters.gasLimit == 250_000)
        #expect(updatedSwapParameters.gasPrice == swapParameters.gasPrice)
        #expect(updated.approveFee.amount.value == approveFee.amount.value)

        guard case .legacy(let proxiedParameters) = updated.parametersType else {
            Issue.record("Expected parametersType to proxy the legacy swap parameters")
            return
        }
        #expect(proxiedParameters.gasLimit == 250_000)
    }

    /// combinedFee must reject a swap fee whose parameters are not EthereumFeeParameters (wrong chain or missing), surfacing a defined loader error instead of building a malformed fee.
    @Test("combinedFee throws swapFeeParametersNotFound for non-Ethereum or missing swap parameters")
    func combinedFee_nonEthereumSwapParameters_throws() {
        let approveFee = makeFee("0.0005")

        let nonEthereumSwapFee = makeFee("0.0001", parameters: NonEthereumFeeParameters())
        expectSwapFeeParametersNotFound("non-Ethereum parameters") {
            try ApproveWithSwapFeeParameters.combinedFee(swapFee: nonEthereumSwapFee, approveFee: approveFee)
        }

        let missingParametersSwapFee = makeFee("0.0001")
        expectSwapFeeParametersNotFound("missing parameters") {
            try ApproveWithSwapFeeParameters.combinedFee(swapFee: missingParametersSwapFee, approveFee: approveFee)
        }
    }
}

// MARK: - Helpers

private extension ApproveWithSwapFeeParametersTests {
    func makeFee(_ value: String, parameters: FeeParameters? = nil) -> Fee {
        Fee(Amount(with: .ethereum(testnet: false), value: Decimal(string: value)!), parameters: parameters)
    }

    func expectSwapFeeParametersNotFound(_ label: String, _ operation: () throws -> Any) {
        do {
            _ = try operation()
            Issue.record("Expected combinedFee to throw swapFeeParametersNotFound for \(label)")
        } catch TokenFeeLoaderError.swapFeeParametersNotFound {
        } catch {
            Issue.record("Unexpected error for \(label): \(error)")
        }
    }
}

private struct NonEthereumFeeParameters: FeeParameters {}
