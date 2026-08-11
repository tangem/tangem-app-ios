//
//  EthereumStakingTransactionHelperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
@testable import BlockchainSdk

struct EthereumStakingTransactionHelperTests {
    private let blockchain = Blockchain.ethereum(testnet: false)
    private let transactionBuilder = CommonEthereumTransactionBuilder(
        chainId: 1,
        sourceAddress: PlainAddress(value: Constants.from, type: .default)
    )

    /// A staking provider may quote a type-2 transaction without a tip, as StakeKit does for POL.
    @Test
    func zeroPriorityFeeIsTreatedAsEIP1559() throws {
        let helper = EthereumStakingTransactionHelper(transactionBuilder: transactionBuilder)
        let transaction = makeTransaction(maxFeePerGas: Constants.maxFeePerGasHex, maxPriorityFeePerGas: "0x00")

        let hash = try helper.prepareForSign(transaction)

        let expected = try expectedHash(
            feeParameters: EthereumEIP1559FeeParameters(
                gasLimit: Constants.gasLimit,
                maxFeePerGas: Constants.maxFeePerGas,
                priorityFee: .zero
            )
        )
        #expect(hash == expected)
    }

    /// The quoted `maxFeePerGas` is the whole cap and already includes the tip, so it must be signed as is.
    @Test
    func quotedMaxFeePerGasIsSignedWithoutTheTipAddedOnTop() throws {
        let helper = EthereumStakingTransactionHelper(transactionBuilder: transactionBuilder)
        let transaction = makeTransaction(
            maxFeePerGas: Constants.maxFeePerGasHex,
            maxPriorityFeePerGas: Constants.priorityFeeHex
        )

        let hash = try helper.prepareForSign(transaction)

        let expected = try expectedHash(
            feeParameters: EthereumEIP1559FeeParameters(
                gasLimit: Constants.gasLimit,
                maxFeePerGas: Constants.maxFeePerGas,
                priorityFee: Constants.priorityFee
            )
        )
        #expect(hash == expected)
    }

    @Test
    func legacyTransactionIsBuiltFromGasPrice() throws {
        let helper = EthereumStakingTransactionHelper(transactionBuilder: transactionBuilder)
        let transaction = makeTransaction(gasPrice: Constants.maxFeePerGasHex)

        let hash = try helper.prepareForSign(transaction)

        let expected = try expectedHash(
            feeParameters: EthereumLegacyFeeParameters(
                gasLimit: Constants.gasLimit,
                gasPrice: Constants.maxFeePerGas
            )
        )
        #expect(hash == expected)
    }

    @Test
    func transactionWithoutAnyFeeCapFails() {
        let helper = EthereumStakingTransactionHelper(transactionBuilder: transactionBuilder)
        let transaction = makeTransaction(maxPriorityFeePerGas: "0x00")

        #expect(throws: EthereumTransactionBuilderError.feeParametersNotFound) {
            try helper.prepareForSign(transaction)
        }
    }
}

// MARK: - Helpers

private extension EthereumStakingTransactionHelperTests {
    func expectedHash(feeParameters: FeeParameters) throws -> Data {
        let input = try transactionBuilder.buildSigningInput(
            destination: Constants.to,
            coinAmount: .zero,
            fee: Fee(.zeroCoin(for: blockchain), parameters: feeParameters),
            nonce: Constants.nonce,
            data: Data(hex: Constants.data)
        )

        return try transactionBuilder.buildTxCompilerPreSigningOutput(input: input).dataHash
    }

    func makeTransaction(
        maxFeePerGas: String? = nil,
        maxPriorityFeePerGas: String? = nil,
        gasPrice: String? = nil
    ) -> StakeKitTransaction {
        let feeFields = [
            maxFeePerGas.map { "\"maxFeePerGas\": \"\($0)\"" },
            maxPriorityFeePerGas.map { "\"maxPriorityFeePerGas\": \"\($0)\"" },
            gasPrice.map { "\"gasPrice\": \"\($0)\"" },
        ]
        .compactMap { $0 }
        .map { ", \($0)" }
        .joined()

        let unsignedData = """
        {
            "from": "\(Constants.from)",
            "gasLimit": "\(Constants.gasLimitHex)",
            "to": "\(Constants.to)",
            "data": "\(Constants.data)",
            "nonce": \(Constants.nonce),
            "type": 2,
            "chainId": 1\(feeFields)
        }
        """

        return StakeKitTransaction(
            id: "aa2b1b6c-1b6e-4a2e-9a1c-1a1b1c1d1e1f",
            amount: Amount(with: blockchain, type: .coin, value: 0),
            // The fee amount is irrelevant here — the gas parameters come from the compiled transaction.
            fee: Fee(.zeroCoin(for: blockchain)),
            unsignedData: unsignedData,
            type: nil,
            status: nil,
            stepIndex: 1,
            target: nil,
            solanaBlockhashDate: nil
        )
    }
}

// MARK: - Constants

private extension EthereumStakingTransactionHelperTests {
    enum Constants {
        /// Gas values of a real POL staking transaction quoted by StakeKit.
        static let from = "0xb1123efF798183B7Cb32F62607D3D39E950d9cc3"
        static let to = "0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908"
        static let data = "0xe4457a8a0000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000000000000000000"
        static let nonce = 66
        static let gasLimitHex = "0x037655"
        static let maxFeePerGasHex = "0x01165a8b80"
        static let priorityFeeHex = "0x054e0840"

        static let gasLimit = BigUInt(Data(hex: gasLimitHex))
        static let maxFeePerGas = BigUInt(Data(hex: maxFeePerGasHex))
        static let priorityFee = BigUInt(Data(hex: priorityFeeHex))
    }
}
