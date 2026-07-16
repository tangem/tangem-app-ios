//
//  ExpressApproveAndDEXTransactionDispatcherTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BigInt
import TangemFoundation
import TangemTestKit
@testable import BlockchainSdk
@testable import TangemExpress
@testable import Tangem

@Suite("ExpressApproveAndDEXTransactionDispatcher")
final class ExpressApproveAndDEXTransactionDispatcherTests: LeakTrackingTestSuite {
    /// Any transaction other than .approveAndDex is refused immediately, before anything is built or signed.
    @Test("send refuses a non approveAndDex transaction")
    func send_wrongTransactionType_throwsTransactionNotFound() async {
        let env = makeEnvironment(tokenItem: ethereumTokenItem)
        let transaction: TransactionDispatcherTransactionType = .approve(
            data: makeApproveData(),
            fee: Fee(Amount(with: .ethereum(testnet: false), value: 0))
        )

        do {
            _ = try await env.dispatcher.send(transaction: transaction)
            Issue.record("Expected send to throw transactionNotFound")
        } catch TransactionDispatcherResult.Error.transactionNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    /// A non-EVM blockchain has no approve+swap flow, so the dispatcher rejects it before parsing the fee.
    @Test("send rejects a non-EVM blockchain")
    func send_nonEvmBlockchain_throwsDexNotSupported() async {
        let env = makeEnvironment(tokenItem: bitcoinTokenItem)
        let transaction: TransactionDispatcherTransactionType = .approveAndDex(
            data: makeExpressTransactionData(),
            fee: Fee(Amount(with: .bitcoin(testnet: false), value: 0)),
            approveData: makeApproveData()
        )

        do {
            _ = try await env.dispatcher.send(transaction: transaction)
            Issue.record("Expected send to throw dexNotSupported")
        } catch DEXTransactionDispatcherError.dexNotSupported(let blockchain) {
            #expect(!blockchain.isEmpty)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    /// On EVM, an approveAndDex whose fee is not an ApproveWithSwapFeeParameters is rejected before any transaction is built.
    @Test("send rejects a fee without ApproveWithSwapFeeParameters")
    func send_feeWithoutApproveWithSwapParameters_throwsFeeNotFound() async {
        let env = makeEnvironment(tokenItem: ethereumTokenItem)
        let transaction: TransactionDispatcherTransactionType = .approveAndDex(
            data: makeExpressTransactionData(),
            fee: Fee(
                Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.001")!),
                parameters: EthereumLegacyFeeParameters(gasLimit: 21_000, gasPrice: 1_000_000_000)
            ),
            approveData: makeApproveData()
        )

        do {
            _ = try await env.dispatcher.send(transaction: transaction)
            Issue.record("Expected send to throw feeNotFound")
        } catch TransactionDispatcherResult.Error.feeNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    /// The happy path builds both legs, signs them in a single session in [approve, swap] order, splits the combined fee, and returns the swap (last) result.
    @Test("send builds approve+swap, signs them in one call, and returns the swap result")
    func send_approveAndDex_buildsBothLegsAndReturnsSwapResult() async throws {
        let approveFee = Fee(
            Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.0005")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: 50_000, gasPrice: 20_000_000_000)
        )
        let swapFee = Fee(
            Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.002")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: 200_000, gasPrice: 30_000_000_000)
        )
        let combinedFee = try ApproveWithSwapFeeParameters.combinedFee(swapFee: swapFee, approveFee: approveFee)
        let expressData = makeExpressTransactionData()
        let approveData = makeApproveData()

        let env = makeEnvironment(
            tokenItem: ethereumTokenItem,
            multipleTransactionsSenderResult: .success([
                TransactionSendResult(hash: "approveHash", currentProviderHost: "host"),
                TransactionSendResult(hash: "swapHash", currentProviderHost: "host"),
            ])
        )

        let result = try await env.dispatcher.send(
            transaction: .approveAndDex(data: expressData, fee: combinedFee, approveData: approveData)
        )

        #expect(env.multipleTransactionsSender.sendCalls.count == 1)
        let sentTransactions = try #require(env.multipleTransactionsSender.sendCalls.first)
        #expect(sentTransactions.count == 2)

        let approveTransaction = sentTransactions[0]
        let swapTransaction = sentTransactions[1]

        #expect(approveTransaction.amount.value == 0)
        #expect(approveTransaction.destinationAddress == approveData.toContractAddress)
        #expect(approveTransaction.fee.amount.value == approveFee.amount.value)
        #expect((approveTransaction.params as? EthereumTransactionParams)?.data == approveData.txData)

        #expect(swapTransaction.amount.value == expressData.txValue)
        #expect(swapTransaction.destinationAddress == expressData.destinationAddress)
        #expect(swapTransaction.fee.amount.value == swapFee.amount.value)
        #expect((swapTransaction.params as? EthereumTransactionParams)?.data == Data(hexString: expressData.txData!))

        #expect(approveTransaction.amount.type == swapTransaction.amount.type)

        #expect(env.gaslessSender.sendCalls.isEmpty)

        #expect(result.hash == "swapHash")
        #expect(env.walletModel.updateAfterSendingTransactionCallCount == 1)
    }

    /// Without a multiple-transactions sender both legs cannot be signed in one session, so the dispatcher rejects the send and does not refresh the wallet.
    @Test("send fails when the wallet has no multiple transactions sender")
    func send_withoutMultipleTransactionsSender_throwsTransactionNotSupported() async throws {
        let env = makeEnvironment(tokenItem: ethereumTokenItem, includeMultipleTransactionsSender: false)
        let transaction: TransactionDispatcherTransactionType = .approveAndDex(
            data: makeExpressTransactionData(),
            fee: try makeCombinedFee(),
            approveData: makeApproveData()
        )

        do {
            _ = try await env.dispatcher.send(transaction: transaction)
            Issue.record("Expected send to throw transactionNotSupported")
        } catch TransactionDispatcherProviderError.transactionNotSupported(let reason) {
            #expect(!reason.isEmpty)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(env.walletModel.updateAfterSendingTransactionCallCount == 0)
    }

    /// A failure while broadcasting is surfaced as a mapped error and must not mark the wallet as having sent a transaction.
    @Test("send surfaces a send failure as a mapped error and does not refresh the wallet")
    func send_sendFailure_throwsMappedErrorAndDoesNotUpdateWallet() async throws {
        let env = makeEnvironment(
            tokenItem: ethereumTokenItem,
            multipleTransactionsSenderResult: .failure(SendTxError(error: StubUniversalError()))
        )
        let transaction: TransactionDispatcherTransactionType = .approveAndDex(
            data: makeExpressTransactionData(),
            fee: try makeCombinedFee(),
            approveData: makeApproveData()
        )

        do {
            _ = try await env.dispatcher.send(transaction: transaction)
            Issue.record("Expected send to throw a mapped send error")
        } catch TransactionDispatcherResult.Error.sendTxError {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(env.walletModel.updateAfterSendingTransactionCallCount == 0)
    }

    /// On a gasless-supported chain with a token-denominated fee, both legs route through the gasless sender (not the regular signing path), and the swap (last) result is returned.
    @Test("gasless-supported chain with a token fee routes both legs through the gasless sender")
    func send_gaslessChainTokenFee_routesToGaslessSender() async throws {
        let combinedFee = try makeTokenCombinedFee()
        let env = makeEnvironment(
            tokenItem: ethereumTokenItem,
            gaslessResult: [
                TransactionDispatcherResult(hash: "approveHash", url: nil, signerType: "stub", currentHost: "host"),
                TransactionDispatcherResult(hash: "swapHash", url: nil, signerType: "stub", currentHost: "host"),
            ]
        )

        let result = try await env.dispatcher.send(
            transaction: .approveAndDex(data: makeExpressTransactionData(), fee: combinedFee, approveData: makeApproveData())
        )

        #expect(env.gaslessSender.sendCalls.count == 1)
        #expect(env.gaslessSender.sendCalls.first?.count == 2)
        #expect(env.multipleTransactionsSender.sendCalls.isEmpty)
        #expect(result.hash == "swapHash")
        #expect(env.walletModel.updateAfterSendingTransactionCallCount == 1)
    }
}

// MARK: - Environment

private extension ExpressApproveAndDEXTransactionDispatcherTests {
    struct Environment {
        let dispatcher: ExpressApproveAndDEXTransactionDispatcher
        let walletModel: WalletModelTestsMock
        let transactionCreator: TransactionCreatorStub
        let multipleTransactionsSender: MultipleTransactionsSenderSpy
        let gaslessSender: GaslessSenderSpy
    }

    var ethereumTokenItem: TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }

    var bitcoinTokenItem: TokenItem {
        .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
    }

    func makeEnvironment(
        tokenItem: TokenItem,
        multipleTransactionsSenderResult: Result<[TransactionSendResult], SendTxError> = .success([]),
        includeMultipleTransactionsSender: Bool = true,
        gaslessResult: [TransactionDispatcherResult] = []
    ) -> Environment {
        let walletModel = WalletModelTestsMock(tokenItem: tokenItem, isEmpty: false)
        let signer = TangemSignerStub()
        let transactionCreator = TransactionCreatorStub()
        let multipleTransactionsSender = MultipleTransactionsSenderSpy(result: multipleTransactionsSenderResult)
        let gaslessSender = GaslessSenderSpy(result: gaslessResult)

        walletModel.transactionCreatorMock = transactionCreator
        if includeMultipleTransactionsSender {
            walletModel.multipleTransactionsSenderMock = multipleTransactionsSender
        }

        let dispatcher = ExpressApproveAndDEXTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer,
            gaslessTransactionSender: gaslessSender
        )

        trackForMemoryLeaks(walletModel)
        trackForMemoryLeaks(signer)
        trackForMemoryLeaks(transactionCreator)
        trackForMemoryLeaks(multipleTransactionsSender)
        trackForMemoryLeaks(gaslessSender)
        trackForMemoryLeaks(dispatcher)

        return Environment(
            dispatcher: dispatcher,
            walletModel: walletModel,
            transactionCreator: transactionCreator,
            multipleTransactionsSender: multipleTransactionsSender,
            gaslessSender: gaslessSender
        )
    }

    func makeExpressTransactionData() -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "0xDestination",
            extraDestinationId: nil,
            txValue: Decimal(string: "1.5")!,
            txData: "0xabcdef",
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }

    func makeApproveData() -> ApproveTransactionData {
        ApproveTransactionData(txData: Data([0xAB]), spender: "0xSpender", toContractAddress: "0xContract")
    }

    func makeCombinedFee() throws -> Fee {
        try ApproveWithSwapFeeParameters.combinedFee(
            swapFee: Fee(
                Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.002")!),
                parameters: EthereumLegacyFeeParameters(gasLimit: 200_000, gasPrice: 30_000_000_000)
            ),
            approveFee: Fee(
                Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.0005")!),
                parameters: EthereumLegacyFeeParameters(gasLimit: 50_000, gasPrice: 20_000_000_000)
            )
        )
    }

    func makeTokenCombinedFee() throws -> Fee {
        let token = Token(name: "USDC", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6)
        let swapFee = Fee(
            Amount(with: .ethereum(testnet: false), type: .token(value: token), value: Decimal(string: "0.002")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: 200_000, gasPrice: 30_000_000_000)
        )
        let approveFee = Fee(
            Amount(with: .ethereum(testnet: false), type: .token(value: token), value: Decimal(string: "0.0005")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: 50_000, gasPrice: 20_000_000_000)
        )
        return try ApproveWithSwapFeeParameters.combinedFee(swapFee: swapFee, approveFee: approveFee)
    }
}

// MARK: - Recording doubles

private final class TransactionCreatorStub: TransactionCreator {
    var wallet = Wallet(
        blockchain: .ethereum(testnet: false),
        publicKey: .init(seedKey: Data(), derivationType: .none),
        addressesProvider: EmptyAddressesProvider()
    )

    var walletPublisher: AnyPublisher<Wallet, Never> {
        Just(wallet).eraseToAnyPublisher()
    }

    func validate(amount: Amount, fee: Fee) throws {}

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {}
}

private final class MultipleTransactionsSenderSpy: MultipleTransactionsSender {
    private(set) var sendCalls: [[Transaction]] = []
    private let result: Result<[TransactionSendResult], SendTxError>

    init(result: Result<[TransactionSendResult], SendTxError>) {
        self.result = result
    }

    func send(
        _ transactions: [Transaction],
        signer: TransactionSigner
    ) -> AnyPublisher<[TransactionSendResult], SendTxError> {
        sendCalls.append(transactions)
        return result.publisher.eraseToAnyPublisher()
    }
}

private final class GaslessSenderSpy: GaslessMultipleTransactionSending {
    private(set) var sendCalls: [[BSDKTransaction]] = []
    private let result: [TransactionDispatcherResult]

    init(result: [TransactionDispatcherResult]) {
        self.result = result
    }

    func send(transactions: [BSDKTransaction]) async throws -> [TransactionDispatcherResult] {
        sendCalls.append(transactions)
        return result
    }
}

private struct StubUniversalError: UniversalError {
    var errorCode: Int { 1 }
}
