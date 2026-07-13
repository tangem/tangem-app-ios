//
//  OnrampModelUnsupportedTokenTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("OnrampModel unsupported-token notice", .serialized)
final class OnrampModelUnsupportedTokenTests: LeakTrackingTestSuite {
    typealias SUT = OnrampModel

    private let tokenItem: TokenItem = .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))

    /// `InjectedValues` is process-global mutable state; snapshot it on setup and restore on teardown
    /// so the stub never leaks into other tests (avoids order-dependent flakiness).
    private let originalExpressProvider: ExpressAvailabilityProvider

    override init() {
        originalExpressProvider = InjectedValues[\.expressAvailabilityProvider]
        super.init()
    }

    deinit {
        InjectedValues[\.expressAvailabilityProvider] = originalExpressProvider
    }

    // MARK: - unsupportedTokenPublisher

    @Test("onramp .unavailable → token only when resolved (.updated)")
    func unavailableResolvedReturnsToken() {
        #expect(firstUnsupportedToken(onramp: .unavailable, state: .updated) == tokenItem)
        // `.unavailable` during `.updating` may be a stale cache value that the in-flight load flips — stay silent.
        #expect(firstUnsupportedToken(onramp: .unavailable, state: .updating) == nil)
    }

    @Test(".notLoaded is unknown, not unsupported — nil even when the global state is .updated")
    func notLoadedUpdatedReturnsNil() {
        // Keying the notice off a stale/foreign global `.updated` while this token is still `.notLoaded`
        // would false-show "not supported" for a token that may resolve as supported.
        #expect(firstUnsupportedToken(onramp: .notLoaded, state: .updated) == nil)
    }

    @Test(".notLoaded while still loading → nil")
    func notLoadedUpdatingReturnsNil() {
        #expect(firstUnsupportedToken(onramp: .notLoaded, state: .updating) == nil)
    }

    @Test(".notLoaded after a failed load → nil (handled by the refresh notice instead)")
    func notLoadedFailedReturnsNil() {
        #expect(firstUnsupportedToken(onramp: .notLoaded, state: .failed(error: URLError(.badServerResponse))) == nil)
    }

    @Test("onramp .available → nil")
    func availableReturnsNil() {
        #expect(firstUnsupportedToken(onramp: .available, state: .updated) == nil)
    }

    // MARK: - Analytics fires once

    @Test("Notice - Buy Not Supported fires exactly once for a resolved unsupported token")
    func analyticsFiresOnceForUnsupported() {
        let (sut, _, analytics) = makeSUT(onramp: .unavailable, state: .updated)

        withExtendedLifetime(sut) {
            #expect(analytics.count == 1)
        }
    }

    @Test("Notice - Buy Not Supported does not fire for a not-loaded token even when the global state is .updated")
    func analyticsDoesNotFireForNotLoadedToken() {
        // A stale global `.updated` (e.g. from another token's batch) must not log a token that may still
        // resolve as supported once its own /assets load completes — analytics fires only on `.unavailable`.
        let (sut, _, analytics) = makeSUT(onramp: .notLoaded, state: .updated)

        withExtendedLifetime(sut) {
            #expect(analytics.isEmpty)
        }
    }

    @Test("Notice - Buy Not Supported does not fire for a supported token")
    func analyticsDoesNotFireForAvailable() {
        let (sut, _, analytics) = makeSUT(onramp: .available, state: .updated)

        withExtendedLifetime(sut) {
            #expect(analytics.isEmpty)
        }
    }

    @Test("Notice - Buy Not Supported does not fire while availability is unresolved")
    func analyticsDoesNotFireWhileUnresolved() {
        let (loadingSUT, _, loadingAnalytics) = makeSUT(onramp: .notLoaded, state: .updating)
        let (failedSUT, _, failedAnalytics) = makeSUT(onramp: .notLoaded, state: .failed(error: URLError(.badServerResponse)))

        withExtendedLifetime((loadingSUT, failedSUT)) {
            #expect(loadingAnalytics.isEmpty)
            #expect(failedAnalytics.isEmpty)
        }
    }

    @Test("Notice - Buy Not Supported does not fire on `.unavailable` while still updating")
    func analyticsDoesNotFireForUnavailableWhileUpdating() {
        // A stale cached `.unavailable` during `.updating` may flip to `.available` once the in-flight load completes.
        let (sut, _, analytics) = makeSUT(onramp: .unavailable, state: .updating)

        withExtendedLifetime(sut) {
            #expect(analytics.isEmpty)
        }
    }
}

// MARK: - Helpers

