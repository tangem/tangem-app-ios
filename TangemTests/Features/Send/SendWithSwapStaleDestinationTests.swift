//
//  SendWithSwapStaleDestinationTests.swift
//  TangemTests
//
//  Created for [REDACTED_INFO].
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress
import TangemFoundation
import TangemStaking
import Testing
@testable import BlockchainSdk
@testable import Tangem

private enum TestData {
    static let initialDestination = "rBndy89HdamJ3UHNekAS6ALjW9WoCE2W5s"
    static let updatedDestination = "rLHzPsX6oXkzU2qL12kHCH8G8cnZv1rBJh"
    static let destinationTag: UInt32 = 12886911
    static let amount = Decimal(string: "12.5")!
}

/// Guards [REDACTED_INFO]: in the transfer mode of Send-with-Swap (the receive token is the source token itself)
/// the destination and its memo reach `SwapModel` only after a one-second debounce. Tapping "Send" inside
/// that window used to dispatch the transaction the swap side had last built — with the previous address.
///
/// Also guards the memo itself: the transfer path used to build the transaction with `params: nil`, dropping
/// an entered XRP destination tag regardless of any race.
@Suite("Send with swap: stale destination")
struct SendWithSwapStaleDestinationTests {
    @Test("Send tapped inside the debounce window dispatches the destination on screen", .timeLimit(.minutes(1)))
    func destinationChangedRightBeforeSendIsDispatched() async throws {
        let harness = Harness()
        let model = try await harness.makeReadyToTransferModel()

        // The user edits the destination and taps "Send" before the one-second debounce fires.
        model.destinationDidChanged(harness.destination(TestData.updatedDestination))
        _ = try await model.performAction()

        let dispatched = try #require(harness.recorder.dispatchedTransactions.last)
        #expect(dispatched.destinationAddress == TestData.updatedDestination)
    }

    @Test("Destination tag entered inside the debounce window reaches the signed transaction", .timeLimit(.minutes(1)))
    func destinationTagIsDispatched() async throws {
        let harness = Harness()
        let model = try await harness.makeReadyToTransferModel()

        model.destinationAdditionalParametersDidChanged(harness.filledTagField())
        _ = try await model.performAction()

        let dispatched = try #require(harness.recorder.dispatchedTransactions.last)
        #expect((dispatched.params as? XRPTransactionParams)?.destinationTag == TestData.destinationTag)
    }
}

/// Guards [REDACTED_INFO]: the swap action begins before `SwapModel` raises its own sending flag, because the
/// price-impact gate first waits for the quote to settle. While that wait wasn't covered, the main button
/// stayed live and unspinnered and a second tap started a second send.
@Suite("Send with swap: screen lock")
struct SendWithSwapScreenLockTests {
    @Test("The screen is locked while the send waits for the quote to settle", .timeLimit(.minutes(1)))
    func screenIsLockedWhileTheQuoteSettles() async throws {
        let harness = SendWithSwapStaleDestinationTests.Harness()
        let model = try await harness.makeReadyToTransferModel()
        let processing = ActionInProcessingRecorder(model)

        let quoteGate = TestGate()
        await harness.holdQuoteUpdates(until: quoteGate)

        // The tap lands while the quote is being rebuilt, so the send parks until it settles.
        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: TestData.amount / 2, fiat: nil)))
        let send = Task { try await model.performAction() }

        try await waitUntil { processing.latest }
        #expect(harness.recorder.dispatchedTransactions.isEmpty)

        quoteGate.open()
        _ = try await send.value

        #expect(harness.recorder.dispatchedTransactions.count == 1)
    }
}

// MARK: - Waiting

/// Polls a condition instead of guessing a delay; the test's time limit bounds the wait.
private func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0 ..< 500 {
        if condition() {
            return
        }

        try await Task.sleep(for: .milliseconds(10))
    }

    throw SendWithSwapStaleDestinationTests.TimeoutError()
}

/// Keeps the latest `actionInProcessing` value, so a test can tell whether the screen is locked right now.
private final class ActionInProcessingRecorder {
    private let state = OSAllocatedUnfairLock(initialState: false)
    private var bag: AnyCancellable?

    init(_ model: SendWithSwapModel) {
        bag = model.actionInProcessing.sink { [state] isProcessing in
            state.withLock { $0 = isProcessing }
        }
    }

    var latest: Bool { state.withLock { $0 } }
}

// MARK: - Harness

