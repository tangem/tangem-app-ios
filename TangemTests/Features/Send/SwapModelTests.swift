//
//  SwapModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import TangemPay
import Testing
import TangemTestKit
@testable import TangemExpress
@testable import Tangem

@Suite("SwapModel")
final class SwapModelTests: LeakTrackingTestSuite {
    @Test("SwapModel deallocates properly without memory leaks")
    func swapModelDeallocatesProperly() async {
        let sut = makeSUT()
        trackForMemoryLeaks(sut)

        _ = sut.sourceToken
        _ = sut.receiveToken
        _ = sut.statePublisher
    }

    // MARK: - [REDACTED_INFO]: pair reconciliation

    @Test("A quote request reconciles a missing pair instead of stranding on .idle")
    func amountEditReconcilesMissingPair() async throws {
        let manager = ExpressManagerStub()
        let handler = ReconcilingPairHandlerStub(expressManager: manager)
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: handler
        )
        let recorder = StateRecorder(sut)

        let baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        let state = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        #expect(state.isLoaded)
        #expect(await manager.currentPair != nil)
        #expect(handler.callCount == 1)
        #expect(sut.sourceAmount.value?.crypto == 1)
    }

    @Test("MAX during an in-flight uncached pair load recovers ([REDACTED_INFO] repro)")
    func maxDuringPairLoadRecovers() async throws {
        let manager = ExpressManagerStub()
        let handler = ReconcilingPairHandlerStub(expressManager: manager, loadDelay: .milliseconds(200))
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            expressManager: manager,
            pairUpdateHandler: handler
        )
        let recorder = StateRecorder(sut)

        let baseline = recorder.count
        // Pick a receive token (starts a pair load) and immediately tap MAX (cancels that pair load).
        sut.update(receive: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)))
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 22.619112, fiat: nil)))

        let state = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        #expect(state.isLoaded)
        #expect(await manager.currentPair != nil)
        #expect(sut.sourceAmount.value?.crypto == 22.619112)
    }

    @Test("An already-synchronized pair is not reloaded by a later quote request")
    func inSyncPairIsNotReloaded() async throws {
        let manager = ExpressManagerStub()
        let handler = ReconcilingPairHandlerStub(expressManager: manager)
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            expressManager: manager,
            pairUpdateHandler: handler
        )
        let recorder = StateRecorder(sut)

        var baseline = recorder.count
        sut.update(receive: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        #expect(handler.callCount == 1)

        baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        // The pair is already in sync, so reconciliation must not trigger another pair load.
        #expect(handler.callCount == 1)
    }

    @Test("A failed pair load is recovered by a subsequent quote request (never blank .idle)")
    func failedPairLoadRecoversOnAmountEdit() async throws {
        let manager = ExpressManagerStub()
        let handler = ReconcilingPairHandlerStub(expressManager: manager, failFirstCalls: 1)
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            expressManager: manager,
            pairUpdateHandler: handler
        )
        let recorder = StateRecorder(sut)

        var baseline = recorder.count
        sut.update(receive: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isFailure }

        baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        let state = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        #expect(state.isLoaded)
        #expect(await manager.currentPair != nil)
    }

    @Test("Balance restriction defers the pair load until it is lifted ([REDACTED_INFO] / S10)")
    func restrictionDefersPairLoad() async throws {
        let manager = ExpressManagerStub()
        let handler = ReconcilingPairHandlerStub(expressManager: manager)
        let restriction = ConfigurableBalanceRestrictionChecker(isRestricted: true)
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: handler,
            balanceRestrictionChecker: restriction
        )
        let recorder = StateRecorder(sut)

        var baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        // While restricted the pair must never be loaded.
        #expect(await manager.currentPair == nil)

        restriction.isRestricted = false
        baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 2, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        // Restriction lifted: the next quote request reconciles the deferred pair.
        #expect(await manager.currentPair != nil)
    }

    // MARK: - [REDACTED_INFO]: autoupdate cancellation after send

    @Test("A cancelled update cannot push a quote amount onto the finish screen ([REDACTED_INFO])")
    func cancelledUpdateDoesNotPushComplementaryAmount() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager
        )
        _ = try await manager.update(amountType: .from(5))

        // Any loaded state carrying a quote works — only `loadedState.quote` is read.
        let quote = SwapModel.Quote(fromAmount: 5, expectAmount: 7, highPriceImpact: nil)
        let state = SwapModel.ProvidersState.loaded(
            .swap(selected: .none, providers: .empty),
            state: .restriction(.hasPendingTransaction, quote: quote)
        )

        // Stands in for the update task that `stopAutoupdating()` cancels while it is
        // suspended on `expressManager.getAmountType()` inside `updateComplementaryAmount`.
        let task = Task { try await sut.updateComplementaryAmount(state: state) }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        // The receive amount stays empty: the late quote never reaches the finish screen.
        #expect(sut.receiveAmount.value == nil)
    }

    // MARK: - [REDACTED_INFO]: account funding flows

    @Test("Add funds auto-resolves the source token when the destination is fixed")
    func addFundsResolvesSourceToken() async throws {
        let resolvedSource = SwapableTokenStub(blockchain: .ethereum(testnet: false))
        let sut = makeSUT(
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            sourceTokenResolver: SourceTokenResolverStub(source: resolvedSource),
            shouldStartInitialLoading: true
        )

        // initialLoading runs on a detached task; wait for the resolved source to land.
        for _ in 0 ..< 500 {
            if case .success = sut.sourceToken { break }
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(sut.sourceToken.value?.tokenItem == resolvedSource.tokenItem)
    }

    // MARK: - [REDACTED_INFO]: deferred pair resolution

    @Test("Receive selector unblocks while deferred pair resolution is still in flight ([REDACTED_INFO])")
    func receiveSelectorUnblocksDuringDeferredPairResolution() async throws {
        let sourceToken = SwapableTokenStub(blockchain: .ethereum(testnet: false))
        let resolver = MainSwapSourceResolver(
            userWalletModel: PendingResolutionUserWalletModelStub(),
            swapAvailabilityChecker: SwapAvailabilityCheckerStub()
        )
        // The SUT is not leak-tracked here: the suspended resolver keeps the initial-loading
        // task (and therefore the model) alive until the stub's publishers would emit.
        let sut = makeSUT(
            sourceToken: sourceToken,
            sourceTokenResolver: resolver,
            shouldStartInitialLoading: true
        )

        let error = try await waitForReceiveTokenFailure(sut)
        #expect(error as? SwapModel.SwapModelError == .tokenSelectionRequired)
        // The resolver never resumed, so the pre-selected source must stay intact.
        #expect(sut.sourceToken.value?.tokenItem == sourceToken.tokenItem)
    }

    // MARK: - Destination re-resolution

    @Test("A source change re-resolves the destination")
    func sourceChangeReresolvesDestination() {
        let usdcDestination = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDC", contract: "0xUSDC"))
        let usdtDestination = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDT", contract: "0xUSDT"))
        let resolver = DestinationTokenResolverStub(destination: usdtDestination)
        let sut = makeSUT(receiveToken: usdcDestination, destinationTokenResolver: resolver)

        sut.update(source: SwapableTokenStub(tokenItem: .accountToken(symbol: "USDT", contract: "0xUSDT")))

        #expect(sut.receiveToken.value?.tokenItem == usdtDestination.tokenItem)
    }

    @Test("The resolved destination replaces the installed one even when it carries the same asset")
    func destinationIsReplacedWhenResolvedTokenIsSameAsset() {
        let installedDestination = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDC", contract: "0xUSDC"))
        // Same asset, different token: only the object identity tells them apart, exactly as two
        // account tokens sharing a currency but sending to different addresses would.
        let resolvedDestination = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDC", contract: "0xUSDC"))
        let resolver = DestinationTokenResolverStub(destination: resolvedDestination)
        let sut = makeSUT(receiveToken: installedDestination, destinationTokenResolver: resolver)

        sut.update(source: SwapableTokenStub(blockchain: .ethereum(testnet: false)))

        #expect(sut.receiveToken.value as AnyObject === resolvedDestination)
    }

    @Test("Without a destination resolver a source change leaves the destination untouched")
    func sourceChangeWithoutResolverKeepsDestination() {
        let receive = ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        let sut = makeSUT(receiveToken: receive)

        sut.update(source: SwapableTokenStub(blockchain: .ethereum(testnet: false)))

        #expect(sut.receiveToken.value?.tokenItem == receive.tokenItem)
    }
}

