//
//  TransferModelDestinationTagTests.swift
//  TangemTests
//
//  Created for [REDACTED_INFO].
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemStaking
import TangemUI
import Testing
@testable import BlockchainSdk
@testable import Tangem

private enum TestData {
    static let destinationTag: UInt32 = 12886911
    static let destinationAddress = "rBndy89HdamJ3UHNekAS6ALjW9WoCE2W5s"
}

/// Guards [REDACTED_INFO]: an XRP `DestinationTag` must not be dropped when the user taps "Send" while the
/// transaction validation triggered by entering the tag is still in flight (XRP validates over the network,
/// ~seconds). The send path must wait for that validation and dispatch the tag-carrying transaction.
///
/// The harness holds the first tag-carrying `createTransaction` open to model the "in-flight validation",
/// taps "Send" while it is held, then lets it complete and asserts the dispatched transaction carries the tag.
@Suite("TransferModel destination tag")
struct TransferModelDestinationTagTests {
    @Test("Signed transaction keeps the destination tag when Send is tapped mid-validation", .timeLimit(.minutes(1)))
    func destinationTagSurvivesSendDuringValidation() async throws {
        let harness = Harness()
        let model = harness.makeModel()

        // 1. The initial (tag-less) validation settles.
        let initial = try #require(await harness.awaitFirstBuiltTransaction(model))
        #expect((initial.params as? XRPTransactionParams)?.destinationTag == nil)

        // 2. The user enters the destination tag → its validation starts and is held mid-flight,
        //    modelling XRP's slow network validation.
        model.destinationAdditionalParametersDidChanged(harness.filledTagField())
        await harness.creator.waitUntilFirstTaggedBuildIsInFlight()

        // 3. The user taps "Send" while that validation is still in flight.
        async let sendResult = model.performAction()

        // Wait until the send flow actually starts, instead of a timing-based sleep that can flake under load.
        let sendStartedHolder = CancellableHolder()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sendStartedHolder.cancellable = model.actionInProcessing
                .filter { $0 }
                .first()
                .sink { _ in continuation.resume() }
        }

        // 4. The in-flight validation completes (the network returns). A correct send waited for it.
        await harness.creator.releaseHeldBuild()
        let result = try await sendResult
        #expect(result.hash.isEmpty == false)

        // 5. The transaction actually dispatched must carry the tag the user entered.
        let dispatched = try #require(harness.recorder.dispatchedTransactions.last)
        #expect((dispatched.params as? XRPTransactionParams)?.destinationTag == TestData.destinationTag)
    }
}

// MARK: - Harness

private extension TransferModelDestinationTagTests {
    final class Harness {
        let recorder = TransactionRecorder()
        let creator: ControlledSendTransactionCreator

        private let blockchain: Blockchain = .xrp(curve: .secp256k1)
        private let sourceToken: RecordingTransferableTokenStub

        init() {
            creator = ControlledSendTransactionCreator(sourceAddress: "rnWc1KoZY62gK7h8N8mdXfV3fWWEyzTJZG")

            let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
            let fee = Fee(Amount(with: blockchain, type: .coin, value: Decimal(string: "0.00001")!))
            let tokenFee = TokenFee(option: .market, tokenItem: tokenItem, value: .success(fee))
            let feeProvider = ControllableTokenFeeProviderStub(feeTokenItem: tokenItem, selectedTokenFee: tokenFee)

            sourceToken = RecordingTransferableTokenStub(
                blockchain: blockchain,
                transactionCreator: creator,
                tokenFeeProvidersManager: TokenFeeProvidersManagerMock(feeProvider: feeProvider),
                recorder: recorder
            )
        }

        func makeModel() -> TransferModel {
            let model = TransferModel(
                userWalletId: UserWalletId(value: Data([0x01])),
                userToken: sourceToken,
                transactionSigner: TangemSignerStub(),
                feeIncludedCalculator: FeeIncludedCalculatorStub(),
                analyticsLogger: SendManagementModelAnalyticsLoggerStub(),
                sendAlertBuilder: CommonSendAlertBuilder(),
                predefinedValues: .init(
                    destination: SendDestination(value: .plain(TestData.destinationAddress), source: .pasteButton),
                    tag: .empty(type: .destinationTag),
                    amount: SendAmount(type: .typical(crypto: Decimal(string: "47.202728")!, fiat: 50))
                )
            )
            model.informationRelevanceService = InformationRelevanceServiceStub()
            return model
        }

        func filledTagField() -> SendDestinationAdditionalField {
            .filled(
                type: .destinationTag,
                value: String(TestData.destinationTag),
                params: XRPTransactionParams(destinationTag: TestData.destinationTag)
            )
        }