private extension SendWithSwapStaleDestinationTests {
    struct Harness {
        let recorder = TransactionRecorder()

        private let blockchain: Blockchain = .xrp(curve: .secp256k1)
        private let expressManager = TransferExpressManagerStub()

        private var tokenItem: TokenItem { .blockchain(.init(blockchain, derivationPath: nil)) }

        /// Builds the composition model, selects the source token as the receive token (the transfer mode),
        /// enters an amount and waits until the swap side is ready to transfer to `initialDestination`.
        func makeReadyToTransferModel() async throws -> SendWithSwapModel {
            let sourceToken = makeSourceToken()
            let swapModel = makeSwapModel(sourceToken: sourceToken)
            let model = SendWithSwapModel(
                transferModel: makeTransferModel(),
                swapModel: swapModel,
                initialSourceToken: sourceToken,
                sendAlertBuilder: CommonSendAlertBuilder(),
                analyticsLogger: SendAnalyticsLoggerStub()
            )

            model.destinationDidChanged(destination(TestData.initialDestination))
            swapModel.update(receive: makeReceiveToken(address: TestData.initialDestination, tag: nil))
            model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: TestData.amount, fiat: nil)))

            try await waitForReadyToTransfer(swapModel)
            return model
        }

        func destination(_ address: String) -> SendDestination {
            SendDestination(value: .plain(address), source: .textField)
        }

        /// Parks the quote rebuilds that follow, so a test can hold one in flight.
        func holdQuoteUpdates(until gate: TestGate) async {
            await expressManager.hold(amountUpdatesUntil: gate)
        }

        func filledTagField() -> SendDestinationAdditionalField {
            .filled(
                type: .destinationTag,
                value: String(TestData.destinationTag),
                params: XRPTransactionParams(destinationTag: TestData.destinationTag)
            )
        }

        // MARK: - Model building

        private func makeSwapModel(sourceToken: SendSwapableToken) -> SwapModel {
            SwapModel(
                sourceToken: sourceToken,
                receiveToken: nil,
                expressManager: expressManager,
                swapRepository: SwapRepositoryStub(),
                expressPendingTransactionRepository: ExpressPendingTransactionRepositoryStub(),
                expressAPIProvider: ExpressAPIProviderStub(),
                expressUserWalletId: UserWalletId(value: Data([0x01])),
                analyticsLogger: SendAnalyticsLoggerStub(),
                autoupdatingTimer: AutoupdatingTimer(),
                pairUpdateHandler: TransferPairUpdateHandlerStub(expressManager: expressManager),
                balanceRestrictionFeatureChecker: TransferBalanceRestrictionCheckerStub(),
                shouldStartInitialLoading: false
            )
        }

        private func makeTransferModel() -> TransferModel {
            let model = TransferModel(
                userWalletId: UserWalletId(value: Data([0x01])),
                userToken: SendTransferableTokenStub(blockchain: blockchain, tokenFeeProvidersManager: makeFeeProvidersManager()),
                transactionSigner: TangemSignerStub(),
                feeIncludedCalculator: FeeIncludedCalculatorStub(),
                analyticsLogger: SendManagementModelAnalyticsLoggerStub(),
                sendAlertBuilder: CommonSendAlertBuilder(),
                predefinedValues: .init(tag: .empty(type: .destinationTag))
            )
            model.informationRelevanceService = InformationRelevanceServiceStub()
            return model
        }

        private func makeSourceToken() -> SendSwapableToken {
            TransferSwapableTokenStub(
                blockchain: blockchain,
                transactionCreator: PlainTransactionCreatorStub(sourceAddress: "rnWc1KoZY62gK7h8N8mdXfV3fWWEyzTJZG"),
                tokenFeeProvidersManager: makeFeeProvidersManager(),
                recorder: recorder
            )
        }

        private func makeReceiveToken(address: String, tag: String?) -> SendReceiveToken {
            CommonSendReceiveTokenFactory(tokenItem: tokenItem).makeSendReceiveToken(
                destination: SendReceiveTokenDestination(destination: .plain(address), destinationTag: tag)
            )
        }

        private func makeFeeProvidersManager() -> TokenFeeProvidersManager {
            let fee = Fee(Amount(with: blockchain, type: .coin, value: Decimal(string: "0.00001")!))
            let tokenFee = TokenFee(option: .market, tokenItem: tokenItem, value: .success(fee))
            return TokenFeeProvidersManagerMock(
                feeProvider: ControllableTokenFeeProviderStub(feeTokenItem: tokenItem, selectedTokenFee: tokenFee)
            )
        }

        // MARK: - Waiting

        private func waitForReadyToTransfer(_ swapModel: SwapModel) async throws {
            let states = SwapProvidersStateRecorder(swapModel)
            // Comfortably outlasts the one-second quote debounce on the amount path.
            for _ in 0 ..< 500 {
                if case .loaded(_, .readyToTransfer) = states.latest {
                    return
                }
                try await Task.sleep(for: .milliseconds(10))
            }

            throw TimeoutError()
        }
    }

    struct TimeoutError: Error {}
}

