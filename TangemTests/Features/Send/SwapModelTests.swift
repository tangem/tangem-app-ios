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
    private let jointAccountDelegate = JointAccountModelDelegateMock()

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
        let recorder = SwapProvidersStateRecorder(sut)

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
        let recorder = SwapProvidersStateRecorder(sut)

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
        let recorder = SwapProvidersStateRecorder(sut)

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
        let recorder = SwapProvidersStateRecorder(sut)

        var baseline = recorder.count
        sut.update(receive: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isFailure }

        baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        let state = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        #expect(state.isLoaded)
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
        let gate = TestGate()
        await manager.holdAmountTypeReads(behind: gate)
        let task = Task { try await sut.updateComplementaryAmount(state: state) }
        task.cancel()
        gate.open()

        await #expect(throws: CancellationError.self) { try await task.value }
        // The receive amount stays empty: the late quote never reaches the finish screen.
        #expect(sut.receiveAmount.value == nil)
    }

    // MARK: - [REDACTED_INFO]: stale-input dispatch

    @Test("A send is refused when the settled update never described the current inputs", .timeLimit(.minutes(1)))
    func sendIsRefusedAfterSupersededUpdate() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: 0) { $0.isLoaded }

        // The recalculation for the new amount ends as cancelled, so no state is marked as built from it.
        await manager.failNextAmountUpdate(with: CancellationError())
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 2, fiat: nil)))

        await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await sut.send()
        }
    }

    @Test("The high price impact gate waits for the pending update to settle", .timeLimit(.minutes(1)))
    func impactGateWaitsForPendingUpdate() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: 0) { $0.isLoaded }

        await manager.holdNextAmountUpdate()
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 2, fiat: nil)))

        let hasReturned = OSAllocatedUnfairLock(initialState: false)
        let gate = Task { [weak sut] in
            _ = await sut?.settledHighPriceImpact()
            hasReturned.withLock { $0 = true }
        }

        // A quote still in flight must not read as "no impact": the gate keeps waiting instead of waving
        // the send through. The wait outlasts the 1s debounce on the amount path.
        try await Task.sleep(for: .milliseconds(1500))
        #expect(hasReturned.withLock { $0 } == false)

        await manager.releaseHeldAmountUpdate()
        await gate.value
        #expect(recorder.latest?.isLoaded == true)
    }

    @Test("An autoupdate tick queued by a previous arming is ignored", .timeLimit(.minutes(1)))
    func staleAutoupdateTickIsIgnored() async throws {
        let manager = ExpressManagerStub()
        await manager.setSelectedProvider(ExpressAvailableProviderFixture.make(state: .error(StubError(), quote: .none)))
        let timer = ManualAutoupdatingTimer()
        let sut = makeSUT(
            // The pending transaction restriction is one of the states that arm autoupdating.
            sourceToken: SwapableTokenStub(
                blockchain: .ethereum(testnet: false),
                sendingRestriction: .hasPendingTransaction(blockchain: .ethereum(testnet: false))
            ),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager),
            autoupdatingTimer: timer
        )
        let recorder = SwapProvidersStateRecorder(sut)

        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: 0) { $0.isLoaded }
        let staleArming = try #require(timer.armings.first)

        // The next update re-arms the timer, so the tick captured above belongs to a superseded arming.
        var baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 2, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        #expect(timer.armings.count > 1)

        baseline = recorder.count
        staleArming()
        await MainActor.run {}
        #expect(recorder.count == baseline)

        // The tick from the current arming still refreshes, so the guard isn't rejecting everything.
        let currentArming = try #require(timer.armings.last)
        currentArming()
        // The autoupdate transition is silent for the UI, so any new publish is the signal here.
        _ = try await waitForNewState(recorder, since: baseline) { _ in true }
    }

    // MARK: - [REDACTED_INFO]: amount prefilled before the initial pair load

    @MainActor
    @Test("An amount prefilled before the initial pair load is quoted ([REDACTED_INFO])")
    func amountPrefilledBeforeInitialLoadingIsQuoted() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager),
            initialResolvingPolicy: .enabled()
        )

        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        try await waitUntil { await manager.getAmountType() == .from(1) }
        #expect(await manager.currentPair != nil)
        #expect(await manager.updateAmountTypeCallCount == 1)
    }

    // MARK: - [REDACTED_INFO]: account funding flows

    @Test("Add funds auto-resolves the source token when the destination is fixed")
    func addFundsResolvesSourceToken() async throws {
        let resolvedSource = SwapableTokenStub(blockchain: .ethereum(testnet: false))
        let sut = makeSUT(
            receiveToken: SwapableTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            sourceTokenResolver: SourceTokenResolverStub(source: resolvedSource),
            initialResolvingPolicy: .enabled()
        )

        // initialLoading runs on a detached task; wait for the resolved source to land.
        for _ in 0 ..< 500 {
            if case .success = sut.sourceToken { break }
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(sut.sourceToken.value?.tokenItem == resolvedSource.tokenItem)
    }

    // MARK: - [REDACTED_INFO]: deferred pair resolution

    @Test("Receive selector unblocks while the source is still being resolved ([REDACTED_INFO])")
    func receiveSelectorUnblocksWhileSourceIsResolving() async throws {
        let resolver = ControllableSourceResolverStub(source: SwapableTokenStub(blockchain: .ethereum(testnet: false)))
        // The SUT is not leak-tracked here: the suspended resolver keeps the initial-loading
        // task (and therefore the model) alive until the stub is released.
        let sut = makeSUT(sourceTokenResolver: resolver, initialResolvingPolicy: .enabled())

        let error = try await waitForReceiveTokenFailure(sut)
        #expect(error as? SwapModel.SwapModelError == .tokenSelectionRequired)
        #expect(sut.sourceToken.isLoading)
    }

    @Test("A resolved source that matches the receive token picked meanwhile is left to the user")
    func resolvedSourceMatchingPickedReceiveIsNotInstalled() async throws {
        let token = SwapableTokenStub(blockchain: .ethereum(testnet: false))
        let resolver = ControllableSourceResolverStub(source: token)
        let sut = makeSUT(sourceTokenResolver: resolver, initialResolvingPolicy: .enabled())

        _ = try await waitForReceiveTokenFailure(sut)
        sut.update(receive: token)
        resolver.release()

        try await waitUntil { sut.sourceToken.isFailure }

        guard case .failure(let error) = sut.sourceToken else {
            Issue.record("Expected the source to be left to the user, got \(sut.sourceToken)")
            return
        }

        #expect(error as? SwapModel.SwapModelError == .tokenSelectionRequired)
        #expect(sut.receiveToken.value?.tokenItem == token.tokenItem)
    }

    @Test("A receive side the resolver can't settle is left to the user")
    func unsettledReceiveSideIsLeftToTheUser() async throws {
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveTokenResolver: ReceiveTokenResolverStub(receive: nil),
            initialResolvingPolicy: .enabled()
        )

        let error = try await waitForReceiveTokenFailure(sut)

        #expect(error as? SwapModel.SwapModelError == .tokenSelectionRequired)
        #expect(sut.sourceToken.isSuccess)
    }

    @Test("Resolving that outlives the timeout leaves the side to the user")
    func resolvingThatOutlivesTheTimeoutIsLeftToTheUser() async throws {
        let resolver = ControllableSourceResolverStub(source: SwapableTokenStub(blockchain: .ethereum(testnet: false)))
        let sut = makeSUT(
            sourceTokenResolver: resolver,
            initialResolvingPolicy: .enabled(timeout: .milliseconds(50))
        )

        try await waitUntil { sut.sourceToken.isFailure }

        guard case .failure(let error) = sut.sourceToken else {
            Issue.record("Expected the source to be left to the user, got \(sut.sourceToken)")
            return
        }

        #expect(error as? SwapModel.SwapModelError == .tokenSelectionRequired)
        resolver.release()
    }

    // MARK: - Destination re-resolution

    @Test("The destination follows the source resolved during initial loading")
    func destinationFollowsTheSourceResolvedInitially() async throws {
        let resolvedSource = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDT", contract: "0xUSDT"))
        let followingDestination = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDC", contract: "0xUSDC"))
        let sut = makeSUT(
            receiveToken: SwapableTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            sourceTokenResolver: SourceTokenResolverStub(source: resolvedSource),
            destinationTokenResolver: DestinationTokenResolverStub(destination: followingDestination),
            initialResolvingPolicy: .enabled()
        )

        try await waitUntil { sut.receiveToken.value?.tokenItem == followingDestination.tokenItem }
        #expect(sut.sourceToken.value?.tokenItem == resolvedSource.tokenItem)
    }

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
        let receive = SwapableTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        let sut = makeSUT(receiveToken: receive)

        sut.update(source: SwapableTokenStub(blockchain: .ethereum(testnet: false)))

        #expect(sut.receiveToken.value?.tokenItem == receive.tokenItem)
    }

    // MARK: - Receive token replacement

    @Test("A crypto receive amount keeps its fiat value in the replacing token ([REDACTED_INFO])")
    func receiveTokenReplacementConvertsCryptoAmount() async throws {
        let amount = try await receiveAmountAfterReplacement(
            entered: SendAmount(type: .typical(crypto: 0.1, fiat: 400)),
            prices: ["svs-previous-coin": 4000, "svs-new-coin": 100_000]
        )

        #expect(amount?.crypto == 0.004)
    }

    @Test("A fiat receive amount stays the same fiat value in the replacing token")
    func receiveTokenReplacementKeepsEnteredFiat() async throws {
        let amount = try await receiveAmountAfterReplacement(
            entered: SendAmount(type: .alternative(fiat: 50, crypto: 0.0125)),
            prices: ["svs-previous-coin": 4000, "svs-new-coin": 100_000]
        )

        #expect(amount?.fiat == 50)
        #expect(amount?.crypto == 0.0005)
    }

    @Test("The same asset on another network keeps the entered receive amount")
    func receiveNetworkChangeKeepsAmount() async throws {
        let amount = try await receiveAmountAfterReplacement(
            entered: SendAmount(type: .typical(crypto: 100, fiat: 100)),
            previous: makeQuotedTokenItem(currencyId: "svs-stable-coin", blockchain: .ethereum(testnet: false)),
            replacing: makeQuotedTokenItem(currencyId: "svs-stable-coin", blockchain: .polygon(testnet: false)),
            prices: ["svs-stable-coin": 1]
        )

        #expect(amount?.crypto == 100)
    }

    @Test("A destination-only update of the same receive token keeps the entered amount")
    func sameReceiveTokenUpdateKeepsAmount() async throws {
        let tokenItem = makeQuotedTokenItem(currencyId: "svs-previous-coin")
        let amount = try await receiveAmountAfterReplacement(
            entered: SendAmount(type: .typical(crypto: 0.1, fiat: 400)),
            previous: tokenItem,
            replacing: tokenItem,
            prices: [:]
        )

        #expect(amount?.crypto == 0.1)
    }

    @Test("Without a price for the replacing token the old receive amount is not carried over")
    func receiveTokenReplacementWithoutPriceDropsAmount() async throws {
        let amount = try await receiveAmountAfterReplacement(
            entered: SendAmount(type: .typical(crypto: 0.1, fiat: 400)),
            prices: ["svs-previous-coin": 4000]
        )

        #expect(amount == nil)
    }

    // MARK: - Pair reversal

    @Test("Reversing the pair makes the receive token the source")
    func pairReversalSwapsSides() async throws {
        let source = SwapableTokenStub(blockchain: .ethereum(testnet: false))
        let receive = SwapableTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        let sut = makeSUT(sourceToken: source, receiveToken: receive)

        sut.userDidRequestSwapSourceAndReceiveToken()

        try await waitUntil { sut.sourceToken.value?.tokenItem == receive.tokenItem }
        #expect(sut.receiveToken.value?.tokenItem == source.tokenItem)
    }

    @Test("Reversing the pair keeps a joint account's destination out of the source")
    func pairReversalKeepsJointAccountDestination() async throws {
        let source = SwapableTokenStub(blockchain: .ethereum(testnet: false))
        let sut = makeSUT(sourceToken: source)
        let item = makeJointAccountItem()
        try sut.swapTokenSelectorDidRequestUpdate(destination: item)

        sut.userDidRequestSwapSourceAndReceiveToken()
        try await Task.sleep(for: .milliseconds(100))

        #expect(sut.sourceToken.value?.tokenItem == source.tokenItem)
        #expect(sut.receiveToken.value?.tokenItem == item.tokenItem)
    }

    @Test("Reversing the pair keeps the sides when the receive token can't be swapped from", arguments: SendingRestrictionCase.allCases)
    func pairReversalKeepsSidesForRestrictedReceiveToken(restriction: SendingRestrictionCase) async throws {
        let source = SwapableTokenStub(blockchain: .ethereum(testnet: false))
        let receive = SwapableTokenStub(
            blockchain: .ton(curve: .ed25519, testnet: false),
            sendingRestriction: restriction.sendingRestriction
        )
        let sut = makeSUT(sourceToken: source, receiveToken: receive)

        sut.userDidRequestSwapSourceAndReceiveToken()
        try await Task.sleep(for: .milliseconds(100))

        #expect(sut.sourceToken.value?.tokenItem == source.tokenItem)
        #expect(sut.receiveToken.value?.tokenItem == receive.tokenItem)
    }

    // MARK: - Custom slippage

    @Test("The slippage sheet keeps its provider through a fee refresh but not through a quote reload")
    func slippageProviderFollowsReloadKind() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)
        let defaultSlippage = Decimal(string: "0.003")!

        var baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        await manager.setSelectedProvider(ExpressAvailableProviderFixture.make(
            state: .restriction(.tooBigAmount(100, currencySymbol: "ETH"), quote: nil),
            slippage: defaultSlippage,
            isCustomSlippageSupported: true
        ))
        baseline = recorder.count
        sut.actualizeInformation()
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect(sut.slippageProvider?.slippage == defaultSlippage)

        baseline = recorder.count
        sut.actualizeInformation()

        #expect(sut.slippageProvider == nil)

        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect(sut.slippageProvider?.slippage == defaultSlippage)

        baseline = recorder.count
        sut.userDidFinishSelection(feeTokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)), feeOption: .market)

        let isLoadingFee = if case .loading(.fee) = recorder.latest { true } else { false }
        #expect(isLoadingFee)
        #expect(sut.slippageProvider?.slippage == defaultSlippage)

        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        await manager.holdNextAmountUpdate()
        baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 2, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { state in
            if case .loading = state { true } else { false }
        }

        #expect(sut.slippageProvider == nil)

        await manager.releaseHeldAmountUpdate()
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect(sut.slippageProvider?.slippage == defaultSlippage)

        sut.update(receive: ReceiveTokenStub(blockchain: .polygon(testnet: false)))

        #expect(sut.slippageProvider == nil)
    }

    @Test("Choosing another provider hands the slippage sheet the new provider right away")
    func providerSelectionReplacesSlippageProvider() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)
        let quotedState: ExpressProviderManagerState = .restriction(.tooBigAmount(100, currencySymbol: "ETH"), quote: nil)
        let first = ExpressAvailableProviderFixture.make(state: quotedState, slippage: Decimal(string: "0.003"), isCustomSlippageSupported: true)
        let second = ExpressAvailableProviderFixture.make(state: quotedState, slippage: Decimal(string: "0.01"), isCustomSlippageSupported: false)

        var baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        await manager.setSelectedProvider(first)
        baseline = recorder.count
        sut.actualizeInformation()
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect(sut.slippageProvider?.isCustomSlippageSupported == true)

        baseline = recorder.count
        sut.userDidSelect(provider: second)

        #expect(sut.slippageProvider?.isCustomSlippageSupported == false)

        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect(sut.slippageProvider?.isCustomSlippageSupported == false)
    }

    @Test("A provider without a default slippage gives the slippage sheet nothing to open")
    func providerWithoutSlippageIsNotOfferedToSelector() {
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        )
        let quotedState: ExpressProviderManagerState = .restriction(.tooBigAmount(100, currencySymbol: "ETH"), quote: nil)

        sut.userDidSelect(provider: ExpressAvailableProviderFixture.make(state: quotedState, slippage: nil))

        #expect(sut.slippageProvider == nil)
    }

    @Test("Tapping the low slippage warning asks the router to open the slippage sheet")
    func editSlippageNotificationOpensSelector() {
        let router = SwapModelRouterSpy()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        )
        sut.router = router

        sut.didTapNotification(with: 0, action: .editSlippage)

        #expect(router.slippageSelectorOpenings == 1)
    }

    @Test("Setting a custom slippage updates the manager once, without a separate quote reload")
    func customSlippageReachesManagerOnce() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager
        )

        sut.userDidSet(slippage: .custom(0.005))
        try await waitUntil { await manager.getSlippage() == 0.005 }

        #expect(sut.slippage == .custom(0.005))
        #expect(await manager.updateSlippageCallCount == 1)
        #expect(await manager.updateTypeCallCount == 0)
        #expect(await manager.updateAmountTypeCallCount == 0)
    }

    @Test("An amount change resets the custom slippage to Auto and flags the reset")
    func amountChangeResetsCustomSlippage() async throws {
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        )
        var resets: [Bool] = []
        let cancellable = sut.isCustomSlippageResetPublisher.sink { resets.append($0) }

        withExtendedLifetime(cancellable) {
            sut.userDidSet(slippage: .custom(0.005))
            sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
            sut.userDidSet(slippage: .custom(0.004))
        }

        #expect(resets == [false, false, true, false])
        #expect(sut.slippage == .custom(0.004))
    }

    @Test("An amount change leaves the slippage reset to the manager instead of requoting before the new amount")
    func amountChangeSkipsSlippageSync() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        var baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        baseline = recorder.count
        sut.userDidSet(slippage: .custom(0.005))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 2, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect(await manager.updateSlippageCallCount == 1)
        #expect(await manager.getSlippage() == nil)
        #expect(sut.slippage == .auto)
    }

    @Test("Retyping the same amount within the debounce leaves the manager on the model's Auto")
    func retypedAmountKeepsManagerInSync() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        var baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        baseline = recorder.count
        sut.userDidSet(slippage: .custom(0.005))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 12, fiat: nil)))
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect(sut.slippage == .auto)
        #expect(await manager.getSlippage() == nil)
    }

    @Test(
        "The swap event reports the slippage the transaction goes out with",
        arguments: [
            (isSupported: true, slippage: SwapSlippage.custom(Decimal(string: "0.004")!), transaction: Decimal?.some(Decimal(string: "0.0045")!), expected: Decimal?.some(Decimal(string: "0.0045")!)),
            (isSupported: true, slippage: SwapSlippage.custom(Decimal(string: "0.004")!), transaction: Decimal?.none, expected: Decimal?.some(Decimal(string: "0.004")!)),
            (isSupported: true, slippage: SwapSlippage.auto, transaction: Decimal?.none, expected: Decimal?.some(Decimal(string: "0.003")!)),
            (isSupported: false, slippage: SwapSlippage.custom(Decimal(string: "0.004")!), transaction: Decimal?.none, expected: Decimal?.some(Decimal(string: "0.003")!)),
            (isSupported: false, slippage: SwapSlippage.custom(Decimal(string: "0.004")!), transaction: Decimal?.some(Decimal(string: "0.0045")!), expected: Decimal?.some(Decimal(string: "0.0045")!)),
        ]
    )
    func swapAnalyticsSlippage(isSupported: Bool, slippage: SwapSlippage, transaction: Decimal?, expected: Decimal?) {
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        )
        let provider = ExpressAvailableProviderFixture.make(
            state: .idle,
            slippage: Decimal(string: "0.003"),
            isCustomSlippageSupported: isSupported
        )

        sut.userDidSet(slippage: slippage)

        #expect(sut.swapAnalyticsSlippage(provider: provider, transactionSlippage: transaction) == expected)
    }

    @MainActor
    @Test("A source token change resets the custom slippage")
    func sourceChangeResetsCustomSlippage() {
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(tokenItem: .accountToken(symbol: "USDC", contract: "0xUSDC")),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        )

        sut.userDidSet(slippage: .custom(0.005))
        sut.update(source: SwapableTokenStub(tokenItem: .accountToken(symbol: "USDT", contract: "0xUSDT")))

        #expect(sut.slippage == .auto)
    }

    @MainActor
    @Test("A receive token change resets the custom slippage")
    func receiveChangeResetsCustomSlippage() {
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false))
        )

        sut.userDidSet(slippage: .custom(0.005))
        sut.update(receive: ReceiveTokenStub(blockchain: .polygon(testnet: false)))

        #expect(sut.slippage == .auto)
    }

    @Test("A token change leaves the reset slippage to the pair update instead of requoting the outgoing pair")
    func tokenChangeSkipsSlippageSyncForOutgoingPair() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        var baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        baseline = recorder.count
        sut.userDidSet(slippage: .custom(0.005))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }
        #expect(await manager.getSlippage() == 0.005)

        baseline = recorder.count
        sut.update(receive: ReceiveTokenStub(blockchain: .polygon(testnet: false)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect(await manager.updateSlippageCallCount == 1)
        #expect(await manager.getSlippage() == nil)
        #expect(sut.slippage == .auto)
    }

    @Test(
        "Loaded quotes keep a custom slippage only for a provider that supports it within its range",
        arguments: [
            (isSupported: true, defaultSlippage: Decimal(0.003), isKept: true),
            (isSupported: true, defaultSlippage: Decimal(0.0015), isKept: false),
            (isSupported: false, defaultSlippage: Decimal(0.003), isKept: false),
        ]
    )
    func providerCompatibilityDecidesReset(isSupported: Bool, defaultSlippage: Decimal, isKept: Bool) async throws {
        let manager = ExpressManagerStub()
        let handler = ReconcilingPairHandlerStub(expressManager: manager)
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: ReceiveTokenStub(blockchain: .ton(curve: .ed25519, testnet: false)),
            expressManager: manager,
            pairUpdateHandler: handler
        )
        let recorder = SwapProvidersStateRecorder(sut)

        var baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        await manager.setSelectedProvider(ExpressAvailableProviderFixture.make(
            state: .idle,
            slippage: defaultSlippage,
            isCustomSlippageSupported: isSupported
        ))
        sut.userDidSet(slippage: .custom(0.0035))

        baseline = recorder.count
        sut.actualizeInformation()
        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        #expect((sut.slippage == .custom(0.0035)) == isKept)
        #expect(await manager.getSlippage() == (isKept ? 0.0035 : nil))
    }

    // MARK: - Token selector output

    @Test("A joint account's token picked as the source is refused and the source stays")
    func jointAccountTokenIsRefusedAsSource() {
        let source = SwapableTokenStub(blockchain: .ethereum(testnet: false))
        let sut = makeSUT(sourceToken: source)

        #expect(throws: TokenSelectorItemOutputTypeBuilder.BuildError.self) {
            try sut.swapTokenSelectorDidRequestUpdate(sender: makeJointAccountItem())
        }

        #expect(sut.sourceToken.value?.tokenItem == source.tokenItem)
    }

    @Test("A joint account's token picked as the destination becomes a receive-only token")
    func jointAccountTokenIsAcceptedAsDestination() throws {
        let sut = makeSUT(sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)))
        let item = makeJointAccountItem()

        try sut.swapTokenSelectorDidRequestUpdate(destination: item)

        #expect(sut.receiveToken.value?.tokenItem == item.tokenItem)
        #expect(!(sut.receiveToken.value is SendSwapableToken))
    }

    // MARK: - Transfer destination

    @Test("A transfer pair is addressed to the receive token's own address, for the fee and for the transaction alike")
    func transferIsAddressedToTheReceiveToken() async throws {
        let usdc = TokenItem.accountToken(symbol: "USDC", contract: "0xUSDC")
        let zeroFee = Fee(Amount(with: usdc.blockchain, type: usdc.amountType, value: 0))
        let feeManager = TokenFeeProvidersManagerMock(
            feeProvider: TokenFeeProviderStub(
                feeTokenItem: usdc,
                initialFee: TokenFee(option: .market, tokenItem: usdc, value: .success(zeroFee))
            )
        )
        let source = SwapableTokenStub(
            tokenItem: usdc,
            transactionValidator: SendTransactionValidatorStub(),
            tokenFeeProvidersManager: feeManager
        )
        let receive = SwapableTokenStub(tokenItem: usdc, defaultAddress: "0xBridge")
        let sut = makeSUT(sourceToken: source, receiveToken: receive)
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        let state = try await sut.mapToReadyToTransferState()

        guard case .readyToTransfer(let transfer) = state else {
            Issue.record("Expected a transfer ready to go, got \(state)")
            return
        }

        #expect(transfer.destination == "0xBridge")
        #expect(feeManager.updateInputCalls == [.common(amount: 1, destination: "0xBridge")])
    }

    // MARK: - Fee row on balance restrictions

    @Test("A balance restriction hides the fee row when the selected provider has not estimated the swap fee")
    func balanceRestrictionHidesFeeRowWithoutSwapFee() {
        let sut = makeSUT()
        let cases: [(ExpressProviderManagerState, SwapModel.RestrictionType)] = [
            (.restriction(.insufficientBalance(1), quote: nil), .notEnoughBalanceForSwapping),
            (.restriction(.feeCurrencyHasZeroBalance(isFeeCurrency: false), quote: nil), .notEnoughAmountForFee(isFeeCurrency: false, feeCurrencyBalance: 0)),
            (.permissionRequired(makePermissionRequired()), .notEnoughBalanceForSwapping),
            (.revokeAndPermissionRequired(makePermissionRequired()), .notEnoughBalanceForSwapping),
        ]

        for (providerState, restriction) in cases {
            let providersState = makeRestrictedProvidersState(providerState: providerState, restriction: restriction)
            #expect(!sut.mapToShouldShowFeeSelectorRow(providersState: providersState), "\(providerState)")
        }
    }

    @Test("A balance restriction keeps the fee row when the selected provider has estimated the swap fee")
    func balanceRestrictionKeepsFeeRowWithSwapFee() {
        let sut = makeSUT()
        let cases: [(ExpressProviderManagerState, SwapModel.RestrictionType)] = [
            (makeCEXPreviewState(), .notEnoughBalanceForSwapping),
            (makeDEXPreviewState(), .notEnoughBalanceForSwapping),
            (makeDEXWithApprovePreviewState(), .notEnoughAmountForFee(isFeeCurrency: false, feeCurrencyBalance: 0)),
            (.restriction(.insufficientBalanceIncludingFee, quote: nil), .notEnoughBalanceForSwapping),
            (
                .restriction(.feeCurrencyInsufficientBalanceForTxValue(1, isFeeCurrency: true, feeCurrencyBalance: 0), quote: nil),
                .notEnoughAmountForTxValue(1, isFeeCurrency: true, feeCurrencyBalance: 0)
            ),
        ]

        for (providerState, restriction) in cases {
            let providersState = makeRestrictedProvidersState(providerState: providerState, restriction: restriction)
            #expect(sut.mapToShouldShowFeeSelectorRow(providersState: providersState), "\(providerState)")
        }
    }

    // MARK: - [REDACTED_INFO]: destination trustline restriction

    @Test("A destination that requires a trustline maps to the trustlineRequired restriction")
    func destinationRequiringTrustlineMapsToRestriction() async throws {
        let receive = SwapableTokenStub(
            blockchain: .stellar(curve: .ed25519, testnet: false),
            receivingRestriction: .requiresTrustline
        )
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: receive
        )

        let restriction = try await sut.validateReceivingRestrictions(receiveAmount: 100)

        guard case .trustlineRequired(let destination) = restriction else {
            Issue.record("Expected .trustlineRequired, got \(String(describing: restriction))")
            return
        }

        #expect(destination as AnyObject === receive)
    }

    @Test("A trustline-restricted destination blocks the providers flow without requesting quotes")
    func trustlineRestrictedDestinationBlocksProviders() async throws {
        let manager = ExpressManagerStub()
        let receive = SwapableTokenStub(
            blockchain: .stellar(curve: .ed25519, testnet: false),
            receivingRestriction: .requiresTrustline
        )
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: receive,
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        let baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        let state = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        guard case .loaded(.swap(selected: .none, providers: let providers), .restriction(.trustlineRequired(let destination), quote: .none)) = state else {
            Issue.record("Expected the trustlineRequired restriction without providers, got \(state)")
            return
        }

        #expect(destination as AnyObject === receive)
        #expect(providers.isEmpty)
        #expect(await manager.updateAmountTypeCallCount == 0)
    }

    @Test("A receive-only destination that requires a trustline maps to the trustlineRequired restriction")
    func receiveOnlyDestinationRequiringTrustlineMapsToRestriction() async throws {
        let receive = SendSourceTokenStub(
            blockchain: .stellar(curve: .ed25519, testnet: false),
            receivingRestriction: .requiresTrustline
        )
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: receive
        )

        let restriction = try await sut.validateReceivingRestrictions(receiveAmount: 100)

        guard case .trustlineRequired(let destination) = restriction else {
            Issue.record("Expected .trustlineRequired, got \(String(describing: restriction))")
            return
        }

        #expect(destination as AnyObject === receive)
    }

    @Test("A trustline-restricted receive-only destination blocks the providers flow without requesting quotes")
    func trustlineRestrictedReceiveOnlyDestinationBlocksProviders() async throws {
        let manager = ExpressManagerStub()
        let receive = SendSourceTokenStub(
            blockchain: .stellar(curve: .ed25519, testnet: false),
            receivingRestriction: .requiresTrustline
        )
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: receive,
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        let baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        let state = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        guard case .loaded(.swap(selected: .none, providers: let providers), .restriction(.trustlineRequired(let destination), quote: .none)) = state else {
            Issue.record("Expected the trustlineRequired restriction without providers, got \(state)")
            return
        }

        #expect(destination as AnyObject === receive)
        #expect(providers.isEmpty)
        #expect(await manager.updateAmountTypeCallCount == 0)
    }

    @Test("Quotes wait for the destination trustline data instead of loading on an unknown requirement")
    func destinationWithPendingTrustlineDataHoldsQuotes() async throws {
        let manager = ExpressManagerStub()
        let restrictionsProvider = PendingReceivingRestrictionsProviderStub(restrictionWhenLoaded: .requiresTrustline)
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: SwapableTokenStub(
                blockchain: .stellar(curve: .ed25519, testnet: false),
                receivingRestrictionsProvider: restrictionsProvider
            ),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        let baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoading }
        #expect(await manager.updateAmountTypeCallCount == 0)

        let loadingCount = recorder.count
        restrictionsProvider.finishLoading()

        let state = try await waitForNewState(recorder, since: loadingCount) { $0.isLoaded }

        guard case .loaded(.swap(selected: .none, providers: _), .restriction(.trustlineRequired, quote: .none)) = state else {
            Issue.record("Expected the trustlineRequired restriction once the data settled, got \(state)")
            return
        }

        #expect(await manager.updateAmountTypeCallCount == 0)
    }

    @Test("A destination whose data cannot be loaded fails the providers instead of quoting")
    func destinationWithUnavailableDataFailsProviders() async throws {
        let manager = ExpressManagerStub()
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: SwapableTokenStub(
                blockchain: .stellar(curve: .ed25519, testnet: false),
                receivingRestrictionsProvider: UnavailableReceivingRestrictionsProviderStub()
            ),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        let baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        let state = try await waitForNewState(recorder, since: baseline) { state in
            if case .failure = state { true } else { false }
        }

        guard case .failure(ReceivingRestrictionsError.restrictionsDataUnavailable) = state else {
            Issue.record("Expected the unavailable data failure, got \(state)")
            return
        }

        #expect(await manager.updateAmountTypeCallCount == 0)
    }

    @Test("Once the destination data settles without a restriction the quotes are requested")
    func destinationWithSettledDataResumesQuotes() async throws {
        let manager = ExpressManagerStub()
        let restrictionsProvider = PendingReceivingRestrictionsProviderStub(restrictionWhenLoaded: nil)
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: SwapableTokenStub(
                blockchain: .stellar(curve: .ed25519, testnet: false),
                receivingRestrictionsProvider: restrictionsProvider
            ),
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let recorder = SwapProvidersStateRecorder(sut)

        let baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoading }
        #expect(await manager.updateAmountTypeCallCount == 0)

        let loadingCount = recorder.count
        restrictionsProvider.finishLoading()

        let state = try await waitForNewState(recorder, since: loadingCount) { $0.isLoaded }

        if case .loaded(_, .restriction(.trustlineRequired, _)) = state {
            Issue.record("Expected the quotes to resume, got the trustline restriction")
            return
        }

        #expect(await manager.updateAmountTypeCallCount == 1)
    }

    @Test("Tapping the trustline banner opens the details of the destination token")
    func trustlineBannerTapOpensDestinationTokenDetails() async throws {
        let manager = ExpressManagerStub()
        let receive = SwapableTokenStub(
            blockchain: .stellar(curve: .ed25519, testnet: false),
            receivingRestriction: .requiresTrustline
        )
        let sut = makeSUT(
            sourceToken: SwapableTokenStub(blockchain: .ethereum(testnet: false)),
            receiveToken: receive,
            expressManager: manager,
            pairUpdateHandler: ReconcilingPairHandlerStub(expressManager: manager)
        )
        let router = SwapModelRouterSpy()
        sut.router = router
        let recorder = SwapProvidersStateRecorder(sut)

        let baseline = recorder.count
        sut.update(sourceAmount: SendAmount(type: .typical(crypto: 1, fiat: nil)))

        _ = try await waitForNewState(recorder, since: baseline) { $0.isLoaded }

        sut.didTapNotification(with: 0, action: .addTokenTrustline)

        #expect(router.openedTokenDetails.count == 1)
        #expect(router.openedTokenDetails.first?.tokenItem == receive.tokenItem)
        #expect(router.openedTokenDetails.first?.userWalletId == receive.userWalletInfo.id)
    }
}

