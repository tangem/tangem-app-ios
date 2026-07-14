//
//  OnrampModelHandleApplePayAuthorizationTests.swift
//  TangemTests
//
//  Created on 29.04.2026.
//

import Combine
import Foundation
import PassKit
import Testing
import TangemFoundation
import struct TangemUIUtils.AlertBinder
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("OnrampModel.handleApplePayAuthorization", .serialized)
final class OnrampModelHandleApplePayAuthorizationTests {
    private let eventLog = EventLog()
    private let pendingTransactionRepositoryStub: StubOnrampPendingTransactionRepository
    private let unknownStatusRepositoryStub: StubOnrampUnknownStatusRepository

    init() {
        pendingTransactionRepositoryStub = StubOnrampPendingTransactionRepository(eventLog: eventLog)
        unknownStatusRepositoryStub = StubOnrampUnknownStatusRepository()
        InjectedValues[\.onrampPendingTransactionsRepository] = pendingTransactionRepositoryStub
        InjectedValues[\.onrampUnknownStatusRepository] = unknownStatusRepositoryStub
    }

    @Test("Native payment success → result.succeed() once with .success status")
    func nativePaymentSucceeds() async {
        let manager = StubOnrampManager(mode: .nativePayment(StubFixtures.makeNativePaymentData()))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .success)
        #expect(outcome.lastErrors.isEmpty)
    }

    @Test("Widget fallback → result.fail() once with .failure status and no errors")
    func widgetFallbackFails() async {
        let manager = StubOnrampManager(mode: .widget(StubFixtures.makeRedirectData()))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .failure)
        #expect(outcome.lastErrors.isEmpty)
    }

    /// Widget fallback now opens the KYC sheet (giving the user a chance to opt
    /// out of the widget). Pending-tx + WebView fire only when the user taps
    /// Verify, which calls back through the `onProceedToWidget` closure.
    @Test("Widget fallback opens KYC sheet on applePaySheetDidFinish after calling result.fail()")
    func widgetFallbackOpensSheetBeforeFail() async {
        let manager = StubOnrampManager(mode: .widget(StubFixtures.makeRedirectData()))
        let router = StubOnrampModelRoutable(eventLog: eventLog)
        let model = makeModel(onrampManager: manager)
        model.router = router

        _ = await runHandleAndAwaitResult(on: model)
        #expect(eventLog.events == [.resultHandler])
        #expect(router.openKYCCallCount == 0)

        await runOnMain { model.applePaySheetDidFinish() }

        #expect(eventLog.events == [.resultHandler, .kycSheetOpened])
        #expect(router.openKYCCallCount == 1)
    }

    @Test("Verify tap fires redirect → transactionDidSend recorded")
    func verifyTapRecordsTransaction() async {
        let manager = StubOnrampManager(mode: .widget(StubFixtures.makeRedirectData()))
        let router = StubOnrampModelRoutable(eventLog: eventLog)
        let model = makeModel(onrampManager: manager)
        model.router = router

        _ = await runHandleAndAwaitResult(on: model)
        await runOnMain { model.applePaySheetDidFinish() }

        await runOnMain { router.lastOnProceedToWidget?() }

        #expect(eventLog.events.contains(.transactionDidSend))
    }

    @Test("Thrown non-PassKit error → result.fail() once with scrubbed errors")
    func errorPathFailsWithScrubbedError() async {
        let stubError = NSError(domain: "TestDomain", code: 7, userInfo: nil)
        let manager = StubOnrampManager(mode: .throwsError(stubError))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .failure)
        // Non-PKPaymentErrorDomain errors are dropped by ApplePayAuthorizationResult.fail
        // so PassKit can dismiss instead of waiting for an inline correction.
        #expect(outcome.lastErrors.isEmpty)
    }

    @Test("Thrown PassKit error → result.fail(error) forwards the error")
    func errorPathForwardsPassKitError() async {
        let passKitError = NSError(
            domain: PKPaymentErrorDomain,
            code: PKPaymentError.Code.billingContactInvalidError.rawValue,
            userInfo: nil
        )
        let manager = StubOnrampManager(mode: .throwsError(passKitError))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .failure)
        #expect(outcome.lastErrors.count == 1)
        #expect((outcome.lastErrors.first as NSError?)?.domain == PKPaymentErrorDomain)
    }

    @Test("Cancellation → result.fail() once with no errors")
    func cancellationFailsWithoutError() async {
        let manager = StubOnrampManager(mode: .throwsError(CancellationError()))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .failure)
        #expect(outcome.lastErrors.isEmpty)
    }

    // MARK: - Deferred completion on applePaySheetDidFinish

    @Test("Native payment success defers openFinishStep() until applePaySheetDidFinish()")
    func finishStepFiresOnDidFinish() async {
        let manager = StubOnrampManager(mode: .nativePayment(StubFixtures.makeNativePaymentData()))
        let router = StubOnrampModelRoutable(eventLog: eventLog)
        let alertPresenter = StubSendViewAlertPresenter(eventLog: eventLog)
        let model = makeModel(onrampManager: manager)
        model.router = router
        model.alertPresenter = alertPresenter

        _ = await runHandleAndAwaitResult(on: model)
        // Sheet still up: nothing routed yet.
        #expect(!eventLog.events.contains(.finishStepOpened))

        await runOnMain { model.applePaySheetDidFinish() }

        #expect(eventLog.events.filter { $0 == .finishStepOpened }.count == 1)
        #expect(!eventLog.events.contains(.alertShown))

        // Second dismiss must not re-trigger (pending state cleared).
        await runOnMain { model.applePaySheetDidFinish() }
        #expect(eventLog.events.filter { $0 == .finishStepOpened }.count == 1)
    }

    @Test("Thrown error defers alert until applePaySheetDidFinish()")
    func errorFiresAlertOnDidFinish() async {
        let stubError = NSError(domain: "TestDomain", code: 7, userInfo: nil)
        let manager = StubOnrampManager(mode: .throwsError(stubError))
        let router = StubOnrampModelRoutable(eventLog: eventLog)
        let alertPresenter = StubSendViewAlertPresenter(eventLog: eventLog)
        let model = makeModel(onrampManager: manager)
        model.router = router
        model.alertPresenter = alertPresenter

        _ = await runHandleAndAwaitResult(on: model)
        // Sheet still up: alert not shown yet.
        #expect(!eventLog.events.contains(.alertShown))

        await runOnMain { model.applePaySheetDidFinish() }

        #expect(eventLog.events.filter { $0 == .alertShown }.count == 1)
        #expect(!eventLog.events.contains(.finishStepOpened))

        // Second dismiss must not re-trigger.
        await runOnMain { model.applePaySheetDidFinish() }
        #expect(eventLog.events.filter { $0 == .alertShown }.count == 1)
    }

    @Test("PassKit-domain error is not deferred as an alert on applePaySheetDidFinish()")
    func passKitErrorDoesNotDeferAlert() async {
        let passKitError = NSError(
            domain: PKPaymentErrorDomain,
            code: PKPaymentError.Code.billingContactInvalidError.rawValue,
            userInfo: nil
        )
        let manager = StubOnrampManager(mode: .throwsError(passKitError))
        let router = StubOnrampModelRoutable(eventLog: eventLog)
        let alertPresenter = StubSendViewAlertPresenter(eventLog: eventLog)
        let model = makeModel(onrampManager: manager)
        model.router = router
        model.alertPresenter = alertPresenter

        _ = await runHandleAndAwaitResult(on: model)
        await runOnMain { model.applePaySheetDidFinish() }

        #expect(!eventLog.events.contains(.alertShown))
        #expect(!eventLog.events.contains(.finishStepOpened))
    }

    @Test("applePaySheetDidFinish() with no pending completion is a no-op")
    func didFinishWithoutPendingCompletionDoesNothing() async {
        let manager = StubOnrampManager(mode: .nativePayment(StubFixtures.makeNativePaymentData()))
        let router = StubOnrampModelRoutable(eventLog: eventLog)
        let alertPresenter = StubSendViewAlertPresenter(eventLog: eventLog)
        let model = makeModel(onrampManager: manager)
        model.router = router
        model.alertPresenter = alertPresenter

        await runOnMain { model.applePaySheetDidFinish() }

        #expect(!eventLog.events.contains(.finishStepOpened))
        #expect(!eventLog.events.contains(.alertShown))
    }

    // MARK: - Timeout fallback ([REDACTED_INFO])

    @Test("Express timeout → /history/onramp returns matching tx → result.succeed() and pending tx recorded")
    func timeoutWithHistoryMatchSucceeds() async {
        let historyItem = StubFixtures.makeHistoryItem(toContractAddress: ExpressConstants.coinContractAddress, toNetwork: "ethereum")
        let manager = StubOnrampManager(mode: .throwsError(StubFixtures.makeExpressTimeoutError()), historyMode: .returns([historyItem]))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .success)
        #expect(outcome.lastErrors.isEmpty)
        #expect(eventLog.events.contains(.transactionAddedFromHistory))
        #expect(unknownStatusRepositoryStub.trackedRecords.isEmpty)
    }

    @Test("Express timeout → /history/onramp empty → result.fail() and no unknown-status record")
    func timeoutWithEmptyHistoryFails() async {
        let manager = StubOnrampManager(mode: .throwsError(StubFixtures.makeExpressTimeoutError()), historyMode: .returns([]))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .failure)
        #expect(!eventLog.events.contains(.transactionDidSend))
        #expect(unknownStatusRepositoryStub.trackedRecords.isEmpty)
    }

    @Test("Express timeout → /history/onramp throws → result.fail() and unknown-status record persisted")
    func timeoutWithHistoryFailureMarksUnknown() async {
        let manager = StubOnrampManager(
            mode: .throwsError(StubFixtures.makeExpressTimeoutError()),
            historyMode: .throwsError(URLError(.notConnectedToInternet))
        )
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .failure)
        #expect(!eventLog.events.contains(.transactionDidSend))
        #expect(unknownStatusRepositoryStub.trackedRecords.count == 1)
        #expect(unknownStatusRepositoryStub.trackedRecords.first?.payoutAddress == "0xtest")
    }

    // MARK: - Helpers

    private func makeModel(onrampManager: OnrampManager) -> OnrampModel {
        OnrampModel(
            userWalletId: "test-wallet",
            tokenItem: .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)),
            defaultAddressString: "0xtest",
            onrampManager: onrampManager,
            onrampDataRepository: StubOnrampDataRepository(),
            onrampRepository: StubOnrampRepository(),
            analyticsLogger: NoOpOnrampSendAnalyticsLogger(),
            autoupdatingTimer: AutoupdatingTimer(),
            redirectSettingsBuilder: OnrampRedirectSettingsBuilder(),
            predefinedValues: .init(amount: nil),
            isHistoryFallbackEnabled: true
        )
    }

    private func runHandleAndAwaitResult(on model: OnrampModel) async -> ResultOutcome {
        let recorder = ResultHandlerRecorder(eventLog: eventLog)
        let result = ApplePayAuthorizationResult(
            provider: OnrampTestFixtures.makeProvider(),
            applePayResult: StubFixtures.makeApplePayResult(),
            resultHandler: { recorder.record($0) }
        )

        await withCheckedContinuation { continuation in
            recorder.onFirstCall = { continuation.resume() }
            model.handleApplePayAuthorization(result)
        }

        return recorder.snapshot
    }
}