// MARK: - Transaction creator

private struct PlainTransactionCreatorStub: SendTransactionCreator {
    let sourceAddress: String

    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: "",
            contractAddress: nil,
            params: params
        )
    }
}

// MARK: - Source token

/// The source token of the transfer mode: it both signs the transaction and, being the same token, is what
/// the user picked as the receive token.
private final class TransferSwapableTokenStub: SendSourceTokenStub, SendSwapableToken {
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

    var isExemptFee: Bool { false }
    var swapAvailabilityProvider: any SwapAvailabilityProvider { AlwaysAvailableSwapAvailabilityProviderStub() }
    var sendingRestrictionsProvider: any SendingRestrictionsProvider { NoSendingRestrictionsProviderStub() }
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { NoReceivingRestrictionsProviderStub() }
    var supportedProvidersFilter: SupportedProvidersFilter { .byDifferentAddressExchangeSupport }
    var sendYieldModuleHelper: SendYieldModuleHelper? { nil }
    var operationType: ExpressOperationType { .swapAndSend }

    // MARK: - Reached only through the real express manager, which these tests replace

    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { fatalError("Unused in tests") }
    var balanceProvider: any TangemExpress.BalanceProvider { fatalError("Unused in tests") }
    var analyticsLogger: any TangemExpress.AnalyticsLogger { fatalError("Unused in tests") }
    var providerTransactionValidator: any ExpressProviderTransactionValidator { fatalError("Unused in tests") }
}

private struct AlwaysAvailableSwapAvailabilityProviderStub: SwapAvailabilityProvider {
    let isSwapAvailable = true
}

private struct NoSendingRestrictionsProviderStub: SendingRestrictionsProvider {
    var sendingRestrictions: SendingRestrictions? { nil }
}

private struct NoReceivingRestrictionsProviderStub: ReceivingRestrictionsProvider {
    var isRestrictionKnown: Bool { true }
    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction? { nil }
}

// MARK: - Express stubs

/// Mirrors `RegularSwapPairUpdateHandler` for a transfer pair: no loading type at all, so the invalidation
/// can't ride on the visible loading transition.
private final class TransferPairUpdateHandlerStub: SwapPairUpdateHandler {
    private let expressManager: TransferExpressManagerStub
    /// Models the network round-trip the rebuild takes, so a send that doesn't wait for it reads the
    /// previous state instead of the fresh one.
    private let loadDelay: Duration

    init(expressManager: TransferExpressManagerStub, loadDelay: Duration = .milliseconds(200)) {
        self.expressManager = expressManager
        self.loadDelay = loadDelay
    }

    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        nil
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        try await Task.sleep(for: loadDelay)
        _ = try await expressManager.update(pair: ExpressManagerSwappingPair(source: source, destination: destination))
        return .transfer
    }
}

private actor TransferExpressManagerStub: ExpressManager {
    private var currentPair: ExpressManagerSwappingPair?
    private var amountType: ExpressAmountType?
    private var amountUpdateGate: TestGate?

    func getCurrentPair() -> ExpressManagerSwappingPair? { currentPair }
    func getAmountType() -> ExpressAmountType? { amountType }

    func hold(amountUpdatesUntil gate: TestGate) {
        amountUpdateGate = gate
    }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState {
        currentPair = pair
        return .transfer
    }

    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState {
        self.amountType = amountType
        await amountUpdateGate?.wait()
        return .transfer
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState { .transfer }
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState { .transfer }
    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState { .transfer }

    func requestData() async throws -> ExpressTransactionData {
        fatalError("Unused in tests")
    }
}

private final class TransferBalanceRestrictionCheckerStub: SwapBalanceRestrictionFeatureChecker {
    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction { .none }
}
