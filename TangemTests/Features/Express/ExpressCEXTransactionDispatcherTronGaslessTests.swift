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
        #expect(parameters.request.operation == .transfer(destinationAddress: sourceAddress))
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
                amountRaw: 10_000_000,
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

@Suite("TronGaslessTransactionSender — contract calls", .serialized)
struct TronGaslessTransactionSenderContractCallTests {
    @Test("a swap signs and submits compensation and original transactions")
    func swap_signsAndSubmitsBothTransactions() async throws {
        try await InjectedDependenciesIsolation.shared.run {
            let previousNetworkManager = InjectedValues[\.gaslessTransactionsNetworkManager]
            defer {
                InjectedValues[\.gaslessTransactionsNetworkManager] = previousNetworkManager
            }

            let networkManager = TronGaslessSubmitNetworkManagerStub()
            InjectedValues[\.gaslessTransactionsNetworkManager] = networkManager

            let token = Token(
                name: "USDT",
                symbol: "USDT",
                contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
                decimalCount: 6
            )
            let tokenItem = TokenItem.token(token, .init(.tron(testnet: false), derivationPath: nil))
            let walletModel = WalletModelTestsMock(
                tokenItem: tokenItem,
                isEmpty: false,
                addresses: [PlainAddress(value: "TSource", type: .default)]
            )
            let builder = TronGaslessBuilderSpy()
            walletModel.tronGaslessTransactionsBuilderMock = builder
            walletModel.availableBalanceProviderMock = TokenBalanceProviderTestsMock(balance: 10)

            let feeToken = BSDKToken(
                name: token.name,
                symbol: token.symbol,
                contractAddress: token.contractAddress,
                decimalCount: token.decimalCount
            )
            let callData = Data([0x31, 0x10, 0xC7, 0xB9])
            let parameters = TronGaslessFeeParameters(
                quoteId: "quote",
                request: TronGaslessQuoteRequest(
                    sourceAddress: "TSource",
                    tokenContractAddress: token.contractAddress,
                    amountRaw: 3_000_000,
                    feeTokenContractAddress: token.contractAddress,
                    operation: .swap(contractAddress: "TSwap", callData: callData, spender: "TSpender")
                ),
                feeRecipient: "TFeeRecipient",
                compensationToken: token.contractAddress,
                compensationAmountRaw: "2500000",
                expiresAt: .distantFuture,
                energy: 1,
                bandwidth: 1,
                trxCost: "20"
            )
            let transaction = BSDKTransaction(
                amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 0),
                fee: BSDKFee(BSDKAmount(with: feeToken, value: 2.5), parameters: parameters),
                sourceAddress: "TSource",
                destinationAddress: "TSwap",
                changeAddress: "TSource",
                contractAddress: "TSwap",
                params: TronTransactionParams(transactionType: .contractCall(callData: callData, feeLimit: 20_000_000))
            )
            let sut = TronGaslessTransactionSender(
                walletModel: walletModel,
                transactionSigner: TangemSignerStub()
            )

            let result = try await sut.send(transaction: transaction)

            #expect(result.hash == "originalHash")
            #expect(builder.originalTransaction?.destinationAddress == "TSwap")
            #expect(builder.compensationTransaction?.destinationAddress == "TFeeRecipient")
            #expect(builder.compensationTransaction?.amount.value == 2.5)
            #expect(networkManager.submitRequests == [
                .init(
                    quoteId: "quote",
                    signedCompensationTx: "signedCompensation",
                    signedOriginalTx: "signedOriginal"
                ),
            ])
        }
    }

    @Test("a swap validates the source amount and compensation against the fee-token balance")
    func swap_combinedAmountExceedsBalance_notEnoughGaslessFeeBalance() async {
        await InjectedDependenciesIsolation.shared.run {
            let previousNetworkManager = InjectedValues[\.gaslessTransactionsNetworkManager]
            defer {
                InjectedValues[\.gaslessTransactionsNetworkManager] = previousNetworkManager
            }

            let networkManager = TronGaslessSubmitNetworkManagerStub()
            InjectedValues[\.gaslessTransactionsNetworkManager] = networkManager

            let token = Token(
                name: "USDT",
                symbol: "USDT",
                contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
                decimalCount: 6
            )
            let tokenItem = TokenItem.token(token, .init(.tron(testnet: false), derivationPath: nil))
            let walletModel = WalletModelTestsMock(
                tokenItem: tokenItem,
                isEmpty: false,
                addresses: [PlainAddress(value: "TSource", type: .default)]
            )
            let builder = TronGaslessBuilderSpy()
            walletModel.tronGaslessTransactionsBuilderMock = builder
            walletModel.availableBalanceProviderMock = TokenBalanceProviderTestsMock(balance: 5)

            let feeToken = BSDKToken(
                name: token.name,
                symbol: token.symbol,
                contractAddress: token.contractAddress,
                decimalCount: token.decimalCount
            )
            let callData = Data([0x31, 0x10, 0xC7, 0xB9])
            let parameters = TronGaslessFeeParameters(
                quoteId: "quote",
                request: TronGaslessQuoteRequest(
                    sourceAddress: "TSource",
                    tokenContractAddress: token.contractAddress,
                    amountRaw: 3_000_000,
                    feeTokenContractAddress: token.contractAddress,
                    operation: .swap(contractAddress: "TSwap", callData: callData, spender: "TSpender")
                ),
                feeRecipient: "TFeeRecipient",
                compensationToken: token.contractAddress,
                compensationAmountRaw: "2500000",
                expiresAt: .distantFuture,
                energy: 1,
                bandwidth: 1,
                trxCost: "20"
            )
            let transaction = BSDKTransaction(
                amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 0),
                fee: BSDKFee(BSDKAmount(with: feeToken, value: 2.5), parameters: parameters),
                sourceAddress: "TSource",
                destinationAddress: "TSwap",
                changeAddress: "TSource",
                contractAddress: "TSwap",
                params: TronTransactionParams(transactionType: .contractCall(callData: callData, feeLimit: 20_000_000))
            )
            let sut = TronGaslessTransactionSender(
                walletModel: walletModel,
                transactionSigner: TangemSignerStub()
            )

            do {
                _ = try await sut.send(transaction: transaction)
                Issue.record("Expected notEnoughGaslessFeeBalance")
            } catch TokenFeeProviderError.notEnoughGaslessFeeBalance(let balance) {
                #expect(balance == 5)
            } catch {
                Issue.record("Unexpected error: \(error)")
            }

            #expect(builder.originalTransaction == nil)
            #expect(networkManager.submitRequests.isEmpty)
        }
    }
}