// MARK: - EventLog

private enum RecordedEvent: Equatable {
    case transactionDidSend
    case transactionAddedFromHistory
    case resultHandler
    case kycSheetOpened
    case finishStepOpened
    case alertShown
}

private final class EventLog: Sendable {
    private let state = OSAllocatedUnfairLock<[RecordedEvent]>(initialState: [])

    func append(_ event: RecordedEvent) {
        state.withLock { $0.append(event) }
    }

    var events: [RecordedEvent] {
        state.withLock { $0 }
    }
}

// MARK: - ResultHandlerRecorder

private struct ResultOutcome {
    let callCount: Int
    let lastStatus: PKPaymentAuthorizationStatus?
    let lastErrors: [Error]
}

private final class ResultHandlerRecorder: Sendable {
    private struct State {
        var callCount: Int = 0
        var lastStatus: PKPaymentAuthorizationStatus?
        var lastErrors: [Error] = []
        var onFirstCall: (() -> Void)?
    }

    private let state = OSAllocatedUnfairLock<State>(initialState: State())
    private let eventLog: EventLog

    init(eventLog: EventLog) {
        self.eventLog = eventLog
    }

    var onFirstCall: (() -> Void)? {
        get { state.withLock { $0.onFirstCall } }
        set { state.withLock { $0.onFirstCall = newValue } }
    }