// MARK: - Helpers

private extension SwapModelTests {
    func makeSUT(
        sourceToken: SendSwapableToken? = nil,
        receiveToken: SendReceiveToken? = nil,
        expressManager: ExpressManager = ExpressManagerStub(),
        pairUpdateHandler: SwapPairUpdateHandler = SwapPairUpdateHandlerStub(),
        balanceRestrictionChecker: SwapBalanceRestrictionFeatureChecker = SwapBalanceRestrictionFeatureCheckerStub(),
        sourceTokenResolver: (any SwapSourceTokenResolver)? = nil,
        destinationTokenResolver: (any SwapDestinationTokenResolver)? = nil,
        shouldStartInitialLoading: Bool = false
    ) -> SwapModel {
        let model = SwapModel(
            sourceToken: sourceToken,
            receiveToken: receiveToken,
            expressManager: expressManager,
            swapRepository: SwapRepositoryStub(),
            expressPendingTransactionRepository: ExpressPendingTransactionRepositoryStub(),
            expressAPIProvider: ExpressAPIProviderStub(),
            expressUserWalletId: UserWalletId(value: Data()),
            analyticsLogger: SendAnalyticsLoggerStub(),
            autoupdatingTimer: AutoupdatingTimer(),
            pairUpdateHandler: pairUpdateHandler,
            balanceRestrictionFeatureChecker: balanceRestrictionChecker,
            sourceTokenResolver: sourceTokenResolver,
            destinationTokenResolver: destinationTokenResolver,
            shouldStartInitialLoading: shouldStartInitialLoading
        )

        // The production factory always injects the updater; the model unwraps it implicitly
        // (e.g. on pair reversal), so tests must too. The updater keeps weak references — its
        // no-op behavior here is exactly what these tests want.
        model.externalAmountUpdater = SendAmountExternalUpdater(
            viewModel: ExternalUpdatableViewModelStub(),
            interactor: SendAmountInteractorStub()
        )

        return model
    }

