//
//  LendingDepositPreparationSenderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
import TangemFoundation
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending deposit preparation sender", .timeLimit(.minutes(1)))
struct LendingDepositPreparationSenderTests {
    private static let blockchain = BlockchainSdk.Blockchain.ethereum(testnet: false)
    private static let owner = "0x3333333333333333333333333333333333333333"
    private static let module = "0x1111111111111111111111111111111111111111"
    private static let factory = "0x2222222222222222222222222222222222222222"
    private static let depositData = Data([0x09, 0x21, 0xEC, 0xD4])
    private static let gas = TransferPreparationGas(preparation: 200_000, mainCall: 300_000)

    @Test("The preparation and the deposit are signed together, each with its share of the gas", arguments: [false, true])
    func sendsBothInOneCall(isEIP1559: Bool) async throws {
        let sender = MultipleTransactionsSenderSpy(result: .success([Self.sendResult("0xprep"), Self.sendResult("0xdeposit")]))
        let updates = OSAllocatedUnfairLock(initialState: 0)
        let sut = makeSUT(sender: sender, onSent: { updates.withLock { $0 += 1 } })

        let result = try await sut.send(mainCall: Self.deposit(parameters: Self.parameters(isEIP1559: isEIP1559)), gas: Self.gas)

        let sent = try #require(sender.sendCalls.first)
        #expect(sender.sendCalls.count == 1)
        #expect(sent.count == 2)
        #expect(sent[0].destinationAddress == Self.factory)
        #expect(sent[0].amount.value == 0)
        #expect(Self.gasLimit(of: sent[0]) == 200_000)
        #expect(sent[1].destinationAddress == Self.module)
        #expect(sent[1].amount.value == Decimal(5) / 10)
        #expect(Self.gasLimit(of: sent[1]) == 300_000)
        #expect((sent[1].params as? EthereumTransactionParams)?.data == Self.depositData)
        #expect(result.hash == "0xdeposit")
        #expect(updates.withLock { $0 } == 1)
    }

    @Test("A failed send is reported for the deposit, and the wallet still refreshes in case the preparation went out")
    func failedSend() async throws {
        let sender = MultipleTransactionsSenderSpy(result: .failure(SendTxError(error: SendErrorStub())))
        let updates = OSAllocatedUnfairLock(initialState: 0)
        let sut = makeSUT(sender: sender, onSent: { updates.withLock { $0 += 1 } })

        await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await sut.send(mainCall: Self.deposit(parameters: Self.parameters(isEIP1559: false)), gas: Self.gas)
        }
        #expect(updates.withLock { $0 } == 1)
    }

    @Test("A custom fee with a gas limit below the pair's or a pinned nonce is refused before signing, with the reason", arguments: CustomFee.allCases)
    func customFeeIsRefused(fee: CustomFee) async {
        let sender = MultipleTransactionsSenderSpy(result: .success([]))
        let sut = makeSUT(sender: sender, onSent: {})

        let error = await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await sut.send(mainCall: Self.deposit(parameters: fee.parameters), gas: Self.gas)
        }

        #expect(error.flatMap(Self.reason) == fee.reason.errorDescription)
        #expect(sender.sendCalls.isEmpty)
    }

    @Test("A custom gas limit above the pair's keeps the preparation's share and gives the rest to the deposit")
    func higherGasLimitGoesToDeposit() async throws {
        let sender = MultipleTransactionsSenderSpy(result: .success([Self.sendResult("0xprep"), Self.sendResult("0xdeposit")]))
        let sut = makeSUT(sender: sender, onSent: {})

        _ = try await sut.send(mainCall: Self.deposit(parameters: EthereumLegacyFeeParameters(gasLimit: 600_000, gasPrice: 10_000_000_000)), gas: Self.gas)

        let sent = try #require(sender.sendCalls.first)
        #expect(sent.map(Self.gasLimit) == [200_000, 400_000])
    }

    @Test("A deposit while an earlier transaction of the wallet is still in the mempool is refused and nothing is signed")
    func pendingTransactionBlocksPair() async {
        let sender = MultipleTransactionsSenderSpy(result: .success([]))
        let sut = makeSUT(sender: sender, hasPendingTransactions: { true }, onSent: {})

        let error = await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await sut.send(mainCall: Self.deposit(parameters: Self.parameters(isEIP1559: false)), gas: Self.gas)
        }

        #expect(error.flatMap(Self.reason) == LendingTransactionError.previousTransactionPending.errorDescription)
        #expect(sender.sendCalls.isEmpty)
    }

    @Test("A pair that can't be built is reported as a failed deposit, so the support pop-up shows, and nothing is signed")
    func buildFailure() async {
        let sender = MultipleTransactionsSenderSpy(result: .success([]))
        let updates = OSAllocatedUnfairLock(initialState: 0)
        let sut = makeSUT(
            sender: sender,
            transactionCreator: WalletTransactionCreatorStub(blockchain: Self.blockchain, validationError: SendErrorStub()),
            onSent: { updates.withLock { $0 += 1 } }
        )

        let error = await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await sut.send(mainCall: Self.deposit(parameters: Self.parameters(isEIP1559: false)), gas: Self.gas)
        }

        #expect(error.map(Self.isSendFailure) == true)
        #expect(sender.sendCalls.isEmpty)
        #expect(updates.withLock { $0 } == 0)
    }

    @Test("A demo wallet shows the demo pop-up instead of signing")
    func demoWallet() async {
        let sender = MultipleTransactionsSenderSpy(result: .success([]))
        let sut = makeSUT(sender: sender, isDemo: true, onSent: {})

        let error = await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await sut.send(mainCall: Self.deposit(parameters: Self.parameters(isEIP1559: false)), gas: Self.gas)
        }

        #expect(error.map(Self.isDemoAlert) == true)
        #expect(sender.sendCalls.isEmpty)
    }
}

