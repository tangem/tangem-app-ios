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
    static let replacedDestinationTag: UInt32 = 42424242
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

    /// [REDACTED_INFO]: a build superseded by a newer one must leave no trace — neither the transaction it was
    /// building nor the fee-included flag it computed on the way.
    @Test("A superseded build neither dispatches nor publishes its fee-included flag", .timeLimit(.minutes(1)))
    func supersededBuildLeavesNoTrace() async throws {
        // Only the superseded build would report an included fee, so the flag tells whether it leaked.
        let feeIncludedCalculator = SequencedFeeIncludedCalculatorStub(results: [false, true, false])
        let harness = Harness(feeIncludedCalculator: feeIncludedCalculator)
        let model = harness.makeModel()
        let feeIncludedRecorder = FeeIncludedRecorder(model)

        _ = try #require(await harness.awaitFirstBuiltTransaction(model))

        // The user enters a tag; its build is held mid-flight and then superseded by a second one.
        model.destinationAdditionalParametersDidChanged(harness.filledTagField())
        await harness.creator.waitUntilFirstTaggedBuildIsInFlight()
        #expect(feeIncludedRecorder.values.contains(true) == false)

        model.destinationAdditionalParametersDidChanged(harness.filledTagField(value: TestData.replacedDestinationTag))
        await harness.creator.releaseHeldBuild()

        let result = try await model.performAction()
        #expect(result.hash.isEmpty == false)

        let dispatched = try #require(harness.recorder.dispatchedTransactions.last)
        #expect((dispatched.params as? XRPTransactionParams)?.destinationTag == TestData.replacedDestinationTag)
        #expect(feeIncludedRecorder.values.contains(true) == false)
    }

    /// [REDACTED_INFO]: the fee behind the built transaction went back to loading, so the built inputs no longer
    /// describe the screen. Nothing may be dispatched — the flow reports outdated information instead.
    @Test("A send is refused when the built transaction no longer matches the selected fee", .timeLimit(.minutes(1)))
    func sendIsRefusedWhenBuiltInputsAreStale() async throws {
        let harness = Harness()
        let model = harness.makeModel()

        _ = try #require(await harness.awaitFirstBuiltTransaction(model))

        // A reloading fee never reaches the rebuild — it is filtered out of the inputs — so the transaction
        // stays the one built from the previous fee.
        harness.feeProvider.set(selectedTokenFee: harness.loadingTokenFee())

        await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await model.performAction()
        }
        #expect(harness.recorder.dispatchedTransactions.isEmpty)
    }
}

// MARK: - Fee included recorder

private final class FeeIncludedRecorder {
    private let state = OSAllocatedUnfairLock(initialState: [Bool]())
    private var bag: AnyCancellable?

    init(_ model: TransferModel) {
        bag = model.isFeeIncludedPublisher.sink { [state] value in
            state.withLock { $0.append(value) }
        }
    }

    var values: [Bool] { state.withLock { $0 } }
}

private final class SequencedFeeIncludedCalculatorStub: FeeIncludedCalculator {
    private let state: OSAllocatedUnfairLock<(results: [Bool], index: Int)>

    init(results: [Bool]) {
        state = OSAllocatedUnfairLock(initialState: (results: results, index: 0))
    }

    func shouldIncludeFee(_ fee: Fee, into amount: Amount) -> Bool {
        state.withLock { state in
            defer { state.index += 1 }
            return state.results.indices.contains(state.index) ? state.results[state.index] : false
        }
    }
}

// MARK: - Harness

private extension TransferModelDestinationTagTests {
    final class Harness {
        let recorder = TransactionRecorder()
        let creator: ControlledSendTransactionCreator
        let feeProvider: ControllableTokenFeeProviderStub

        private let blockchain: Blockchain = .xrp(curve: .secp256k1)
        private let tokenItem: TokenItem
        private let sourceToken: RecordingTransferableTokenStub
        private let feeIncludedCalculator: FeeIncludedCalculator

        init(feeIncludedCalculator: FeeIncludedCalculator = FeeIncludedCalculatorStub()) {
            self.feeIncludedCalculator = feeIncludedCalculator
            creator = ControlledSendTransactionCreator(sourceAddress: "rnWc1KoZY62gK7h8N8mdXfV3fWWEyzTJZG")

            let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
            self.tokenItem = tokenItem
            let fee = Fee(Amount(with: blockchain, type: .coin, value: Decimal(string: "0.00001")!))
            let tokenFee = TokenFee(option: .market, tokenItem: tokenItem, value: .success(fee))
            let feeProvider = ControllableTokenFeeProviderStub(feeTokenItem: tokenItem, selectedTokenFee: tokenFee)
            self.feeProvider = feeProvider

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
                feeIncludedCalculator: feeIncludedCalculator,
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

        func loadingTokenFee() -> TokenFee {
            TokenFee(option: .market, tokenItem: tokenItem, value: .loading)
        }

        func filledTagField(value: UInt32 = TestData.destinationTag) -> SendDestinationAdditionalField {
            .filled(
                type: .destinationTag,
                value: String(value),
                params: XRPTransactionParams(destinationTag: value)
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
