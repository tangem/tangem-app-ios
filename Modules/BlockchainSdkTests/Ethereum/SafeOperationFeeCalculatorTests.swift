//
//  SafeOperationFeeCalculatorTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk
import Testing

struct SafeOperationFeeCalculatorTests {
    @Test("The deployment folds its gas into baseGas and nothing else")
    func baseGasFollowsDeployment() throws {
        let deployed = try safeParameters(of: SafeOperationFeeCalculator.fee(
            estimate: Constants.estimate,
            state: .deployed(nonce: 5, owners: [], threshold: 2),
            parameters: Constants.parameters
        ))
        let notDeployed = try safeParameters(of: SafeOperationFeeCalculator.fee(
            estimate: Constants.estimate,
            state: .notDeployed,
            parameters: Constants.parameters
        ))

        #expect(deployed.baseGas == 100)
        #expect(notDeployed.baseGas == 100 + 300)
        #expect(deployed.nonce == 5)
        #expect(notDeployed.nonce == 0)
        #expect(deployed.isDeployed)
        #expect(!notDeployed.isDeployed)
        #expect(deployed.safeTxGas == notDeployed.safeTxGas)
        #expect(deployed.gasPrice == notDeployed.gasPrice)
    }

    @Test("The estimate is buffered and priced with the margin, and the fee is their product in the coin")
    func bufferMarginAndFee() throws {
        let fee = SafeOperationFeeCalculator.fee(
            estimate: Constants.estimate,
            state: .deployed(nonce: 5, owners: [], threshold: 2),
            parameters: Constants.parameters
        )
        let parameters = try safeParameters(of: fee)

        #expect(parameters.safeTxGas == 23_520)
        #expect(parameters.gasPrice == 2_100)
        #expect(parameters.gasToken.address == "0x0000000000000000000000000000000000000000")
        #expect(parameters.refundReceiver == Constants.parameters.refundReceiver)
        #expect(fee.amount.type == .coin)
        #expect(fee.amount.value == Decimal((23_520 + 100) * 2_100) / Constants.decimalValue)
    }

    @Test("A token gasToken prices gas in the token's smallest units, rounded up, and the fee is in the token")
    func tokenGasPriceIsConvertedAndRoundedUp() throws {
        // 2_100 wei per gas at 1e9 tokens per coin, in 6-decimal units: 2_100 * 1e9 * 1e6 / 1e18 = 2.1
        let fee = SafeOperationFeeCalculator.fee(
            estimate: Constants.estimate,
            state: .deployed(nonce: 5, owners: [], threshold: 2),
            parameters: Constants.parameters(gasToken: Constants.usdc)
        )
        let parameters = try safeParameters(of: fee)

        #expect(parameters.gasPrice == 3)
        #expect(parameters.gasToken.address == "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        #expect(fee.amount.type == .token(value: Constants.usdcToken))
        #expect(fee.amount.value == Decimal((23_520 + 100) * 3) / 1_000_000)
    }

    private func safeParameters(of fee: Fee) throws -> SafeTransactionFeeParameters {
        try #require(fee.parameters as? SafeTransactionFeeParameters)
    }
}

// MARK: - Constants

private extension SafeOperationFeeCalculatorTests {
    enum Constants {
        static let estimate = SafeInnerCallEstimate(gasLimit: 21_000, gasPrice: 2_000)
        static let blockchain = Blockchain.ethereum(testnet: false)
        static let decimalValue = blockchain.decimalValue
        static let parameters = parameters(gasToken: .coin(blockchain))
        static let usdcToken = Token(name: "USDC", symbol: "USDC", contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", decimalCount: 6)
        static let usdc = SafeGasToken.token(usdcToken, blockchain: blockchain, nativeToTokenRate: 1_000_000_000)

        static func parameters(gasToken: SafeGasToken) -> SafeOperationParameters {
            SafeOperationParameters(
                baseGas: 100,
                deployGas: 300,
                gasPriceMarginPercent: 5,
                safeTxGasBufferPercent: 12,
                gasToken: gasToken,
                refundReceiver: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
            )
        }
    }
}
