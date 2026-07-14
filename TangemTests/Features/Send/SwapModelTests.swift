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
}

// MARK: - Helpers

private extension SwapModelTests {
    func makeSUT(
        sourceToken: SendSwapableToken? = nil,
        receiveToken: SendReceiveToken? = nil,
        expressManager: ExpressManager = ExpressManagerStub(),
        pairUpdateHandler: SwapPairUpdateHandler = SwapPairUpdateHandlerStub(),
        balanceRestrictionChecker: SwapBalanceRestrictionFeatureChecker = SwapBalanceRestrictionFeatureCheckerStub()
    ) -> SwapModel {
        SwapModel(
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
            shouldStartInitialLoading: false
        )
    }

    /// Waits for a state published *after* `baseline` that satisfies `predicate`. Capturing the baseline
    /// count before the triggering action makes the wait robust for back-to-back tasks, where the
    /// `CurrentValueSubject` already holds a stale terminal state from the previous task.
    func waitForNewState(
        _ recorder: StateRecorder,
        since baseline: Int,
        timeout: Duration = .seconds(5),
        where predicate: @escaping (SwapModel.ProvidersState) -> Bool
    ) async throws -> SwapModel.ProvidersState {
        for _ in 0 ..< 500 {
            if recorder.count > baseline, let latest = recorder.latest, predicate(latest) {
                return latest
            }
            try await Task.sleep(for: .milliseconds(10))
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

private final class ExpressAPIProviderStub: ExpressAPIProvider {
    func assets(currencies: Set<ExpressWalletCurrency>) async throws -> [ExpressAsset] { [] }
    func pairs(from: Set<ExpressWalletCurrency>, to: Set<ExpressWalletCurrency>) async throws -> [ExpressPair] { [] }
    func providers(branch: ExpressBranch) async throws -> [ExpressProvider] { [] }

    func exchangeQuote(item: ExpressSwappableQuoteItem) async throws -> ExpressQuote {
        ExpressQuote(fromAmount: .zero, expectAmount: .zero, allowanceContract: nil, quoteId: nil, txType: nil)
    }

    func exchangeData(item: ExpressSwappableDataItem) async throws -> ExpressTransactionData {
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

    func exchangeStatus(transactionId: String) async throws -> ExchangeTransaction {
        fatalError("Not used in tests")
    }

    func exchangeSent(result: ExpressTransactionSentResult) async throws {}

    // Onramp
    func onrampCurrencies() async throws -> [OnrampFiatCurrency] { [] }
    func onrampCountries() async throws -> [OnrampCountry] { [] }

    func onrampCountryByIP() async throws -> OnrampCountry {
        let currency = OnrampFiatCurrency(identity: OnrampIdentity(name: "", code: "", image: nil), precision: 0)
        return OnrampCountry(identity: currency.identity, currency: currency, onrampAvailable: false)
    }

    func onrampPaymentMethods() async throws -> [OnrampPaymentMethod] { [] }
    func onrampPairs(from: OnrampFiatCurrency, to: [ExpressWalletCurrency], country: OnrampCountry) async throws -> [OnrampPair] { [] }

    func onrampQuote(item: OnrampQuotesRequestItem) async throws -> OnrampQuote {
        OnrampQuote(expectedAmount: .zero, nativePaymentAvailable: false, quoteId: nil)
    }

    func onrampData(item: OnrampRedirectDataRequestItem) async throws -> OnrampRedirectData {
        OnrampRedirectData(
            txId: "",
            widgetURL: URL(string: "https://stub")!,
            redirectURL: URL(string: "https://stub")!,
            fromAmount: .zero,
            fromCurrencyCode: "",
            toAmount: nil,
            countryCode: "",
            externalTxId: nil,
            externalTxURL: nil
        )
    }

    func onrampNativePaymentData(item: OnrampNativePaymentRequestItem) async throws -> OnrampDataResult {
        .widget(OnrampRedirectData(
            txId: "",
            widgetURL: URL(string: "https://stub")!,
            redirectURL: URL(string: "https://stub")!,
            fromAmount: .zero,
            fromCurrencyCode: "",
            toAmount: nil,
            countryCode: "",
            externalTxId: nil,
            externalTxURL: nil
        ))
    }

    func onrampStatus(transactionId: String) async throws -> OnrampTransaction {
        fatalError("Not used in tests")
    }

    /// History
    func exchangeHistory(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage {
        ExchangeHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func exchangeHistoryDelta(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage {
        ExchangeHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func onrampHistory(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage {
        OnrampHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func onrampHistoryDelta(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage {
        OnrampHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }
}

private final class SendAnalyticsLoggerStub: SendAnalyticsLogger {
    // MARK: - SendAnalyticsLogger

    func setup(sendDestinationInput: any SendDestinationInput) {}
    func setup(sendFeeInput: any SendFeeInput) {}
    func setup(sendSourceTokenInput: any SendSourceTokenInput) {}
    func setup(sendReceiveTokenInput: any SendReceiveTokenInput) {}
    func setup(sendSwapProvidersInput: any SendSwapProvidersInput) {}

    // MARK: - SendManagementModelAnalyticsLogger

    func logTransactionRejected(error: SendTxError) {}
    func logTransactionSent(amount: SendAmount?, additionalField: SendDestinationAdditionalField?, fee: FeeOption, signerType: String, currentProviderHost: String, tokenFee: TokenFee?) {}

    // MARK: - SendBaseViewAnalyticsLogger

    func logSendBaseViewOpened() {}
    func logRequestSupport() {}
    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {}
    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {}

    // MARK: - SendAmountAnalyticsLogger

    func logTapMaxAmount() {}
    func logTapConvertToAnotherToken() {}
    func logAmountStepOpened() {}
    func logAmountStepReopened() {}
    func logSwapErrorInsufficientBalance(screen: Analytics.ParameterValue) {}
    func logSwapErrorMinAmount(screen: Analytics.ParameterValue) {}
    func logSwapErrorMaxAmount(screen: Analytics.ParameterValue) {}
    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String) {}
    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?) {}

    // MARK: - SendReceiveTokensListAnalyticsLogger

    func logSearchClicked() {}
    func logTokenSearched(coin: CoinModel, searchText: String?) {}
    func logTokenChosen(token: TokenItem) {}
    func logSendSwapCantSwapThisToken(token: String) {}
    func logSendSwapAvailable(token: String) {}
    func logSendSwapAvailableClicked(token: String) {}

    // MARK: - SendDestinationAnalyticsLogger

    func logSendAddressEntered(isAddressValid: Bool, addressSource: Analytics.DestinationAddressSource) {}
    func logQRScannerOpened() {}
    func logDestinationStepOpened() {}
    func logAddressBookWidgetShown() {}
    func logAddressBookContactSelected(_ contact: AddressBookContact) {}
    func logAddressBookAddressSubstituted(_ contact: AddressBookContact) {}
    func logDestinationStepReopened() {}
    func setDestinationAnalyticsProvider(_ analyticsProvider: (any AccountModelAnalyticsProviding)?) {}

    // MARK: - SendFeeAnalyticsLogger

    func logFeeSelected(tokenFee: TokenFee) {}
    func logFeeSelected(_ feeOption: FeeOption) {}
    func logSendNoticeTransactionDelaysArePossible() {}
    func logFeeStepOpened() {}
    func logFeeStepReopened() {}
    func logFeeSummaryOpened() {}
    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {}

    // MARK: - FeeSelectorAnalytics

    func logCustomFeeClicked() {}

    // MARK: - SendSwapProvidersAnalyticsLogger

    func logSendSwapProvidersChosen(provider: ExpressProvider) {}
    func logSendSwapFilterProviderTapped(type: Analytics.ParameterValue) {}

    // MARK: - SendSummaryAnalyticsLogger

    func logUserDidTapOnValidator() {}
    func logUserDidTapOnProvider() {}
    func logSummaryStepOpened() {}
    func logTapAmountFraction(_ fraction: SwapAmountFraction) {}

    // MARK: - SendFinishAnalyticsLogger

    func logFinishStepOpened() {}
    func logShareButton() {}
    func logExploreButton() {}

    // MARK: - SendApproveAnalyticsLogger

    func logPermissionScreenOpened(isRevoke: Bool) {}
    func logSwapButtonPermissionApprove(policy: BSDKApprovePolicy) {}
    func logApproveTransactionSent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String) {}

    // MARK: - SwapManagementModelAnalyticsLogger

    func logSwapButtonSwap() {}
    func logSwapButtonTransfer() {}
    func logSwapTransferModeSwitched() {}
    func logSwapTransactionSent(result: TransactionDispatcherResult) {}
    func logSwapPreselectedTokenChanged(direction: Analytics.ParameterValue, preselectedSymbol: String, selectedSymbol: String) {}
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
    func hasSwapTotalBalanceRestriction(for token: SendSourceToken) async throws -> Bool { false }
}

private final class ConfigurableBalanceRestrictionChecker: SwapBalanceRestrictionFeatureChecker {
    var isRestricted: Bool

    init(isRestricted: Bool) {
        self.isRestricted = isRestricted
    }

    func hasSwapTotalBalanceRestriction(for token: SendSourceToken) async throws -> Bool {
        isRestricted
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

private final class SwapableTokenStub: SendSwapableToken {
    private let inner: SendSourceTokenStub

    init(blockchain: Blockchain) {
        inner = SendSourceTokenStub(blockchain: blockchain)
    }

    // MARK: - SendSourceToken proxy

    var tokenItem: TokenItem { inner.tokenItem }
    var isCustom: Bool { inner.isCustom }
    var fiatItem: FiatItem { inner.fiatItem }
    var userWalletInfo: UserWalletInfo { inner.userWalletInfo }
    var id: WalletModelId { inner.id }
    var header: TokenHeader { inner.header }
    var feeTokenItem: TokenItem { inner.feeTokenItem }
    var defaultAddressString: String { inner.defaultAddressString }
    var availableBalanceProvider: TokenBalanceProvider { inner.availableBalanceProvider }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { inner.fiatAvailableBalanceProvider }
    var allowanceService: (any AllowanceService)? { inner.allowanceService }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { inner.withdrawalNotificationProvider }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { inner.emailDataCollectorBuilder }
    var transactionHistoryEnricher: TransactionHistoryExpressDataEnriching? { get async { await inner.transactionHistoryEnricher } }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { inner.transactionDispatcherProvider }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { inner.accountModelAnalyticsProvider }
    var tangemIconProvider: any TangemIconProvider { inner.tangemIconProvider }
    var confirmTransactionPolicy: any ConfirmTransactionPolicy { inner.confirmTransactionPolicy }

    // MARK: - Swap members

    var isExemptFee: Bool { false }
    var swapAvailabilityProvider: any SwapAvailabilityProvider { SwapAvailabilityProviderStub(isSwapAvailable: true) }
    var supportedProvidersFilter: SupportedProvidersFilter { .byDifferentAddressExchangeSupport }
    var sendYieldModuleHelper: SendYieldModuleHelper? { nil }
    var operationType: ExpressOperationType { .swapAndSend }

    // MARK: - Unused in these tests

    var sendingRestrictionsProvider: any SendingRestrictionsProvider { fatalError("Unused in tests") }
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { fatalError("Unused in tests") }
    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { fatalError("Unused in tests") }
    var tokenFeeProvidersManager: any TokenFeeProvidersManager { fatalError("Unused in tests") }
    var transactionValidator: any SendTransactionValidator { fatalError("Unused in tests") }
    var transactionCreator: any SendTransactionCreator { fatalError("Unused in tests") }
    var balanceProvider: any TangemExpress.BalanceProvider { fatalError("Unused in tests") }
    var analyticsLogger: any TangemExpress.AnalyticsLogger { fatalError("Unused in tests") }
    var providerTransactionValidator: any ExpressProviderTransactionValidator { fatalError("Unused in tests") }
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

private struct SwapAvailabilityProviderStub: SwapAvailabilityProvider {
    let isSwapAvailable: Bool
}