        func awaitFirstBuiltTransaction(_ model: TransferModel) async -> BSDKTransaction? {
            let holder = CancellableHolder()
            return await withCheckedContinuation { (continuation: CheckedContinuation<BSDKTransaction?, Never>) in
                holder.cancellable = model.bsdkTransactionResultPublisher
                    .compactMap { result -> BSDKTransaction? in
                        guard let result else { return nil }
                        if case .success(let transaction) = result { return transaction }
                        return nil
                    }
                    .first()
                    .sink { continuation.resume(returning: $0) }
            }
        }
    }

    final class CancellableHolder {
        var cancellable: AnyCancellable?
    }
}

// MARK: - Controlled transaction creator

/// Builds transactions locally, but holds the **first** call that carries a destination tag open until
/// `releaseHeldBuild()` — modelling an XRP validation still performing its network round-trip.
private actor ControlledSendTransactionCreator: SendTransactionCreator {
    private let sourceAddress: String
    private var taggedCallCount = 0
    private var heldContinuation: CheckedContinuation<Void, Never>?
    private var isReleased = false

    private var firstTaggedBuildArrived = false
    private var firstTaggedBuildWaiters: [CheckedContinuation<Void, Never>] = []

    init(sourceAddress: String) {
        self.sourceAddress = sourceAddress
    }

    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        let hasTag = (params as? XRPTransactionParams)?.destinationTag != nil

        if hasTag {
            taggedCallCount += 1
            if taggedCallCount == 1 {
                firstTaggedBuildArrived = true
                firstTaggedBuildWaiters.forEach { $0.resume() }
                firstTaggedBuildWaiters.removeAll()

                if !isReleased {
                    await withCheckedContinuation { continuation in
                        heldContinuation = continuation
                    }
                }
            }
        }

        return Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: "",
            contractAddress: nil,
            params: params
        )
    }

    /// Suspends until the first tag-carrying validation has entered `createTransaction` and is being held.
    func waitUntilFirstTaggedBuildIsInFlight() async {
        if firstTaggedBuildArrived { return }
        await withCheckedContinuation { firstTaggedBuildWaiters.append($0) }
    }

    func releaseHeldBuild() {
        isReleased = true
        heldContinuation?.resume()
        heldContinuation = nil
    }
}

// MARK: - Recording dispatcher

private final class TransactionRecorder: @unchecked Sendable {
    private let state = OSAllocatedUnfairLock(initialState: [BSDKTransaction]())

    var dispatchedTransactions: [BSDKTransaction] { state.withLock { $0 } }

    func record(_ transaction: BSDKTransaction) {
        state.withLock { $0.append(transaction) }
    }
}

private struct RecordingTransactionDispatcher: TransactionDispatcher {
    let recorder: TransactionRecorder
    let hasNFCInteraction = false

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        if case .transfer(let bsdkTransaction) = transaction {
            recorder.record(bsdkTransaction)
        }

        return TransactionDispatcherResult(hash: "hash", url: nil, signerType: "test", currentHost: "test")
    }
}

private struct RecordingTransactionDispatcherProvider: TransactionDispatcherProvider {
    let recorder: TransactionRecorder

    func makeTransferTransactionDispatcher() -> TransactionDispatcher { RecordingTransactionDispatcher(recorder: recorder) }
    func makeApproveTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeApproveAndDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeCEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeYieldModuleTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
}

// MARK: - Misc stubs

private final class InformationRelevanceServiceStub: InformationRelevanceService {
    var isActual: Bool { true }
    func informationDidUpdated() {}
    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, Error> {
        Just(.ok).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private struct SendManagementModelAnalyticsLoggerStub: SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: SendTxError) {}
    func logTransactionSent(
        amount: SendAmount?,
        additionalField: SendDestinationAdditionalField?,
        fee: FeeOption,
        signerType: String,
        currentProviderHost: String,
        tokenFee: TokenFee?
    ) {}
}

// MARK: - SendTransferableToken stub

/// Reuses the shared `SendSourceTokenStub` for all the boilerplate and only injects the pieces this test
/// drives: a controllable transaction creator, a fee providers manager, and a recording dispatcher.
private final class RecordingTransferableTokenStub: SendSourceTokenStub, SendTransferableToken {
    let transactionValidator: SendTransactionValidator = SendTransactionValidatorStub()
    let transactionCreator: SendTransactionCreator
    let tokenFeeProvidersManager: TokenFeeProvidersManager

    private let recorder: TransactionRecorder

    init(
        blockchain: Blockchain,
        transactionCreator: SendTransactionCreator,
        tokenFeeProvidersManager: TokenFeeProvidersManager,
        recorder: TransactionRecorder
    ) {
        self.transactionCreator = transactionCreator
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
        self.recorder = recorder
        super.init(blockchain: blockchain)
    }

    override var transactionDispatcherProvider: any TransactionDispatcherProvider {
        RecordingTransactionDispatcherProvider(recorder: recorder)
    }
}
