//
//  ExpressDEXTransactionDispatcherTronBuildTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemTestKit
@testable import BlockchainSdk
@testable import TangemExpress
@testable import Tangem

@Suite("ExpressDEXTransactionDispatcher — Tron transaction build")
final class ExpressDEXTransactionDispatcherTronBuildTests: LeakTrackingTestSuite {
    @Test("a provider contract call builds a coin-typed contract-call transaction with an adjusted fee limit")
    func buildTronTransaction_contractCall() async throws {
        let env = makeEnvironment()
        let fee = Fee(Amount(with: .tron(testnet: false), value: 16))

        let transaction = try await env.dispatcher.buildTronTransaction(
            data: makeExpressTransactionData(txData: "0x" + TronDEXFixtures.liFiRawTransactionHex),
            fee: fee
        )

        #expect(transaction.amount.value == 0)
        #expect(transaction.amount.type == .coin)
        #expect(transaction.destinationAddress == "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt")
        #expect(transaction.contractAddress == "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt")

        let params = try #require(transaction.params as? TronTransactionParams)
        guard case .contractCall(let callData, let feeLimit) = params.transactionType else {
            Issue.record("Expected .contractCall params, got \(params.transactionType)")
            return
        }
        #expect(callData.count == 1476)
        #expect(callData.prefix(4) == Data([0x31, 0x10, 0xC7, 0xB9]))
        #expect(feeLimit == 100_000_000)
        #expect(params.memo == nil)
    }

    @Test("a THORChain-routed contract call carries the embedded memo and the provider fee limit")
    func buildTronTransaction_contractCallWithMemo() async throws {
        let env = makeEnvironment()
        let fee = Fee(Amount(with: .tron(testnet: false), value: 2))

        let transaction = try await env.dispatcher.buildTronTransaction(
            data: makeExpressTransactionData(
                destinationAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
                txData: "0x" + TronDEXFixtures.swapKitRawTransactionHex
            ),
            fee: fee
        )

        let params = try #require(transaction.params as? TronTransactionParams)
        guard case .contractCall(_, let feeLimit) = params.transactionType else {
            Issue.record("Expected .contractCall params, got \(params.transactionType)")
            return
        }
        #expect(feeLimit == 10_000_000)
        #expect(params.memo == TronDEXFixtures.swapKitMemo)
    }

    @Test("a provider coin transfer builds a plain transfer transaction")
    func buildTronTransaction_transfer() async throws {
        let env = makeEnvironment()
        let fee = Fee(Amount(with: .tron(testnet: false), value: 1))

        let transaction = try await env.dispatcher.buildTronTransaction(
            data: makeExpressTransactionData(
                destinationAddress: "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6",
                txValue: 50,
                txData: TronDEXFixtures.swapKitTransferRawTransactionHex
            ),
            fee: fee
        )

        #expect(transaction.amount.value == 50)
        #expect(transaction.amount.type == .coin)
        #expect(transaction.destinationAddress == "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6")

        let params = try #require(transaction.params as? TronTransactionParams)
        guard case .transfer = params.transactionType else {
            Issue.record("Expected .transfer params, got \(params.transactionType)")
            return
        }
        #expect(params.memo == nil)
    }

    @Test("a provider transaction built for a different owner is rejected")
    func buildTronTransaction_foreignOwner_throws() async {
        let env = makeEnvironment(ownerAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF")

        await #expect(throws: TronDEXTransactionValidationError.ownerAddressMismatch) {
            _ = try await env.dispatcher.buildTronTransaction(
                data: makeExpressTransactionData(txData: "0x" + TronDEXFixtures.liFiRawTransactionHex),
                fee: Fee(Amount(with: .tron(testnet: false), value: 1))
            )
        }
    }

    @Test("a Tron DEX send hands the built contract call to the transfer dispatcher and returns its result")
    func sendForwardsBuiltTronTransactionToTransferDispatcher() async throws {
        let env = makeEnvironment()
        let data = makeExpressTransactionData(txData: "0x" + TronDEXFixtures.liFiRawTransactionHex)
        let fee = Fee(Amount(with: .tron(testnet: false), value: 1))

        let result = try await env.dispatcher.send(transaction: .dex(data: data, fee: fee))

        #expect(result.hash == TransferTransactionDispatcherSpy.hash)
        #expect(env.transferDispatcher.sentTransactions.count == 1)

        let sent = try #require(env.transferDispatcher.sentTransactions.first)
        guard case .transfer(let transaction) = sent else {
            Issue.record("Expected a .transfer transaction, got \(sent)")
            return
        }

        #expect(transaction.destinationAddress == "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt")
        #expect(transaction.fee.amount.value == 1)

        let params = try #require(transaction.params as? TronTransactionParams)
        guard case .contractCall = params.transactionType else {
            Issue.record("Expected .contractCall params, got \(params.transactionType)")
            return
        }
    }
}

// MARK: - Environment

private extension ExpressDEXTransactionDispatcherTronBuildTests {
    struct Environment {
        let dispatcher: ExpressDEXTransactionDispatcher
        let transferDispatcher: TransferTransactionDispatcherSpy
    }

    func makeEnvironment(ownerAddress: String = "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW") -> Environment {
        let tokenItem: TokenItem = .blockchain(.init(.tron(testnet: false), derivationPath: nil))
        let walletModel = WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            addresses: [PlainAddress(value: ownerAddress, type: .default)]
        )
        let signer = TangemSignerStub()
        let transactionCreator = TransactionCreatorStub(blockchain: tokenItem.blockchain)
        let transferDispatcher = TransferTransactionDispatcherSpy()

        walletModel.transactionCreatorMock = transactionCreator

        let dispatcher = ExpressDEXTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            transferTransactionDispatcher: transferDispatcher
        )

        trackForMemoryLeaks(walletModel)
        trackForMemoryLeaks(signer)
        trackForMemoryLeaks(transactionCreator)
        trackForMemoryLeaks(transferDispatcher)
        trackForMemoryLeaks(dispatcher)

        return Environment(dispatcher: dispatcher, transferDispatcher: transferDispatcher)
    }

    func makeExpressTransactionData(
        destinationAddress: String = "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt",
        txValue: Decimal = .zero,
        txData: String?
    ) -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW",
            destinationAddress: destinationAddress,
            extraDestinationId: nil,
            txValue: txValue,
            txData: txData,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }
}

// MARK: - Recording doubles

private final class TransferTransactionDispatcherSpy: TransactionDispatcher {
    static let hash = "hash"

    private(set) var sentTransactions: [TransactionDispatcherTransactionType] = []

    var hasNFCInteraction: Bool { false }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        sentTransactions.append(transaction)
        return TransactionDispatcherResult(hash: Self.hash, url: nil, signerType: "stub", currentHost: "host")
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