    func record(_ result: PKPaymentAuthorizationResult) {
        eventLog.append(.resultHandler)
        let onFirst: (() -> Void)? = state.withLock { state in
            state.callCount += 1
            state.lastStatus = result.status
            state.lastErrors = result.errors
            return state.callCount == 1 ? state.onFirstCall : nil
        }
        onFirst?()
    }

    var snapshot: ResultOutcome {
        state.withLock { state in
            ResultOutcome(
                callCount: state.callCount,
                lastStatus: state.lastStatus,
                lastErrors: state.lastErrors
            )
        }
    }
}

// MARK: - StubOnrampManager

private actor StubOnrampManager: OnrampManager {
    enum Mode {
        case nativePayment(OnrampNativePaymentData)
        case widget(OnrampRedirectData)
        case throwsError(Error)
    }

    enum HistoryMode {
        case unused
        case returns([OnrampTransaction])
        case throwsError(Error)
    }

    private let mode: Mode
    private let historyMode: HistoryMode

    init(mode: Mode, historyMode: HistoryMode = .unused) {
        self.mode = mode
        self.historyMode = historyMode
    }

    func initialSetupCountry() async throws -> OnrampCountry {
        fatalError("not used")
    }

    func setupProviders(request: OnrampPairRequestItem) async throws -> ProvidersList {
        fatalError("not used")
    }

    func setupQuotes(in providers: ProvidersList, amount: OnrampUpdatingAmount) async throws -> (list: ProvidersList, provider: OnrampProvider) {
        fatalError("not used")
    }

    func loadRedirectData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings) async throws -> OnrampRedirectData {
        fatalError("not used")
    }

    func loadNativePaymentData(
        provider: OnrampProvider,
        redirectSettings: OnrampRedirectSettings,
        applePayResult: OnrampApplePayResult
    ) async throws -> OnrampDataResult {
        switch mode {
        case .nativePayment(let data): return .nativePayment(data)
        case .widget(let data): return .widget(data)
        case .throwsError(let error): throw error
        }
    }

    func findRecentOnrampTransaction(
        payoutAddress: String,
        since: Date,
        toContractAddress: String,
        toNetwork: String,
        providerId: ExpressProvider.Id,
        limit: Int?
    ) async throws -> OnrampTransaction? {
        switch historyMode {
        case .unused: return nil
        case .returns(let items):
            return OnrampHistoryMatcher.findMatch(
                in: items,
                since: since,
                toContractAddress: toContractAddress,
                toNetwork: toNetwork,
                providerId: providerId
            )
        case .throwsError(let error): throw error
        }
    }
}

