//
//  YieldLendingTransactionProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("YieldLendingTransactionProvider")
final class YieldLendingTransactionProviderTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let yieldModule = "0x1111111111111111111111111111111111111111"
    private static let fee = Fee(Amount(with: blockchain, type: .coin, value: Decimal(string: "0.0004")!))

    @Test("A deposit sends the amount as the transaction value to the module, with no approval")
    func deposit() async throws {
        let transaction = try await makeSUT().depositTransaction(
            amount: Decimal(string: "0.5")!,
            yieldModule: Self.yieldModule,
            fee: Self.fee
        )

        #expect(transaction.amount == Amount(with: Self.blockchain, type: .coin, value: Decimal(string: "0.5")!))
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == "0921ecd4")
    }

    @Test("A deposit amount finer than a wei is rounded down to whole wei")
    func depositFinerThanWei() async throws {
        let transaction = try await makeSUT().depositTransaction(
            amount: Decimal(string: "0.50000000000000000099")!,
            yieldModule: Self.yieldModule,
            fee: Self.fee
        )

        #expect(transaction.amount == Amount(with: Self.blockchain, type: .coin, value: Decimal(string: "0.5")!))
    }

    @Test("A deposit of less than a wei is rejected instead of paying gas for an empty deposit", arguments: ["0", "0.0000000000000000009", "-1"])
    func emptyDeposit(amount: String) async {
        await #expect(throws: ValidationError.invalidAmount) {
            try await makeSUT().depositTransaction(
                amount: Decimal(string: amount)!,
                yieldModule: Self.yieldModule,
                fee: Self.fee
            )
        }
    }

    @Test("Withdrawing part of the position withdraws exactly that amount in wei", arguments: ["0.4", "0.40000000000000000099"])
    func partialWithdrawal(amount: String) async throws {
        let transaction = try await makeSUT().withdrawTransaction(
            .partial(Decimal(string: amount)!),
            yieldModule: Self.yieldModule,
            fee: Self.fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == "84276d81000000000000000000000000000000000000000000000000058d15e176280000")
    }

    @Test("Withdrawing everything closes the position, however much it has grown since it was read")
    func fullWithdrawal() async throws {
        let transaction = try await makeSUT().withdrawTransaction(.all, yieldModule: Self.yieldModule, fee: Self.fee)

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == "4423380d")
    }

    @Test("A partial withdrawal of less than a wei is rejected instead of sending nothing", arguments: ["0", "0.0000000000000000009", "-1"])
    func emptyPartialWithdrawal(amount: String) async {
        await #expect(throws: ValidationError.invalidAmount) {
            try await makeSUT().withdrawTransaction(
                .partial(Decimal(string: amount)!),
                yieldModule: Self.yieldModule,
                fee: Self.fee
            )
        }
    }
}

// MARK: - Fixtures

private extension YieldLendingTransactionProviderTests {
    func makeSUT() -> YieldLendingTransactionProvider {
        let transactionCreator = trackForMemoryLeaks(TransactionCreatorStub(blockchain: Self.blockchain))

        return trackForMemoryLeaks(
            YieldLendingTransactionProvider(blockchain: Self.blockchain, transactionCreator: transactionCreator)
        )
    }

    static func callData(of transaction: Transaction) -> String? {
        (transaction.params as? EthereumTransactionParams)?.data?.hex()
    }
}

private final class TransactionCreatorStub: TransactionCreator {
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

    func validate(amount: Amount, fee: Fee) throws {}

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {}
}