// MARK: - Helpers

extension LendingDepositPreparationSenderTests {
    enum CustomFee: CaseIterable {
        case smallerGasLimit
        case pinnedNonce

        var parameters: any EthereumFeeParameters {
            switch self {
            case .smallerGasLimit: EthereumLegacyFeeParameters(gasLimit: 400_000, gasPrice: 10_000_000_000)
            case .pinnedNonce: EthereumLegacyFeeParameters(gasLimit: 500_000, gasPrice: 10_000_000_000, nonce: 7)
            }
        }

        var reason: LendingTransactionError {
            switch self {
            case .smallerGasLimit: .gasLimitTooLow(required: 500_000)
            case .pinnedNonce: .customNonce
            }
        }
    }
}

private extension LendingDepositPreparationSenderTests {
    static func reason(_ error: TransactionDispatcherResult.Error) -> String? {
        guard case .loadTransactionInfo(let error) = error else {
            return nil
        }

        return error.errorDescription
    }

    static func isSendFailure(_ error: TransactionDispatcherResult.Error) -> Bool {
        if case .sendTxError = error { true } else { false }
    }

    static func isDemoAlert(_ error: TransactionDispatcherResult.Error) -> Bool {
        if case .demoAlert = error { true } else { false }
    }

    static func parameters(isEIP1559: Bool) -> any EthereumFeeParameters {
        isEIP1559
            ? EthereumEIP1559FeeParameters(gasLimit: 500_000, maxFeePerGas: 20_000_000_000, priorityFee: 1_000_000_000)
            : EthereumLegacyFeeParameters(gasLimit: 500_000, gasPrice: 10_000_000_000)
    }

    static func sendResult(_ hash: String) -> TransactionSendResult {
        TransactionSendResult(hash: hash, currentProviderHost: "test")
    }

    static func deposit(parameters: any EthereumFeeParameters) -> BSDKTransaction {
        BSDKTransaction(
            amount: Amount(with: blockchain, type: .coin, value: Decimal(5) / 10),
            fee: Fee(Amount(with: blockchain, type: .coin, value: Decimal(5) / 1000), parameters: parameters),
            sourceAddress: owner,
            destinationAddress: module,
            changeAddress: owner,
            params: EthereumTransactionParams(data: depositData)
        )
    }

    static func gasLimit(of transaction: BSDKTransaction) -> BigUInt? {
        (transaction.fee.parameters as? any EthereumFeeParameters)?.gasLimit
    }

    func makeSUT(
        sender: MultipleTransactionsSenderSpy,
        isDemo: Bool = false,
        transactionCreator: TransactionCreator = WalletTransactionCreatorStub(blockchain: blockchain),
        hasPendingTransactions: @escaping () async throws -> Bool = { false },
        onSent: @escaping () -> Void
    ) -> LendingDepositPreparationSender {
        LendingDepositPreparationSender(
            preparationCall: TransferPreparationCall(destination: Self.factory, value: 0, data: Data([0xCB, 0xED, 0xA1, 0x4C])),
            blockchain: Self.blockchain,
            isDemo: isDemo,
            transactionCreator: transactionCreator,
            transactionsSender: sender,
            signer: TangemSignerStub(),
            gasEstimator: GasEstimatorStub(),
            hasPendingTransactions: hasPendingTransactions,
            onSent: onSent
        )
    }
}

// MARK: - Stubs

private struct SendErrorStub: UniversalError {
    var errorCode: Int { 1 }
}

private struct GasEstimatorStub: LendingDepositGasEstimating {
    func gas(preparation: TransferPreparationCall, deposit: TransferPreparationCall) async -> TransferPreparationGas? {
        TransferPreparationGas(preparation: 200_000, mainCall: 300_000)
    }
}