// MARK: - StubOnrampUnknownStatusRepository

private final class StubOnrampUnknownStatusRepository: OnrampUnknownStatusRepository {
    private let state = OSAllocatedUnfairLock<[OnrampUnknownStatusRecord]>(initialState: [])

    var recordsPublisher: AnyPublisher<[OnrampUnknownStatusRecord], Never> {
        Just(state.withLock { $0 }).eraseToAnyPublisher()
    }

    func track(_ record: OnrampUnknownStatusRecord) {
        state.withLock { $0.append(record) }
    }

    func pendingRecoveryCandidates(userWalletId: String, toContractAddress: String, toNetwork: String) -> [OnrampUnknownStatusRecord] {
        state.withLock { $0 }
    }

    func noteRecoveryProbe(recordId: String) {}

    func untrack(recordId: String) {
        state.withLock { $0.removeAll { $0.id == recordId } }
    }

    var trackedRecords: [OnrampUnknownStatusRecord] {
        state.withLock { $0 }
    }
}

// MARK: - Stub repositories / loggers

private actor StubOnrampDataRepository: OnrampDataRepository {
    func providers() async throws -> [ExpressProvider] { [] }
    func paymentMethods() async throws -> [OnrampPaymentMethod] { [] }
    func countries() async throws -> [OnrampCountry] { [] }
    func currencies() async throws -> [OnrampFiatCurrency] { [] }
}

private struct StubOnrampRepository: OnrampRepository {
    var preferenceCountry: OnrampCountry? { nil }
    var preferenceCurrency: OnrampFiatCurrency? { nil }
    var preferencePublisher: AnyPublisher<OnrampPreference, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?) {}
}

private final class StubOnrampPendingTransactionRepository: OnrampPendingTransactionRepository {
    private let eventLog: EventLog

    init(eventLog: EventLog) {
        self.eventLog = eventLog
    }

    var transactions: [OnrampPendingTransactionRecord] { [] }
    var transactionsPublisher: AnyPublisher<[OnrampPendingTransactionRecord], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func updateItems(_ items: [OnrampPendingTransactionRecord]) {}
    func onrampTransactionDidSend(_ txData: SentOnrampTransactionData, userWalletId: String) {
        eventLog.append(.transactionDidSend)
    }

    func addRecordIfNeeded(_ record: OnrampPendingTransactionRecord) {
        eventLog.append(.transactionAddedFromHistory)
    }

    func hideSwapTransaction(with id: String) {}
}

private final class StubOnrampModelRoutable: OnrampModelRoutable, Sendable {
    private struct State {
        var openKYCCallCount: Int = 0
        var lastOnProceedToWidget: (() -> Void)?
    }

    private let state = OSAllocatedUnfairLock<State>(initialState: State())
    private let eventLog: EventLog

    init(eventLog: EventLog) {
        self.eventLog = eventLog
    }