// MARK: - Helpers

private extension SwapModelTests {
    func makeSUT(
        sourceToken: SendSwapableToken? = nil,
        receiveToken: SendReceiveToken? = nil,
        expressManager: ExpressManager = ExpressManagerStub(),
        pairUpdateHandler: SwapPairUpdateHandler = SwapPairUpdateHandlerStub(),
        autoupdatingTimer: any AutoupdatingTimerSetup = AutoupdatingTimer(),
        sourceTokenResolver: (any SwapSourceTokenResolver)? = nil,
        receiveTokenResolver: (any SwapReceiveTokenResolver)? = nil,
        destinationTokenResolver: (any SwapDestinationTokenResolver)? = nil,
        initialResolvingPolicy: SwapModel.InitialResolvingPolicy = .disabled
    ) -> SwapModel {
        let model = SwapModel(
            parameters: makeParameters(
                sourceToken: sourceToken,
                receiveToken: receiveToken,
                sourceTokenResolver: sourceTokenResolver,
                receiveTokenResolver: receiveTokenResolver,
                destinationTokenResolver: destinationTokenResolver
            ),
            expressManager: expressManager,
            swapRepository: SwapRepositoryStub(),
            expressPendingTransactionRepository: ExpressPendingTransactionRepositoryStub(),
            expressAPIProvider: ExpressAPIProviderStub(),
            expressUserWalletId: UserWalletId(value: Data()),
            analyticsLogger: SendAnalyticsLoggerStub(),
            autoupdatingTimer: autoupdatingTimer,
            pairUpdateHandler: pairUpdateHandler,
            balanceRestrictionFeatureChecker: SwapBalanceRestrictionFeatureCheckerStub(),
            initialResolvingPolicy: initialResolvingPolicy
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

    func makeParameters(
        sourceToken: SendSwapableToken?,
        receiveToken: SendReceiveToken?,
        sourceTokenResolver: (any SwapSourceTokenResolver)?,
        receiveTokenResolver: (any SwapReceiveTokenResolver)?,
        destinationTokenResolver: (any SwapDestinationTokenResolver)?
    ) -> PredefinedSwapParameters {
        let configuration = SwapFlowConfiguration(
            isPairReversalEnabled: true,
            sourceTokenSelection: .selectable(.unrestricted),
            receiveTokenSelection: destinationTokenResolver.map { SwapFlowConfiguration.ReceiveTokenSelection.followsSource($0) } ?? .selectable(.unrestricted),
            summaryTitle: nil
        )

        let defaultSourceToken = SwapableTokenStub(blockchain: .ethereum(testnet: false))

        let source: any SwapSourceTokenResolver = if let sourceTokenResolver {
            sourceTokenResolver
        } else if let sourceToken {
            .resolved(sourceToken)
        } else if receiveToken == nil {
            .resolved(defaultSourceToken)
        } else {
            .userSelection
        }

        let receive: any SwapReceiveTokenResolver = if let receiveTokenResolver {
            receiveTokenResolver
        } else if let receiveToken {
            .resolved(receiveToken)
        } else {
            .userSelection
        }

        return PredefinedSwapParameters(
            userWalletInfo: (sourceToken ?? defaultSourceToken).userWalletInfo,
            source: source,
            receive: receive,
            configuration: configuration
        )
    }

    func makeJointAccountItem() -> TokenSelectorItem {
        let account = CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, accountType: .joint, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            accountStatus: .pending,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            delegate: jointAccountDelegate
        )
        let walletModel = WalletModelTestsMock(
            tokenItem: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)),
            isEmpty: false,
            account: account
        )
        let userWalletInfo = UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(supportedBlockchains: [.polygon(testnet: false)]),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )

        return TokenSelectorItem(userWalletInfo: userWalletInfo, kind: .crypto(walletModel, account))
    }

    func makeQuotedTokenItem(currencyId: String, blockchain: Blockchain = .ethereum(testnet: false)) -> TokenItem {
        let token = Token(
            name: currencyId,
            symbol: currencyId.uppercased(),
            contractAddress: "0x\(currencyId)",
            decimalCount: 18,
            id: currencyId
        )

        return .token(token, BlockchainNetwork(blockchain, derivationPath: nil))
    }

    func receiveAmountAfterReplacement(
        entered: SendAmount,
        previous: TokenItem? = nil,
        replacing: TokenItem? = nil,
        prices: [String: Decimal]
    ) async throws -> SendAmount? {
        try await InjectedDependenciesIsolation.shared.run {
            let previousRepository = try injectQuotes(prices)
            defer { InjectedValues.setTokenQuotesRepository(previousRepository) }

            let sut = makeSUT(
                sourceToken: SwapableTokenStub(blockchain: .polygon(testnet: false)),
                receiveToken: SwapableTokenStub(tokenItem: previous ?? makeQuotedTokenItem(currencyId: "svs-previous-coin"))
            )
            sut.update(receiveAmount: entered)

            sut.update(receive: SwapableTokenStub(tokenItem: replacing ?? makeQuotedTokenItem(currencyId: "svs-new-coin")))

            return sut.receiveAmount.value
        }
    }

    func injectQuotes(_ prices: [String: Decimal]) throws -> TokenQuotesRepository & TokenQuotesRepositoryUpdater {
        let quotes = prices.reduce(into: Quotes()) { quotes, entry in
            quotes[entry.key] = TokenQuote(
                currencyId: entry.key,
                price: entry.value,
                priceUsd: entry.value,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "USD"
            )
        }

        let previous = try #require(InjectedValues[\.quotesRepository] as? TokenQuotesRepository & TokenQuotesRepositoryUpdater)
        InjectedValues.setTokenQuotesRepository(MockTokenQuotesRepository(quotes: quotes))
        return previous
    }

    func makeRestrictedProvidersState(
        providerState: ExpressProviderManagerState,
        restriction: SwapModel.RestrictionType
    ) -> SwapModel.ProvidersState {
        let selected = ExpressAvailableProviderFixture.make(state: providerState)
        return .loaded(.swap(selected: selected, providers: .empty), state: .restriction(restriction, quote: nil))
    }

    func makeCEXPreviewState() -> ExpressProviderManagerState {
        let provider = ExpressAvailableProviderFixture.make(state: .idle).provider
        return .cexPreview(.init(provider: provider, subtractFee: 0, quote: ExpressQuoteFixture.make(), fee: makeZeroFee()))
    }

    func makeDEXPreviewState() -> ExpressProviderManagerState {
        let provider = ExpressAvailableProviderFixture.make(state: .idle).provider
        return .dexPreview(.init(provider: provider, data: ExpressTransactionDataFixture.make(), fee: makeZeroFee(), quote: ExpressQuoteFixture.make()))
    }

    func makeDEXWithApprovePreviewState() -> ExpressProviderManagerState {
        let provider = ExpressAvailableProviderFixture.make(state: .idle).provider
        return .dexWithApprovePreview(.init(
            provider: provider,
            expressTransactionData: ExpressTransactionDataFixture.make(),
            quote: ExpressQuoteFixture.make(),
            approveData: .init(
                provider: provider,
                approvePolicy: .specified,
                approveTransactionData: makeApproveTransactionData(),
                approvalFlow: .approve,
                approveFee: makeZeroFee()
            ),
            combinedFee: makeZeroFee()
        ))
    }

    func makePermissionRequired() -> ExpressProviderManagerState.PermissionRequired {
        let provider = ExpressAvailableProviderFixture.make(state: .idle).provider
        return .init(
            provider: provider,
            policy: .specified,
            data: makeApproveTransactionData(),
            approvalFlow: .approve,
            fee: makeZeroFee(),
            quote: ExpressQuoteFixture.make()
        )
    }

    func makeApproveTransactionData() -> ApproveTransactionData {
        ApproveTransactionData(txData: Data(), spender: "0xspender", toContractAddress: "0xcontract")
    }

    func makeZeroFee() -> Fee {
        Fee(Amount(with: .polygon(testnet: false), type: .coin, value: 0))
    }

    /// Waits for a state published *after* `baseline` that satisfies `predicate`. Capturing the baseline
    /// count before the triggering action makes the wait robust for back-to-back tasks, where the
    /// `CurrentValueSubject` already holds a stale terminal state from the previous task.
    func waitForNewState(
        _ recorder: SwapProvidersStateRecorder,
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

    func waitUntil(_ condition: @escaping () async -> Bool) async throws {
        for _ in 0 ..< 500 {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }

        throw TimeoutError()
    }

    struct TimeoutError: Error {}
    struct StubError: Error {}
}

