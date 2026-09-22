//
//  SafeTransactionFeeParametersTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk
import Testing

struct SafeTransactionFeeParametersTests {
    @Test("The gas limit is the refunded total, and only the inner call's share of it moves")
    func gasLimitAndItsChange() {
        let parameters = Constants.parameters(gasToken: .coin(Constants.blockchain), gasPrice: 2_100)

        #expect(parameters.gasLimit == 23_520 + 110_000)
        #expect(parameters.nonce == 5)
        #expect(parameters.changingGasLimit(to: 110_000 + 30_000).safeTxGas == 30_000)
        #expect(parameters.changingGasLimit(to: 110_000 + 30_000).baseGas == 110_000)
        #expect(parameters.changingGasLimit(to: 110_000 + 30_000).nonce == 5)
        #expect(parameters.changingGasLimit(to: 1_000).safeTxGas == 0)
        #expect(parameters.changingNonce(to: 6).nonce == 6)
    }

    @Test("The fee is in the gas token: the coin by the network's decimals, a token by its own")
    func feeFollowsGasToken() {
        let coin = Constants.parameters(gasToken: .coin(Constants.blockchain), gasPrice: 2_100)
        let token = Constants.parameters(gasToken: Constants.usdc, gasPrice: 3)

        #expect(coin.calculateFee(decimalValue: Constants.blockchain.decimalValue) == Decimal((23_520 + 110_000) * 2_100) / Constants.blockchain.decimalValue)
        #expect(token.calculateFee(decimalValue: Constants.blockchain.decimalValue) == Decimal((23_520 + 110_000) * 3) / 1_000_000)
    }
}

// MARK: - Constants

private extension SafeTransactionFeeParametersTests {
    enum Constants {
        static let blockchain = Blockchain.ethereum(testnet: false)
        static let usdcToken = Token(name: "USDC", symbol: "USDC", contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", decimalCount: 6)
        static let usdc = SafeGasToken.token(usdcToken, blockchain: blockchain, nativeToTokenRate: 1_000_000_000)

        static func parameters(gasToken: SafeGasToken, gasPrice: BigUInt) -> SafeTransactionFeeParameters {
            SafeTransactionFeeParameters(
                safeTxGas: 23_520,
                baseGas: 110_000,
                gasPrice: gasPrice,
                gasToken: gasToken,
                refundReceiver: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                isDeployed: true,
                nonce: 5
            )
        }
    }
}
