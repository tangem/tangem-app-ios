//
//  OnrampMoonPayBalanceProcessingTimeTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("Onramp MoonPay balance processing time")
struct OnrampMoonPayBalanceProcessingTimeTests {
    @Test("MoonPay balance is shown as instant")
    func moonpayBalanceIsInstant() {
        let type = OnrampPaymentMethod.MethodType.from(id: "moonpay-balance")

        #expect(type == .moonpayBalance)
        #expect(type.processingTime == .instant)
    }

    @Test("MoonPay balance keeps its place behind SEPA at the same amount")
    func moonpayBalanceSortsAfterSepa() {
        let moonpayBalance = OnrampTestFixtures.makeProvider(providerId: "moonpay", paymentMethodId: "moonpay-balance")
        let sepa = OnrampTestFixtures.makeProvider(providerId: "moonpay", paymentMethodId: "sepa")

        #expect(sepa < moonpayBalance)
        #expect(!(moonpayBalance < sepa))
    }

    @Test("MoonPay balance ties with other unknown methods")
    func moonpayBalanceTiesWithOtherMethods() {
        let moonpayBalance = OnrampTestFixtures.makeProvider(providerId: "moonpay", paymentMethodId: "moonpay-balance")
        let paypal = OnrampTestFixtures.makeProvider(providerId: "moonpay", paymentMethodId: "paypal")

        #expect(!(moonpayBalance < paypal))
        #expect(!(paypal < moonpayBalance))
    }

    @Test("MoonPay balance does not take the fastest badge from a card")
    func moonpayBalanceIsNotFastest() {
        let moonpayBalance = OnrampTestFixtures.makeProvider(providerId: "moonpay", paymentMethodId: "moonpay-balance")
        let card = OnrampTestFixtures.makeProvider(providerId: "mercuryo", paymentMethodId: "card")

        let list = OnrampTestFixtures.makeProvidersList([moonpayBalance, card])

        #expect(list.fastest() === card)
    }
}
