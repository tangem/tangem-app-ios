//
//  OnrampOfferViewModelBuyActionBuilderTests.swift
//  TangemTests
//
//  Created on 28.04.2026.
//

import Combine
import Foundation
import PassKit
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("OnrampOfferViewModelBuyActionBuilder")
final class OnrampOfferViewModelBuyActionBuilderTests {
    /// Stored to keep the `weak var amountInput` reference inside the builder alive for the duration of each test.
    private let amountInput = StubOnrampAmountInput(fiatCurrency: .makeUSD())

    // MARK: - Widget (button) path

    @Test("Returns .button when geo does not allow Apple Pay")
    func widgetWhenGeoDisallowsApplePay() {
        let builder = makeBuilder(isApplePayAllowed: false)

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        #expect(action.isButton)
    }

    @Test("Returns .button when payment method is not Apple Pay")
    func widgetWhenPaymentMethodIsNotApplePay() {
        let builder = makeBuilder()

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(paymentMethodId: "card"),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        #expect(action.isButton)
    }

    @Test("Returns .button when quote is missing")
    func widgetWhenQuoteIsMissing() {
        let builder = makeBuilder()

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(state: .loading),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        #expect(action.isButton)
    }

    @Test("Returns .button when nativePaymentAvailable is false")
    func widgetWhenNativePaymentDisabled() {
        let quote = OnrampQuote(expectedAmount: 100, nativePaymentAvailable: false, quoteId: "id")
        let builder = makeBuilder()

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(state: .loaded(quote)),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        #expect(action.isButton)
    }

    @Test("Returns .button when quoteId is nil")
    func widgetWhenQuoteIdIsNil() {
        let quote = OnrampQuote(expectedAmount: 100, nativePaymentAvailable: true, quoteId: nil)
        let builder = makeBuilder()

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(state: .loaded(quote)),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        #expect(action.isButton)
    }

    @Test("Returns .button when amount is nil")
    func widgetWhenAmountIsNil() {
        let builder = makeBuilder()

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(amount: nil),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        #expect(action.isButton)
    }

    @Test("Returns .button when fiatCurrency is nil")
    func widgetWhenFiatCurrencyIsNil() {
        let nilCurrencyInput = StubOnrampAmountInput(fiatCurrency: nil)
        let builder = OnrampOfferViewModelBuyActionBuilder(
            geoEligibilityService: StubGeoEligibilityService(isApplePayAllowed: true),
            tokenItem: Self.testTokenItem,
            amountInput: nilCurrencyInput,
            authorizationHandler: nil
        )

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        #expect(action.isButton)
    }

    @Test("Widget .button invokes onWillBuy and onWidgetBuy when tapped")
    func widgetButtonInvokesBothCallbacks() {
        let builder = makeBuilder(isApplePayAllowed: false)

        var willBuyCalled = false
        var widgetBuyCalled = false
        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(),
            onWillBuy: { willBuyCalled = true },
            onWidgetBuy: { widgetBuyCalled = true }
        )

        guard case .button(let onTap) = action else {
            Issue.record("Expected .button, got \(action)")
            return
        }

        onTap()

