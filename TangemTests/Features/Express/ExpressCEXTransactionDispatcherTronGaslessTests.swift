//
//  ExpressCEXTransactionDispatcherTronGaslessTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemTestKit
import TangemFoundation
@testable import BlockchainSdk
@testable import TangemExpress
@testable import Tangem

@Suite("ExpressCEXTransactionDispatcher — Tron gasless")
final class ExpressCEXTransactionDispatcherTronGaslessTests: LeakTrackingTestSuite {
    private let sourceAddress = "TSourceAddress"
    private let depositAddress = "TCEXDepositAddress"
    private let tokenContract = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"

    @Test("a Tron gasless CEX send signs the fee it was given")
    func send_tronGaslessFee_forwardsProvidedFee() async throws {
        let env = makeEnvironment()
        let previewFee = makeGaslessFee(compensation: Decimal(string: "2.5")!)

        let result = try await env.dispatcher.send(transaction: .cex(
            data: makeExpressTransactionData(txValue: 10),
            fee: previewFee
        ))

        #expect(result.hash == TransferTransactionDispatcherSpy.hash)

        let sent = try #require(env.transferDispatcher.sentTransactions.first)
        guard case .transfer(let transaction) = sent else {
            Issue.record("Expected a .transfer transaction, got \(sent)")
            return
        }

        #expect(transaction.amount.value == 10)
        #expect(transaction.destinationAddress == depositAddress)
        #expect(transaction.fee.amount.value == Decimal(string: "2.5"))
        let parameters = try #require(transaction.fee.parameters as? TronGaslessFeeParameters)
        #expect(parameters.quoteId == "stale-quote")
        #expect(parameters.request.destinationAddress == sourceAddress)
    }

    @Test("a coin-paid CEX send signs the fee it was given")
    func send_coinFee_forwardsProvidedFee() async throws {
        let env = makeEnvironment()
        let previewFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 4))

        let _ = try await env.dispatcher.send(transaction: .cex(
            data: makeExpressTransactionData(txValue: 10),
            fee: previewFee
        ))

        let sent = try #require(env.transferDispatcher.sentTransactions.first)
        guard case .transfer(let transaction) = sent else {
            Issue.record("Expected a .transfer transaction, got \(sent)")
            return
        }
        #expect(transaction.fee.amount.value == 4)
        #expect(transaction.destinationAddress == depositAddress)
    }
}

// MARK: - Environment

private extension ExpressCEXTransactionDispatcherTronGaslessTests {
    struct Environment {
        let dispatcher: ExpressCEXTransactionDispatcher
        let transferDispatcher: TransferTransactionDispatcherSpy
    }

    func makeEnvironment() -> Environment {
        let token = Token(
            name: "USDT",
            symbol: "USDT",
            contractAddress: tokenContract,
            decimalCount: 6
        )
        let tokenItem: TokenItem = .token(token, .init(.tron(testnet: false), derivationPath: nil))
        let walletModel = WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            addresses: [PlainAddress(value: sourceAddress, type: .default)]
        )
        let signer = TangemSignerStub()
        let transactionCreator = TransactionCreatorStub(blockchain: tokenItem.blockchain)
        let transferDispatcher = TransferTransactionDispatcherSpy()
        walletModel.transactionCreatorMock = transactionCreator

        let dispatcher = ExpressCEXTransactionDispatcher(
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

    func makeExpressTransactionData(txValue: Decimal) -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: txValue,
            toAmount: 20,
            expressTransactionId: "",
            transactionType: .send,
            sourceAddress: sourceAddress,
            destinationAddress: depositAddress,
            extraDestinationId: nil,
            txValue: txValue,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: depositAddress,
            slippage: nil
        )
    }

    func makeGaslessFee(compensation: Decimal) -> BSDKFee {
        let token = BSDKToken(name: "USDT", symbol: "USDT", contractAddress: tokenContract, decimalCount: 6)
        let parameters = TronGaslessFeeParameters(
            quoteId: "stale-quote",
            request: TronGaslessQuoteRequest(
                sourceAddress: sourceAddress,
                destinationAddress: sourceAddress,
                tokenContractAddress: tokenContract,
                amountRaw: "10000000",
                feeTokenContractAddress: tokenContract
            ),
            feeRecipient: "TFeeRecipient",
            compensationToken: tokenContract,
            compensationAmountRaw: "2500000",
            expiresAt: Date(timeIntervalSince1970: 0),
            energy: 1,
            bandwidth: 1,
            trxCost: "1"
        )
        return BSDKFee(BSDKAmount(with: token, value: compensation), parameters: parameters)
    }
}

// MARK: - Doubles

private final class TransferTransactionDispatcherSpy: TransactionDispatcher {
    static let hash = "hash"

    private(set) var sentTransactions: [TransactionDispatcherTransactionType] = []

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
