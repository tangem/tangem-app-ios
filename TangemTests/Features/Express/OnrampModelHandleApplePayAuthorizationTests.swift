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
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("OnrampModel.handleApplePayAuthorization", .serialized)
final class OnrampModelHandleApplePayAuthorizationTests {
    private let eventLog = EventLog()
    private let pendingTransactionRepositoryStub: StubOnrampPendingTransactionRepository

    init() {
        pendingTransactionRepositoryStub = StubOnrampPendingTransactionRepository(eventLog: eventLog)
        InjectedValues[\.onrampPendingTransactionsRepository] = pendingTransactionRepositoryStub
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

    /// Regression test for B1: in the widget-fallback branch the redirect navigation
    /// (and its pending-transaction record) must be scheduled *before* PassKit is
    /// told the payment failed, so the webview is queued onto main before the
    /// PassKit sheet starts dismissing.
    @Test("Widget fallback schedules redirect navigation before calling result.fail()")
    func widgetFallbackOrdersRedirectBeforeFail() async {
        let manager = StubOnrampManager(mode: .widget(StubFixtures.makeRedirectData()))
        let model = makeModel(onrampManager: manager)

        _ = await runHandleAndAwaitResult(on: model)

        #expect(eventLog.events == [.transactionDidSend, .resultHandler])
    }

    @Test("Thrown error → result.fail(error) once with the wrapped error")
    func errorPathFailsWithError() async {
        let stubError = NSError(domain: "TestDomain", code: 7, userInfo: nil)
        let manager = StubOnrampManager(mode: .throwsError(stubError))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .failure)
        #expect(outcome.lastErrors.count == 1)
        #expect((outcome.lastErrors.first as NSError?)?.domain == "TestDomain")
        #expect((outcome.lastErrors.first as NSError?)?.code == 7)
    }

    @Test("Cancellation → result.fail(CancellationError) once")
    func cancellationFailsWithCancellationError() async {
        let manager = StubOnrampManager(mode: .throwsError(CancellationError()))
        let model = makeModel(onrampManager: manager)

        let outcome = await runHandleAndAwaitResult(on: model)

        #expect(outcome.callCount == 1)
        #expect(outcome.lastStatus == .failure)
        #expect(outcome.lastErrors.count == 1)
        // PassKit bridges Error elements to NSError; CancellationError lands as Domain="Swift.CancellationError".
        #expect((outcome.lastErrors.first as NSError?)?.domain == "Swift.CancellationError")
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
            predefinedValues: .init(amount: nil)
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
    case resultHandler
}

private final class EventLog: @unchecked Sendable {
    private let criticalSection = OSAllocatedUnfairLock()
    private var _events: [RecordedEvent] = []

    func append(_ event: RecordedEvent) {
        criticalSection { _events.append(event) }
    }

    var events: [RecordedEvent] {
        criticalSection { _events }
    }
}

// MARK: - ResultHandlerRecorder

private final class ResultHandlerRecorder: @unchecked Sendable {
    private let criticalSection = OSAllocatedUnfairLock()
    private let eventLog: EventLog
    private var _callCount: Int = 0
    private var _lastStatus: PKPaymentAuthorizationStatus?
    private var _lastErrors: [Error] = []
    private var _onFirstCall: (() -> Void)?

    init(eventLog: EventLog) {
        self.eventLog = eventLog
    }

    var onFirstCall: (() -> Void)? {
        get { criticalSection { _onFirstCall } }
        set { criticalSection { _onFirstCall = newValue } }
    }

    func record(_ result: PKPaymentAuthorizationResult) {
        eventLog.append(.resultHandler)
        let onFirst: (() -> Void)? = criticalSection {
            _callCount += 1
            _lastStatus = result.status
            _lastErrors = result.errors
            return _callCount == 1 ? _onFirstCall : nil
        }
        onFirst?()
    }

    var snapshot: ResultOutcome {
        criticalSection {
            ResultOutcome(
                callCount: _callCount,
                lastStatus: _lastStatus,
                lastErrors: _lastErrors
            )
        }
    }
}

private struct ResultOutcome {
    let callCount: Int
    let lastStatus: PKPaymentAuthorizationStatus?
    let lastErrors: [Error]
}

// MARK: - StubOnrampManager

private actor StubOnrampManager: OnrampManager {
    enum Mode {
        case nativePayment(OnrampNativePaymentData)
        case widget(OnrampRedirectData)
        case throwsError(Error)
    }

    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
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

    func hideSwapTransaction(with id: String) {}
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
}

// MARK: - Fixtures

private enum StubFixtures {
    static func makeNativePaymentData() -> OnrampNativePaymentData {
        OnrampNativePaymentData(
            txId: "native-tx",
            fromAmount: 100,
            fromCurrencyCode: "USD",
            externalTxId: nil,
            externalTxUrl: nil
        )
    }

    static func makeRedirectData() -> OnrampRedirectData {
        OnrampRedirectData(
            txId: "widget-tx",
            widgetUrl: URL(string: "https://example.com/widget")!,
            redirectUrl: URL(string: "https://example.com/redirect")!,
            fromAmount: 100,
            fromCurrencyCode: "USD",
            externalTxId: nil,
            externalTxUrl: nil
        )
    }

    static func makeApplePayResult() -> OnrampApplePayResult {
        OnrampApplePayResult(
            paymentToken: "token",
            userData: OnrampNativePaymentRequestItem.UserData(
                email: nil,
                firstName: nil,
                lastName: nil,
                billingAddress: nil
            )
        )
    }
}