    /// Waits for a state published *after* `baseline` that satisfies `predicate`. Capturing the baseline
    /// count before the triggering action makes the wait robust for back-to-back tasks, where the
    /// `CurrentValueSubject` already holds a stale terminal state from the previous task.
    func waitForNewState(
        _ recorder: StateRecorder,
        since baseline: Int,
        where predicate: @escaping (SwapModel.ProvidersState) -> Bool
    ) async throws -> SwapModel.ProvidersState {
        let pollInterval: Duration = .milliseconds(10)
        // ~5s budget: must comfortably outlast the amount path's 1s quote debounce.
        let maxAttempts = 500

        for _ in 0 ..< maxAttempts {
            if recorder.count > baseline, let latest = recorder.latest, predicate(latest) {
                return latest
            }
            try await Task.sleep(for: pollInterval)
        }

        throw TimeoutError()
    }

    /// Waits until the receive token leaves `.loading` and returns the failure. Under the pre-fix
    /// ordering (selection state sent only after the resolver await) this never happens with a
    /// suspended resolver, so the timeout is the regression signal.
    func waitForReceiveTokenFailure(_ sut: SwapModel) async throws -> any Error {
        let pollInterval: Duration = .milliseconds(10)
        let maxAttempts = 500

        for _ in 0 ..< maxAttempts {
            if case .failure(let error) = sut.receiveToken {
                return error
            }
            try await Task.sleep(for: pollInterval)
        }

        throw TimeoutError()
    }

    struct TimeoutError: Error {}
}

// MARK: - StateRecorder

private final class StateRecorder {
    private let states = OSAllocatedUnfairLock(initialState: [SwapModel.ProvidersState]())
    private var bag: AnyCancellable?