private final class TronGaslessBuilderSpy: TronGaslessTransactionsBuilder {
    private(set) var originalTransaction: BSDKTransaction?
    private(set) var compensationTransaction: BSDKTransaction?

    func buildForGaslessSubmit(
        originalTransaction: BSDKTransaction,
        compensationTransaction: BSDKTransaction,
        signer: TransactionSigner
    ) async throws -> TronGaslessSignedTransactions {
        self.originalTransaction = originalTransaction
        self.compensationTransaction = compensationTransaction
        return TronGaslessSignedTransactions(
            signedCompensationTx: "signedCompensation",
            signedOriginalTx: "signedOriginal"
        )
    }
}

private final class TronGaslessSubmitNetworkManagerStub: GaslessTransactionsNetworkManager {
    private(set) var submitRequests: [TronSubmitRequest] = []

    let cachedFeeRecipientAddress: String? = nil
    var availableFeeTokens: [FeeToken] { [] }
    var availableFeeTokensPublisher: AnyPublisher<[FeeToken], Never> { Just([]).eraseToAnyPublisher() }
    var availableTronFeeTokens: [TronFeeToken] { [] }
    var availableTronFeeTokensPublisher: AnyPublisher<[TronFeeToken], Never> { Just([]).eraseToAnyPublisher() }
    var currentHost: String { "test" }
    var feeRecipientAddress: String? { nil }

    func updateAvailableTokens() {}
    func sendGaslessTransaction(_ transaction: GaslessTransaction, executorVersion: GaslessExecutorVersion) async throws -> String { "" }
    func sendGaslessBatchTransaction(_ transaction: GaslessBatchTransaction) async throws -> String { "" }
    func initialize() {}
    func preloadFeeRecipientAddress() {}

    func estimateTronGaslessTransaction(
        _ request: TronEstimateRequest,
        userWalletId: UserWalletId
    ) async throws -> TronEstimateResponse {
        throw StubError.notNeeded
    }

    func submitTronGaslessTransaction(
        _ request: TronSubmitRequest,
        userWalletId: UserWalletId
    ) async throws -> TronSubmitResponse {
        submitRequests.append(request)
        let data = Data(
            """
            {
              "result": {
                "compensationTxHash": "compensationHash",
                "originalTxHash": "originalHash",
                "status": "broadcast"
              }
            }
            """.utf8
        )
        return try JSONDecoder().decode(TronSubmitResponse.self, from: data)
    }

    private enum StubError: Error {
        case notNeeded
    }
}
