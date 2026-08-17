//
//  ApproveTransactionDispatcherBuildTests.swift
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

@Suite("ApproveTransactionDispatcher — per-blockchain transaction build")
final class ApproveTransactionDispatcherBuildTests: LeakTrackingTestSuite {
    /// The calldata must ride `.contractCall` params, never `EthereumTransactionParams`.
    @Test("Tron approve builds a zero-value contract call carrying the calldata")
    func send_tronApprove_buildsContractCallTransaction() async throws {
        let approveData = ApproveTransactionData(
            txData: Data([0x09, 0x5E, 0xA7, 0xB3, 0xFF]),
            spender: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn",
            toContractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
        )
        let fee = Fee(Amount(with: .tron(testnet: false), value: Decimal(string: "15")!))
        let env = makeEnvironment(tokenItem: .blockchain(.init(.tron(testnet: false), derivationPath: nil)))

        _ = try await env.dispatcher.send(transaction: .approve(data: approveData, fee: fee))

        let sent = try #require(env.transferDispatcher.sentTransactions.first)
        guard case .transfer(let transaction) = sent else {
            Issue.record("Expected a .transfer transaction, got \(sent)")
            return
        }

        #expect(transaction.amount.value == 0)
        #expect(transaction.amount.type == .coin)
        #expect(transaction.destinationAddress == approveData.toContractAddress)
        #expect(transaction.contractAddress == approveData.toContractAddress)

        let params = try #require(transaction.params as? TronTransactionParams)
        guard case .contractCall(let calldata, let feeLimit) = params.transactionType else {
            Issue.record("Expected .contractCall params, got \(params.transactionType)")
            return
        }
        #expect(calldata == approveData.txData)
        #expect(feeLimit == nil)
    }

    @Test("EVM approve still builds EthereumTransactionParams")
    func send_evmApprove_buildsEthereumParams() async throws {
        let approveData = ApproveTransactionData(
            txData: Data([0x09, 0x5E, 0xA7, 0xB3, 0xAB]),
            spender: "0xSpender",
            toContractAddress: "0xContract"
        )
        let fee = Fee(Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.001")!))
        let env = makeEnvironment(tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)))

        _ = try await env.dispatcher.send(transaction: .approve(data: approveData, fee: fee))

        let sent = try #require(env.transferDispatcher.sentTransactions.first)
        guard case .transfer(let transaction) = sent else {
            Issue.record("Expected a .transfer transaction, got \(sent)")
            return
        }

        let params = try #require(transaction.params as? EthereumTransactionParams)
        #expect(params.data == approveData.txData)
        #expect(transaction.destinationAddress == approveData.toContractAddress)
    }
}

// MARK: - Environment

private extension ApproveTransactionDispatcherBuildTests {
    struct Environment {
        let dispatcher: ApproveTransactionDispatcher
        let transferDispatcher: TransferTransactionDispatcherSpy
    }

    func makeEnvironment(tokenItem: TokenItem) -> Environment {
        let walletModel = WalletModelTestsMock(tokenItem: tokenItem, isEmpty: false)
        let signer = TangemSignerStub()
        let transactionCreator = TransactionCreatorStub(blockchain: tokenItem.blockchain)
        let transferDispatcher = TransferTransactionDispatcherSpy()

        walletModel.transactionCreatorMock = transactionCreator

        let dispatcher = ApproveTransactionDispatcher(
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
}

// MARK: - Recording doubles

private final class TransferTransactionDispatcherSpy: TransactionDispatcher {
    private(set) var sentTransactions: [TransactionDispatcherTransactionType] = []

    var hasNFCInteraction: Bool { false }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        sentTransactions.append(transaction)
        return TransactionDispatcherResult(hash: "hash", url: nil, signerType: "stub", currentHost: "host")
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