    init(_ model: SwapModel) {
        bag = model.statePublisher.sink { [states] state in
            states.withLock { $0.append(state) }
        }
    }

    var count: Int { states.withLock { $0.count } }
    var latest: SwapModel.ProvidersState? { states.withLock { $0.last } }
}

// MARK: - Stubs

private actor ExpressManagerStub: ExpressManager {
    private(set) var currentPair: ExpressManagerSwappingPair?
    private var amountType: ExpressAmountType?
    private(set) var updateAmountTypeCallCount = 0

    func getCurrentPair() -> ExpressManagerSwappingPair? { currentPair }
    func getAmountType() -> ExpressAmountType? { amountType }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState {
        currentPair = pair
        amountType = nil
        return state()
    }

    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState {
        updateAmountTypeCallCount += 1
        self.amountType = amountType
        return state()
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState {
        state()
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState {
        state()
    }

    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState {
        state()
    }

    /// Mirrors the real manager: no pair ⇒ `.idle` (the degenerate state behind the bug),
    /// a set pair ⇒ a loadable `.swap` state that `SwapModel` maps to `.loaded`.
    private func state() -> ExpressManagerState {
        currentPair == nil ? .idle : .swap(selected: .none, providers: .empty)
    }

    func requestData() async throws -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "",
            extraDestinationId: nil,
            txValue: .zero,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }
}

private final class SwapRepositoryStub: SwapRepository {
    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency], userWalletInfo: UserWalletInfo) async throws {}
    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws {}
    func getAvailableProvidersIds(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType?) async -> [ExpressProvider.Id] { [] }
    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair] { [] }
    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair] { [] }
    func providers(userWalletInfo: UserWalletInfo) async throws -> [ExpressProvider] { [] }

    // ExpressRepository
    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {}
    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] { [] }
}

private final class ExpressPendingTransactionRepositoryStub: ExpressPendingTransactionRepository {
    var transactions: [ExpressPendingTransactionRecord] { [] }
    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { .just(output: []) }
    func updateItems(_ items: [ExpressPendingTransactionRecord]) {}
    func swapTransactionDidSend(_ transaction: SentSwapTransactionData) {}
    func hideSwapTransaction(with id: String) {}
}

private final class SwapPairUpdateHandlerStub: SwapPairUpdateHandler {
    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        .idle
    }
}

private final class SwapBalanceRestrictionFeatureCheckerStub: SwapBalanceRestrictionFeatureChecker {
    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction { .none }
}

private final class ConfigurableBalanceRestrictionChecker: SwapBalanceRestrictionFeatureChecker {
    var isRestricted: Bool

    init(isRestricted: Bool) {
        self.isRestricted = isRestricted
    }

    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction {
        isRestricted ? .hideProviders : .none
    }
}

/// Pair-update handler that reconciles into a shared `ExpressManagerStub`, mirroring the real handler:
/// it (optionally slowly, cancellably) loads the pair and calls `update(pair:)` so the manager becomes
/// "has pair". `loadDelay` reproduces the ~1s uncached fetch window; `failFirstCalls` reproduces a failed load.
private final class ReconcilingPairHandlerStub: SwapPairUpdateHandler {
    private let expressManager: ExpressManagerStub
    private let loadDelay: Duration?
    private let state: OSAllocatedUnfairLock<State>

    private struct State {
        var callCount = 0
        var remainingFailures: Int
    }

    init(expressManager: ExpressManagerStub, loadDelay: Duration? = nil, failFirstCalls: Int = 0) {
        self.expressManager = expressManager
        self.loadDelay = loadDelay
        state = OSAllocatedUnfairLock(initialState: State(remainingFailures: failFirstCalls))
    }

    var callCount: Int { state.withLock { $0.callCount } }

    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        let shouldFail = state.withLock { state -> Bool in
            state.callCount += 1
            guard state.remainingFailures > 0 else { return false }
            state.remainingFailures -= 1
            return true
        }

        if let loadDelay {
            try await Task.sleep(for: loadDelay)
        }

        if shouldFail {
            throw SwapPairHandlerError.failed
        }