// MARK: - Stubs

private final class SwapModelRouterSpy: SwapModelRoutable {
    private(set) var slippageSelectorOpenings = 0
    private(set) var openedTokenDetails: [(userWalletId: UserWalletId, tokenItem: TokenItem)] = []

    func openNetworkCurrency() {}
    func openApproveSheet() {}
    func performSwapAction() {}

    func openTokenDetails(userWalletId: UserWalletId, tokenItem: TokenItem) {
        openedTokenDetails.append((userWalletId, tokenItem))
    }

    func openSlippageSelector() {
        slippageSelectorOpenings += 1
    }
}

/// Records every arming so a test can fire a tick that a later arming has already superseded.
private final class ManualAutoupdatingTimer: AutoupdatingTimerSetup {
    private let state = OSAllocatedUnfairLock(initialState: [() -> Void]())

    var armings: [() -> Void] { state.withLock { $0 } }

    func setup(refresh: (() -> Void)?) {
        guard let refresh else { return }
        state.withLock { $0.append(refresh) }
    }
}

private actor ExpressManagerStub: ExpressManager {
    private(set) var currentPair: ExpressManagerSwappingPair?
    private var selectedProvider: ExpressAvailableProvider?
    private var amountType: ExpressAmountType?
    private var slippage: Decimal?
    private(set) var updateAmountTypeCallCount = 0
    private(set) var updateTypeCallCount = 0
    private(set) var updateSlippageCallCount = 0

    private var errorOnNextAmountUpdate: Error?
    private var isHoldingNextAmountUpdate = false
    private var isHeldUpdateReleased = false
    private var heldContinuation: CheckedContinuation<Void, Never>?

    private var amountTypeReadGate: TestGate?

    func getCurrentPair() -> ExpressManagerSwappingPair? { currentPair }

    func getAmountType() async -> ExpressAmountType? {
        if let amountTypeReadGate {
            await amountTypeReadGate.wait()
        }

        return amountType
    }

    func getSlippage() -> Decimal? { slippage }

    func holdAmountTypeReads(behind gate: TestGate) {
        amountTypeReadGate = gate
    }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState {
        currentPair = pair
        amountType = nil
        slippage = nil
        return state()
    }

    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState {
        updateAmountTypeCallCount += 1

        if isHoldingNextAmountUpdate {
            isHoldingNextAmountUpdate = false

            if !isHeldUpdateReleased {
                await withCheckedContinuation { heldContinuation = $0 }
            }
        }

        if let errorOnNextAmountUpdate {
            self.errorOnNextAmountUpdate = nil
            throw errorOnNextAmountUpdate
        }

        if amountType != self.amountType {
            slippage = nil
        }

        self.amountType = amountType
        return state()
    }

    // MARK: - Test mutators

    func failNextAmountUpdate(with error: Error) {
        errorOnNextAmountUpdate = error
    }

    func holdNextAmountUpdate() {
        isHoldingNextAmountUpdate = true
        isHeldUpdateReleased = false
    }

    func releaseHeldAmountUpdate() {
        isHeldUpdateReleased = true
        heldContinuation?.resume()
        heldContinuation = nil
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState {
        state()
    }

    func update(slippage: Decimal?) async -> ExpressManagerState {
        updateSlippageCallCount += 1
        self.slippage = slippage
        return state()
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState {
        selectedProvider = provider
        return state()
    }

    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState {
        updateTypeCallCount += 1
        return state()
    }

    /// Mirrors the real manager: no pair ⇒ `.idle` (the degenerate state behind the bug),
    /// a set pair ⇒ a loadable `.swap` state that `SwapModel` maps to `.loaded`.
    private func state() -> ExpressManagerState {
        currentPair == nil ? .idle : .swap(selected: selectedProvider, providers: .empty)
    }

    func setSelectedProvider(_ provider: ExpressAvailableProvider?) {
        selectedProvider = provider
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
            payInAddress: "",
            slippage: nil
        )
    }
}

private final class PendingReceivingRestrictionsProviderStub: ReceivingRestrictionsProvider {
    private let restrictionWhenLoaded: ReceivedRestriction?
    private let isLoaded = OSAllocatedUnfairLock(initialState: false)

    init(restrictionWhenLoaded: ReceivedRestriction?) {
        self.restrictionWhenLoaded = restrictionWhenLoaded
    }

    var isRestrictionKnown: Bool {
        isLoaded.withLock { $0 }
    }

    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction? {
        while !isLoaded.withLock({ $0 }) {
            try await Task.sleep(for: .milliseconds(10))
        }

        return restrictionWhenLoaded
    }

    func finishLoading() {
        isLoaded.withLock { $0 = true }
    }
}

private struct UnavailableReceivingRestrictionsProviderStub: ReceivingRestrictionsProvider {
    var isRestrictionKnown: Bool { false }

    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction? {
        throw ReceivingRestrictionsError.restrictionsDataUnavailable
    }
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

private final class ControllableSourceResolverStub: SwapSourceTokenResolver {
    private let source: SendSwapableToken
    private let releaseStream: AsyncStream<Void>
    private let releaseContinuation: AsyncStream<Void>.Continuation

    init(source: SendSwapableToken) {
        self.source = source
        (releaseStream, releaseContinuation) = AsyncStream<Void>.makeStream()
    }

    var initialSource: LoadingResult<SendSwapableToken, any Error> { .loading }

    func resolveSource(for receive: SendReceiveToken?) async throws -> SendSwapableToken {
        for await _ in releaseStream {
            break
        }

        return source
    }

    func release() {
        releaseContinuation.yield(())
    }
}

private final class SourceTokenResolverStub: SwapSourceTokenResolver {
    private let source: SendSwapableToken?

    init(source: SendSwapableToken?) {
        self.source = source
    }

    var initialSource: LoadingResult<SendSwapableToken, any Error> { .loading }

    func resolveSource(for receive: SendReceiveToken?) async throws -> SendSwapableToken {
        guard let source else {
            throw SwapModel.SwapModelError.tokenSelectionRequired
        }

        return source
    }
}

private final class ReceiveTokenResolverStub: SwapReceiveTokenResolver {
    private let receive: SendReceiveToken?

    init(receive: SendReceiveToken?) {
        self.receive = receive
    }

    var initialReceive: LoadingResult<SendReceiveToken, any Error> { .loading }

    func resolveReceive(for source: SendSwapableToken?) async throws -> SendReceiveToken {
        guard let receive else {
            throw SwapModel.SwapModelError.tokenSelectionRequired
        }

        return receive
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