    var openKYCCallCount: Int { state.withLock { $0.openKYCCallCount } }
    var lastOnProceedToWidget: (() -> Void)? { state.withLock { $0.lastOnProceedToWidget } }

    func openOnrampCountryBottomSheet(country: OnrampCountry) {}
    func openOnrampCountrySelectorView() {}
    func openOnrampRedirecting() {}
    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void) {}
    func openFinishStep() {
        eventLog.append(.finishStepOpened)
    }

    func openOnrampKYCVerification(provider: OnrampProvider, onProceedToWidget: @escaping () -> Void) {
        eventLog.append(.kycSheetOpened)
        state.withLock { state in
            state.openKYCCallCount += 1
            state.lastOnProceedToWidget = onProceedToWidget
        }
    }
}

private final class StubSendViewAlertPresenter: SendViewAlertPresenter {
    private let eventLog: EventLog

    init(eventLog: EventLog) {
        self.eventLog = eventLog
    }

    func showAlert(_ alert: AlertBinder) {
        eventLog.append(.alertShown)
    }
}

private final class NoOpOnrampSendAnalyticsLogger: OnrampSendAnalyticsLogger {
    // SendBaseViewAnalyticsLogger
    func logSendBaseViewOpened() {}
    func logRequestSupport() {}
    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {}
    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {}

    // SendOnrampOffersAnalyticsLogger
    func logOnrampOfferButtonBuy(provider: OnrampProvider) {}
    func logOnrampRecentlyUsedClicked(provider: OnrampProvider) {}
    func logOnrampFastestMethodClicked(provider: OnrampProvider) {}
    func logOnrampBestRateClicked(provider: OnrampProvider) {}
    func logOnrampButtonAllOffers() {}

    // SendOnrampProvidersAnalyticsLogger
    func logOnrampProvidersScreenOpened() {}
    func logOnrampProviderChosen(provider: ExpressProvider) {}

    // SendOnrampPaymentMethodAnalyticsLogger
    func logOnrampPaymentMethodScreenOpened() {}
    func logOnrampPaymentMethodChosen(paymentMethod: OnrampPaymentMethod) {}

    // SendFinishAnalyticsLogger
    func logFinishStepOpened() {}
    func logShareButton() {}
    func logExploreButton() {}

    // OnrampSendAnalyticsLogger own
    func setup(onrampProvidersInput: OnrampProvidersInput) {}
    func logOnrampSelectedProvider(provider: OnrampProvider) {}
    func logOnrampButtonNAP(amount: Decimal, currencyCode: String) {}
    func logOnrampNAPScreenOpened() {}
    func logOnrampVerifyScreenOpened(amount: Decimal, currencyCode: String) {}
    func logOnrampNoticeBuyNotSupported() {}
}

// MARK: - Fixtures

private enum StubFixtures {
    static func makeNativePaymentData() -> OnrampNativePaymentData {
        OnrampNativePaymentData(
            txId: "native-tx",
            fromAmount: 100,
            fromCurrencyCode: "USD",
            externalTxId: nil,
            externalTxURL: nil
        )
    }

    static func makeRedirectData() -> OnrampRedirectData {
        OnrampRedirectData(
            txId: "widget-tx",
            widgetURL: URL(string: "https://example.com/widget")!,
            redirectURL: URL(string: "https://example.com/redirect")!,
            fromAmount: 100,
            fromCurrencyCode: "USD",
            externalTxId: nil,
            externalTxURL: nil
        )
    }

    static func makeExpressTimeoutError() -> Error {
        URLError(.timedOut)
    }

    static func makeHistoryItem(toContractAddress: String, toNetwork: String) -> OnrampTransaction {
        OnrampTransaction(
            txId: "history-tx-1",
            providerId: "mercuryo",
            status: .paid,
            failReason: nil,
            externalTx: ExternalTxInfo(id: "external-1", url: nil),
            payOut: PayOutInfo(address: "0xpayout", hash: nil),
            from: OnrampHistoryFiatAsset(currencyCode: "USD", amount: 100),
            to: OnrampHistoryCryptoAsset(
                currency: ExpressCurrency(contractAddress: toContractAddress, network: toNetwork),
                amount: 0.05,
                actualAmount: nil,
                decimals: 18
            ),
            paymentMethod: "apple-pay",
            countryCode: "US",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static func makeApplePayResult() -> OnrampApplePayResult {
        OnrampApplePayResult(
            paymentToken: "token",
            userData: OnrampNativePaymentRequestItem.UserData(
                email: "user@example.com",
                firstName: nil,
                lastName: nil,
                billingAddress: nil
            )
        )
    }
}