private extension OnrampModelUnsupportedTokenTests {
    func firstUnsupportedToken(onramp: TokenItemExpressState, state: ExpressAvailabilityUpdateState) -> TokenItem? {
        let (sut, _, _) = makeSUT(onramp: onramp, state: state)

        var emitted: [TokenItem?] = []
        let cancellable = sut.unsupportedTokenPublisher.sink { emitted.append($0) }
        cancellable.cancel()

        // Guard against a vacuous pass: the publisher must synchronously emit exactly one value.
        #expect(emitted.count == 1)
        return withExtendedLifetime(sut) { emitted.first ?? nil }
    }

    func makeSUT(
        onramp: TokenItemExpressState,
        state: ExpressAvailabilityUpdateState
    ) -> (sut: SUT, provider: ExpressAvailabilityProviderStub, analytics: AnalyticsLoggerSpy) {
        let provider = ExpressAvailabilityProviderStub(onramp: onramp, state: state)
        let analytics = AnalyticsLoggerSpy()
        InjectedValues[\.expressAvailabilityProvider] = provider

        let sut = OnrampModel(
            userWalletId: "test-wallet",
            tokenItem: tokenItem,
            defaultAddressString: "0xtest",
            onrampManager: OnrampManagerStub(),
            onrampDataRepository: OnrampDataRepositoryStub(),
            onrampRepository: OnrampRepositoryStub(),
            analyticsLogger: analytics,
            autoupdatingTimer: AutoupdatingTimer(),
            redirectSettingsBuilder: OnrampRedirectSettingsBuilder(),
            predefinedValues: .init(amount: nil),
            isHistoryFallbackEnabled: true
        )

        return (trackForMemoryLeaks(sut), provider, analytics)
    }
}

// MARK: - ExpressAvailabilityProviderStub

private final class ExpressAvailabilityProviderStub: ExpressAvailabilityProvider {
    let stateSubject: CurrentValueSubject<ExpressAvailabilityUpdateState, Never>
    private let onrampStateValue: TokenItemExpressState

    init(onramp: TokenItemExpressState, state: ExpressAvailabilityUpdateState) {
        onrampStateValue = onramp
        stateSubject = .init(state)
    }

    var hasCache: Bool { true }
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var expressAvailabilityUpdateStateValue: ExpressAvailabilityUpdateState { stateSubject.value }
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> { stateSubject.eraseToAnyPublisher() }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState { .notLoaded }
    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState { onrampStateValue }
    func canSwap(tokenItem: TokenItem) -> Bool { false }
    func canOnramp(tokenItem: TokenItem) -> Bool { onrampStateValue == .available }
    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {}
}

// MARK: - AnalyticsLoggerSpy

private final class AnalyticsLoggerSpy: OnrampManagementModelAnalyticsLogger {
    private let noticeCount = OSAllocatedUnfairLock(initialState: 0)

    var count: Int { noticeCount.withLock { $0 } }
    var isEmpty: Bool { count == 0 }

    func logOnrampSelectedProvider(provider: OnrampProvider) {}
    func logOnrampVerifyScreenOpened(amount: Decimal, currencyCode: String) {}
    func logOnrampNoticeBuyNotSupported() { noticeCount.withLock { $0 += 1 } }
}

// MARK: - Stub repositories / manager

private actor OnrampManagerStub: OnrampManager {
    func initialSetupCountry() async throws -> OnrampCountry { fatalError("not used") }
    func setupProviders(request: OnrampPairRequestItem) async throws -> ProvidersList { fatalError("not used") }
    func setupQuotes(in providers: ProvidersList, amount: OnrampUpdatingAmount) async throws -> (list: ProvidersList, provider: OnrampProvider) { fatalError("not used") }
    func loadRedirectData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings) async throws -> OnrampRedirectData { fatalError("not used") }
    func loadNativePaymentData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings, applePayResult: OnrampApplePayResult) async throws -> OnrampDataResult { fatalError("not used") }
    func findRecentOnrampTransaction(
        payoutAddress: String,
        since: Date,
        toContractAddress: String,
        toNetwork: String,
        providerId: ExpressProvider.Id,
        limit: Int?
    ) async throws -> OnrampTransaction? { fatalError("not used") }
}

private actor OnrampDataRepositoryStub: OnrampDataRepository {
    func providers() async throws -> [ExpressProvider] { [] }
    func paymentMethods() async throws -> [OnrampPaymentMethod] { [] }
    func countries() async throws -> [OnrampCountry] { [] }
    func currencies() async throws -> [OnrampFiatCurrency] { [] }
}

private struct OnrampRepositoryStub: OnrampRepository {
    var preferenceCountry: OnrampCountry? { nil }
    var preferenceCurrency: OnrampFiatCurrency? { nil }
    var preferencePublisher: AnyPublisher<OnrampPreference, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func updatePreference(country: OnrampCountry?, currency: OnrampFiatCurrency?) {}
}