        let pair = ExpressManagerSwappingPair(source: source, destination: destination)
        return try await expressManager.update(pair: pair)
    }
}

private enum SwapPairHandlerError: Error {
    case failed
}

private final class ReceiveTokenStub: SendReceiveToken {
    let tokenItem: TokenItem

    init(blockchain: Blockchain) {
        tokenItem = .blockchain(.init(blockchain, derivationPath: nil))
    }

    var isCustom: Bool { false }
    var fiatItem: FiatItem { FiatItem(iconURL: nil, currencyCode: "USD") }
    var destination: SendReceiveTokenDestination? { nil }
}

private final class DestinationTokenResolverStub: SwapDestinationTokenResolver {
    private let destination: SendReceiveToken

    init(destination: SendReceiveToken) {
        self.destination = destination
    }

    func resolveDestination(for source: SendSwapableToken) -> SendReceiveToken {
        destination
    }
}

private final class SourceTokenResolverStub: SwapSourceTokenResolver {
    private let source: SendSwapableToken?

    init(source: SendSwapableToken?) {
        self.source = source
    }

    func resolve() async -> SendSwapableToken? {
        source
    }
}

// MARK: - External amount updater stubs

private final class ExternalUpdatableViewModelStub: SendAmountExternalUpdatableViewModel {
    func externalUpdate(amount: SendAmount?) {}
}

private final class SendAmountInteractorStub: SendAmountInteractor {
    var isReceiveTokenSelectionAvailable: Bool { false }
    var sourceFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { .just(output: nil) }
    var receiveFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { .just(output: nil) }
    var isValidPublisher: AnyPublisher<Bool, Never> { .just(output: true) }
    var sourceTokenPublisher: AnyPublisher<LoadingResult<any SendSourceToken, any Error>, Never> { .empty }
    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { .empty }
    var receivedTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> { .empty }
    var receivedTokenAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { .empty }
    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> { .just(output: nil) }
    var isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never> { .just(output: false) }

    func update(sourceAmount: Decimal?) throws -> SendAmount? { nil }
    func update(sourceCryptoAmount: Decimal?) throws -> SendAmount? { nil }
    func update(sourceType: SendAmountCalculationType) throws -> SendAmount? { nil }
    func updateToMaxAmount() throws -> SendAmount { SendAmount(type: .typical(crypto: 0, fiat: 0)) }
    func update(receiveAmount: Decimal?) -> SendAmount? { nil }
    func update(receiveType: SendAmountCalculationType) {}
    func validateExternalSourceAmount(_ amount: SendAmount?) {}
    func userDidRequestClearReceiveToken() {}
}

// MARK: - Deferred pair resolution stubs

private struct SwapAvailabilityCheckerStub: SwapAvailabilityChecker {
    func isSwapAvailable(walletModel: any WalletModel) -> Bool { true }
}

/// A wallet whose account models never arrive, keeping `MainSwapSourceResolver.resolve()`
/// suspended — the unit-test analogue of balances that never finish loading ([REDACTED_INFO]).
private final class PendingResolutionUserWalletModelStub: UserWalletModelMock {
    private let pendingAccountModelsManager = PendingAccountModelsManagerStub()

    override var accountModelsManager: AccountModelsManager { pendingAccountModelsManager }
    override var config: UserWalletConfig { UserWalletConfigStub() }
    override var signer: TangemSigner { TangemSignerStub() }
}

private final class PendingAccountModelsManagerStub: AccountModelsManager {
    var canAddCryptoAccounts: Bool { false }
    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
    var accountModels: [AccountModel] { [] }
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { Empty(completeImmediately: false).eraseToAnyPublisher() }
    var totalCryptoAccountsCountPublisher: AnyPublisher<Int, Never> { Empty().eraseToAnyPublisher() }

    func addCryptoAccount(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountOperationResult { .none }
    func addJointAccount(context: JointAccountCreationContext) async throws(AccountEditError) {}
    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] { [] }
    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult { .none }
    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws {}
    func dispose() {}
    func acceptTangemPayOffer(authorizingInteractor: any TangemPayAuthorizing) async {}
}