        #expect(willBuyCalled)
        #expect(widgetBuyCalled)
    }

    // MARK: - Native Apple Pay path

    @Test("Returns .nativeApplePay with a configured PKPaymentRequest when all conditions are met")
    func nativeApplePayReturnedWhenAllConditionsMet() {
        let builder = makeBuilder()

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        guard case .nativeApplePay(let request, _) = action else {
            Issue.record("Expected .nativeApplePay, got \(action)")
            return
        }

        #expect(request.currencyCode == "USD")
        #expect(request.countryCode == "US")
    }

    @Test("Phase .willAuthorize triggers onWillBuy")
    func willAuthorizeFiresOnWillBuy() {
        let builder = makeBuilder()

        var willBuyCalled = false
        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(),
            onWillBuy: { willBuyCalled = true },
            onWidgetBuy: {}
        )

        guard case .nativeApplePay(_, let onPhaseChange) = action else {
            Issue.record("Expected .nativeApplePay")
            return
        }

        onPhaseChange(.willAuthorize)

        #expect(willBuyCalled)
    }

    @Test("Phase .didAuthorize forwards a bundled ApplePayAuthorizationResult to the handler")
    func didAuthorizeForwardsToHandler() {
        let handler = SpyApplePayButtonPaymentAuthorizationHandler()
        let provider = OnrampTestFixtures.makeProvider()
        let builder = makeBuilder(authorizationHandler: handler)

        var willBuyCalled = false
        let action = builder.make(
            provider: provider,
            onWillBuy: { willBuyCalled = true },
            onWidgetBuy: {}
        )

        guard case .nativeApplePay(_, let onPhaseChange) = action else {
            Issue.record("Expected .nativeApplePay")
            return
        }

        var resultHandlerInvocations = 0
        onPhaseChange(.didAuthorize(payment: StubPKPayment(), resultHandler: { _ in resultHandlerInvocations += 1 }))

        #expect(!willBuyCalled)
        #expect(handler.callCount == 1)
        #expect(handler.lastResult?.provider === provider)

        handler.lastResult?.succeed()
        #expect(resultHandlerInvocations == 1)
    }

    @Test("Phase .didAuthorize fails the authorization when the handler is nil")
    func didAuthorizeFailsWhenHandlerNil() {
        let builder = makeBuilder(authorizationHandler: nil)

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        guard case .nativeApplePay(_, let onPhaseChange) = action else {
            Issue.record("Expected .nativeApplePay")
            return
        }

        var capturedStatus: PKPaymentAuthorizationStatus?
        onPhaseChange(.didAuthorize(payment: StubPKPayment(), resultHandler: { result in
            capturedStatus = result.status
        }))

        #expect(capturedStatus == .failure)
    }

    // MARK: - Helpers

    private func makeBuilder(
        authorizationHandler: ApplePayButtonPaymentAuthorizationHandler? = nil,
        isApplePayAllowed: Bool = true,
        countryCode: String = "US"
    ) -> OnrampOfferViewModelBuyActionBuilder {
        OnrampOfferViewModelBuyActionBuilder(
            geoEligibilityService: StubGeoEligibilityService(isApplePayAllowed: isApplePayAllowed),
            tokenItem: Self.testTokenItem,
            amountInput: amountInput,
            authorizationHandler: authorizationHandler,
            countryCode: countryCode
        )
    }

    fileprivate static let testTokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
}

// MARK: - Spies / Stubs

private final class SpyApplePayButtonPaymentAuthorizationHandler: ApplePayButtonPaymentAuthorizationHandler {
    private(set) var lastResult: ApplePayAuthorizationResult?
    private(set) var callCount: Int = 0

    func handleApplePayAuthorization(_ result: ApplePayAuthorizationResult) {
        lastResult = result
        callCount += 1
    }
}

private final class StubOnrampAmountInput: OnrampAmountInput {
    var fiatCurrency: OnrampFiatCurrency?
    var fiatCurrencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> { Just(fiatCurrency).eraseToAnyPublisher() }
    var amount: Decimal? = 100
    var amountPublisher: AnyPublisher<Decimal?, Never> { Just(amount).eraseToAnyPublisher() }

    init(fiatCurrency: OnrampFiatCurrency?) {
        self.fiatCurrency = fiatCurrency
    }
}

private struct StubGeoEligibilityService: GeoEligibilityService {
    let isApplePayAllowed: Bool
    var isUK: Bool { false }

    func initialize() {}
    func waitForGeoIpRegionIfNeeded() async {}
}

private final class StubPKPaymentToken: PKPaymentToken {
    override var paymentData: Data { Data() }
}

private final class StubPKPayment: PKPayment {
    override var token: PKPaymentToken { StubPKPaymentToken() }
    override var shippingContact: PKContact? {
        let contact = PKContact()
        contact.emailAddress = "test@example.com"
        return contact
    }
}

private extension OnrampFiatCurrency {
    static func makeUSD() -> OnrampFiatCurrency {
        OnrampFiatCurrency(
            identity: OnrampIdentity(name: "US Dollar", code: "USD", image: nil),
            precision: 2
        )
    }
}
