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
    private let presenter = SpyOnrampApplePayPresenter()
    private let analyticsLogger = NoOpOnrampSendAnalyticsLogger()

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
            applePayPresenter: presenter,
            analyticsLogger: analyticsLogger
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

    @Test("Returns .nativeApplePay when all conditions are met")
    func nativeApplePayReturnedWhenAllConditionsMet() {
        let builder = makeBuilder()

        let action = builder.make(
            provider: OnrampTestFixtures.makeProvider(),
            onWillBuy: {},
            onWidgetBuy: {}
        )

        #expect(action.isNativeApplePay)
    }

    @Test("Tapping .nativeApplePay forwards a configured request + provider + onWillBuy to the presenter")
    @MainActor
    func nativeApplePayTapForwardsToPresenter() {
        let provider = OnrampTestFixtures.makeProvider()
        let builder = makeBuilder()

        var willBuyCalled = false
        let action = builder.make(
            provider: provider,
            onWillBuy: { willBuyCalled = true },
            onWidgetBuy: {}
        )

        guard case .nativeApplePay(let onTap) = action else {
            Issue.record("Expected .nativeApplePay, got \(action)")
            return
        }

        onTap()

        #expect(presenter.presentCallCount == 1)
        #expect(presenter.lastRequest?.currencyCode == "USD")
        #expect(presenter.lastRequest?.countryCode == "US")
        #expect(presenter.lastProvider === provider)

        presenter.lastOnWillBuy?()
        #expect(willBuyCalled)
    }

    // MARK: - Helpers

    private func makeBuilder(
        isApplePayAllowed: Bool = true,
        countryCode: String = "US"
    ) -> OnrampOfferViewModelBuyActionBuilder {
        OnrampOfferViewModelBuyActionBuilder(
            geoEligibilityService: StubGeoEligibilityService(isApplePayAllowed: isApplePayAllowed),
            tokenItem: Self.testTokenItem,
            amountInput: amountInput,
            applePayPresenter: presenter,
            analyticsLogger: analyticsLogger,
            countryCode: countryCode
        )
    }

    fileprivate static let testTokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
}

// MARK: - Spies / Stubs

private final class SpyOnrampApplePayPresenter: OnrampApplePayPresenting {
    private(set) var presentCallCount = 0
    private(set) var lastRequest: PKPaymentRequest?
    private(set) var lastProvider: OnrampProvider?
    private(set) var lastOnWillBuy: (() -> Void)?

    func present(request: PKPaymentRequest, provider: OnrampProvider, onWillBuy: @escaping () -> Void) {
        presentCallCount += 1
        lastRequest = request
        lastProvider = provider
        lastOnWillBuy = onWillBuy
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

private final class NoOpOnrampSendAnalyticsLogger: OnrampSendAnalyticsLogger {
    func logSendBaseViewOpened() {}
    func logRequestSupport() {}
    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {}
    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {}

    func logOnrampOfferButtonBuy(provider: OnrampProvider) {}
    func logOnrampRecentlyUsedClicked(provider: OnrampProvider) {}
    func logOnrampFastestMethodClicked(provider: OnrampProvider) {}
    func logOnrampBestRateClicked(provider: OnrampProvider) {}
    func logOnrampButtonAllOffers() {}

    func logOnrampProvidersScreenOpened() {}
    func logOnrampProviderChosen(provider: ExpressProvider) {}

    func logOnrampPaymentMethodScreenOpened() {}
    func logOnrampPaymentMethodChosen(paymentMethod: OnrampPaymentMethod) {}

    func logFinishStepOpened() {}
    func logShareButton() {}
    func logExploreButton() {}

    func setup(onrampProvidersInput: OnrampProvidersInput) {}
    func logOnrampSelectedProvider(provider: OnrampProvider) {}
    func logOnrampButtonNAP(amount: Decimal, currencyCode: String) {}
    func logOnrampNAPScreenOpened() {}
    func logOnrampVerifyScreenOpened(amount: Decimal, currencyCode: String) {}
    func logOnrampNoticeBuyNotSupported() {}
}

private extension OnrampFiatCurrency {
    static func makeUSD() -> OnrampFiatCurrency {
        OnrampFiatCurrency(
            identity: OnrampIdentity(name: "US Dollar", code: "USD", image: nil),
            precision: 2
        )
    }
}
