//
//  YieldTransactionProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("Yield transaction provider")
struct YieldTransactionProviderTests {
    @Test("Gasless exit is built even when the native fee exceeds the coin balance")
    func gaslessExitSkipsFeeValidation() async throws {
        let provider = makeProvider(validatesFee: false)

        let transactions = try await provider.exitTransactions(
            tokenContractAddress: Constants.tokenContractAddress,
            yieldContractAddress: Constants.yieldContractAddress,
            fee: try makeExitFee()
        )

        let transaction = try #require(transactions.first)
        #expect(transactions.count == 1)
        #expect(transaction.destinationAddress == Constants.yieldContractAddress)
        #expect(transaction.contractAddress == Constants.yieldContractAddress)
        #expect(transaction.amount.value == .zero)
        #expect((transaction.fee.parameters as? EthereumFeeParameters)?.gasLimit == Constants.gasLimit)
    }

    @Test("Native exit still fails when the native fee exceeds the coin balance")
    func nativeExitValidatesFee() async throws {
        let provider = makeProvider(validatesFee: true)

        await #expect(throws: FeeValidationError.self) {
            try await provider.exitTransactions(
                tokenContractAddress: Constants.tokenContractAddress,
                yieldContractAddress: Constants.yieldContractAddress,
                fee: try makeExitFee()
            )
        }
    }
}

// MARK: - Helpers

private extension YieldTransactionProviderTests {
    enum Constants {
        static let blockchain = Blockchain.ethereum(testnet: false)
        static let tokenContractAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
        static let yieldContractAddress = "0x1111111111111111111111111111111111111111"
        static let gasLimit: BigUInt = 120_000
    }

    func makeProvider(validatesFee: Bool) -> YieldTransactionProvider {
        YieldTransactionProvider(
            token: Token(
                name: "USD Coin",
                symbol: "USDC",
                contractAddress: Constants.tokenContractAddress,
                decimalCount: 6,
                id: "usd-coin"
            ),
            blockchain: Constants.blockchain,
            transactionCreator: FeeRejectingTransactionCreator(blockchain: Constants.blockchain),
            yieldSupplyContractAddresses: YieldSupplyContractAddresses(
                processorContractAddress: "0x2222222222222222222222222222222222222222",
                factoryContractAddress: "0x3333333333333333333333333333333333333333",
                swapExecutionRegistryContractAddress: "0x4444444444444444444444444444444444444444"
            ),
            validatesFee: validatesFee
        )
    }

    func makeExitFee() throws -> ExitFee {
        try ExitFee(fees: [
            Fee(
                Amount(with: Constants.blockchain, type: .coin, value: 0.001),
                parameters: EthereumEIP1559FeeParameters(gasLimit: Constants.gasLimit, baseFee: 1, priorityFee: 1)
            ),
        ])
    }
}

// MARK: - Test doubles

private struct FeeValidationError: Error {}

private final class FeeRejectingTransactionCreator: TransactionCreator {
    var wallet: Wallet

    init(blockchain: Blockchain) {
        wallet = Wallet(
            blockchain: blockchain,
            publicKey: .init(seedKey: Data(), derivationType: .none),
            addressesProvider: EmptyAddressesProvider()
        )
    }

    var walletPublisher: AnyPublisher<Wallet, Never> {
        Just(wallet).eraseToAnyPublisher()
    }

    func validate(amount: Amount, fee: Fee) throws {
        throw FeeValidationError()
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        throw FeeValidationError()
    }
}
