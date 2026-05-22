//
//  OnrampSuggestedOfferViewModelBuilderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("OnrampSuggestedOfferViewModelBuilder.mapToRecommendedOnrampOfferViewModelTitle")
struct OnrampSuggestedOfferViewModelBuilderTests {
    private let builder = OnrampSuggestedOfferViewModelBuilder(tokenItem: Self.testTokenItem)

    @Test("`.nativeApplePay` with .best attractive type maps to .great badge")
    func nativeApplePayWithBestAttractiveType() {
        let provider = OnrampTestFixtures.makeProvider(paymentMethodId: "apple-pay")
        provider.update(globalAttractiveType: .best)

        let title = builder.mapToRecommendedOnrampOfferViewModelTitle(
            suggestedOfferType: .nativeApplePay(provider)
        )

        #expect(title == .great)
    }

    @Test("`.nativeApplePay` with .great attractive type maps to .great badge")
    func nativeApplePayWithGreatAttractiveType() {
        let provider = OnrampTestFixtures.makeProvider(paymentMethodId: "apple-pay")
        provider.update(globalAttractiveType: .great(percent: 0.05))

        let title = builder.mapToRecommendedOnrampOfferViewModelTitle(
            suggestedOfferType: .nativeApplePay(provider)
        )

        #expect(title == .great)
    }

    @Test("`.nativeApplePay` with .loss attractive type maps to .fastest badge")
    func nativeApplePayWithLossAttractiveType() {
        let provider = OnrampTestFixtures.makeProvider(paymentMethodId: "apple-pay")
        provider.update(globalAttractiveType: .loss(percent: 0.02))

        let title = builder.mapToRecommendedOnrampOfferViewModelTitle(
            suggestedOfferType: .nativeApplePay(provider)
        )

        #expect(title == .fastest)
    }

    @Test("`.nativeApplePay` with no attractive type maps to .fastest badge")
    func nativeApplePayWithoutAttractiveType() {
        let provider = OnrampTestFixtures.makeProvider(paymentMethodId: "apple-pay")
        provider.update(globalAttractiveType: nil)

        let title = builder.mapToRecommendedOnrampOfferViewModelTitle(
            suggestedOfferType: .nativeApplePay(provider)
        )

        #expect(title == .fastest)
    }

    fileprivate static let testTokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
}
