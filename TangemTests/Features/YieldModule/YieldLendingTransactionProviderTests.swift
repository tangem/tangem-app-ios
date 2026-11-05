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
    private static let factory = "0x2222222222222222222222222222222222222222"
    private static let owner = "0x3333333333333333333333333333333333333333"
    private static let wrappedNative = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    private static let upgradeImplementation = "0xaaF16358336a5e292b1D70057f99c3f2e8241C63"
    private static let fee = Fee(Amount(with: blockchain, type: .coin, value: Decimal(string: "0.0004")!))

    @Test("A deposit sends the amount as the transaction value to the module, with no approval")
    func deposit() async throws {
        let transaction = try await makeSUT().depositTransaction(
            amount: Decimal(string: "0.5")!,
            yieldModule: Self.yieldModule,
            upgradeImplementation: nil,
            fee: Self.fee
        )

        #expect(transaction.amount == Amount(with: Self.blockchain, type: .coin, value: Decimal(string: "0.5")!))
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == "0921ecd4")
    }

    @Test("A deposit into a module that needs an upgrade carries the deposit inside the upgrade and keeps its value")
    func depositWithUpgrade() async throws {
        let transaction = try await makeSUT().depositTransaction(
            amount: Decimal(string: "0.5")!,
            yieldModule: Self.yieldModule,
            upgradeImplementation: Self.upgradeImplementation,
            fee: Self.fee
        )

        #expect(transaction.amount == Amount(with: Self.blockchain, type: .coin, value: Decimal(string: "0.5")!))
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == Self.upgradeCall(wrapping: "0921ecd4"))
    }

    @Test("A deposit amount finer than a wei is rounded down to whole wei")
    func depositFinerThanWei() async throws {
        let transaction = try await makeSUT().depositTransaction(
            amount: Decimal(string: "0.50000000000000000099")!,
            yieldModule: Self.yieldModule,
            upgradeImplementation: nil,
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
                upgradeImplementation: nil,
                fee: Self.fee
            )
        }
    }

    @Test("Withdrawing part of the position withdraws exactly that amount in wei", arguments: ["0.4", "0.40000000000000000099"])
    func partialWithdrawal(amount: String) async throws {
        let transaction = try await makeSUT().withdrawTransaction(
            .partial(Decimal(string: amount)!),
            yieldModule: Self.yieldModule,
            upgradeImplementation: nil,
            fee: Self.fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == "84276d81000000000000000000000000000000000000000000000000058d15e176280000")
    }

    @Test("A partial withdrawal from a module that needs an upgrade carries the withdrawal inside the upgrade")
    func partialWithdrawalWithUpgrade() async throws {
        let transaction = try await makeSUT().withdrawTransaction(
            .partial(Decimal(string: "0.2")!),
            yieldModule: Self.yieldModule,
            upgradeImplementation: Self.upgradeImplementation,
            fee: Self.fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == Self.upgradeCall(wrapping: "84276d81" + Self.word("2c68af0bb140000")))
    }

    @Test("Withdrawing everything closes the position, however much it has grown since it was read")
    func fullWithdrawal() async throws {
        let transaction = try await makeSUT().withdrawTransaction(
            .all,
            yieldModule: Self.yieldModule,
            upgradeImplementation: nil,
            fee: Self.fee
        )

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
                upgradeImplementation: nil,
                fee: Self.fee
            )
        }
    }

    @Test("A user without a module deploys one for WETH through the factory, with no approval and no processor fee")
    func deploy() async throws {
        let transaction = try await makeSUT().deployTransaction(
            owner: Self.owner,
            wrappedNative: Self.wrappedNative,
            fee: Self.fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.factory)
        #expect(transaction.contractAddress == Self.factory)
        #expect(Self.callData(of: transaction) == "cbeda14c" + Self.word(Self.owner) + Self.word(Self.wrappedNative) + Self.word("0"))
    }

    @Test("WETH that was never set up is initialised on the module, with no approval and no processor fee")
    func initToken() async throws {
        let transaction = try await makeSUT().initTokenTransaction(
            wrappedNative: Self.wrappedNative,
            yieldModule: Self.yieldModule,
            upgradeImplementation: nil,
            fee: Self.fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == "ebd4b81c" + Self.word(Self.wrappedNative) + Self.word("0"))
    }

    @Test("Initialising WETH on a module that needs an upgrade carries the initialisation inside the upgrade")
    func initTokenWithUpgrade() async throws {
        let transaction = try await makeSUT().initTokenTransaction(
            wrappedNative: Self.wrappedNative,
            yieldModule: Self.yieldModule,
            upgradeImplementation: Self.upgradeImplementation,
            fee: Self.fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == Self.upgradeCall(wrapping: "ebd4b81c" + Self.word(Self.wrappedNative) + Self.word("0")))
    }

    @Test("WETH left inactive by a full withdrawal is reactivated on the module, with no approval and no processor fee")
    func reactivateToken() async throws {
        let transaction = try await makeSUT().reactivateTokenTransaction(
            wrappedNative: Self.wrappedNative,
            yieldModule: Self.yieldModule,
            upgradeImplementation: nil,
            fee: Self.fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == "c478e956" + Self.word(Self.wrappedNative) + Self.word("0"))
    }

    @Test("Reactivating WETH on a module that needs an upgrade carries the reactivation inside the upgrade")
    func reactivateTokenWithUpgrade() async throws {
        let transaction = try await makeSUT().reactivateTokenTransaction(
            wrappedNative: Self.wrappedNative,
            yieldModule: Self.yieldModule,
            upgradeImplementation: Self.upgradeImplementation,
            fee: Self.fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.yieldModule)
        #expect(transaction.contractAddress == Self.yieldModule)
        #expect(Self.callData(of: transaction) == Self.upgradeCall(wrapping: "c478e956" + Self.word(Self.wrappedNative) + Self.word("0")))
    }
}

// MARK: - Fixtures

private extension YieldLendingTransactionProviderTests {
    func makeSUT() -> YieldLendingTransactionProvider {
        let transactionCreator = trackForMemoryLeaks(TransactionCreatorStub(blockchain: Self.blockchain))

        return trackForMemoryLeaks(
            YieldLendingTransactionProvider(
                blockchain: Self.blockchain,
                factoryContractAddress: Self.factory,
                transactionCreator: transactionCreator
            )
        )
    }

    static func callData(of transaction: Transaction) -> String? {
        (transaction.params as? EthereumTransactionParams)?.data?.hex()
    }

    static func word(_ value: String) -> String {
        let hex = value.lowercased().removeHexPrefix()
        return String(repeating: "0", count: 64 - hex.count) + hex
    }

    static func upgradeCall(wrapping call: String) -> String {
        let padding = String(repeating: "0", count: (64 - call.count % 64) % 64)
        return "4f1ef286" + word(upgradeImplementation) + word("40") + word(String(call.count / 2, radix: 16)) + call + padding
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
