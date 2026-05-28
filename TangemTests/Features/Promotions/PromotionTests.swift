//
//  PromotionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Promotion")
struct PromotionTests {
    // MARK: - matches(networkId:tokenAddress:)

    @Test("Returns true when networkId and address match")
    func matchesWhenBothMatch() {
        let sut = makePromotion(tokens: [makeToken(networkId: "ethereum", address: "0xABC")])

        #expect(sut.matches(networkId: "ethereum", tokenAddress: "0xABC"))
    }

    @Test("Returns false when networkId differs")
    func doesNotMatchWhenNetworkIdDiffers() {
        let sut = makePromotion(tokens: [makeToken(networkId: "ethereum", address: "0xABC")])

        #expect(!sut.matches(networkId: "polygon", tokenAddress: "0xABC"))
    }

    @Test("Returns false when address differs")
    func doesNotMatchWhenAddressDiffers() {
        let sut = makePromotion(tokens: [makeToken(networkId: "ethereum", address: "0xABC")])

        #expect(!sut.matches(networkId: "ethereum", tokenAddress: "0xDEF"))
    }

    @Test("Returns false when tokens is nil")
    func doesNotMatchWhenTokensNil() {
        let sut = makePromotion(tokens: nil)

        #expect(!sut.matches(networkId: "ethereum", tokenAddress: "0xABC"))
    }

    @Test("Returns false when tokens is empty")
    func doesNotMatchWhenTokensEmpty() {
        let sut = makePromotion(tokens: [])

        #expect(!sut.matches(networkId: "ethereum", tokenAddress: "0xABC"))
    }

    @Test("Returns true if any token matches")
    func matchesAnyToken() {
        let sut = makePromotion(tokens: [
            makeToken(networkId: "ethereum", address: "0xETH"),
            makeToken(networkId: "polygon", address: "0xPOLY"),
        ])

        #expect(sut.matches(networkId: "polygon", tokenAddress: "0xPOLY"))
    }
}

// MARK: - Helpers

private extension PromotionTests {
    func makePromotion(tokens: [Promotion.TokenInfo]?) -> Promotion {
        Promotion(
            id: 1,
            placeholder: .tokenDetails,
            priority: "high",
            title: "T",
            subtitle: "S",
            iconUrl: nil,
            deeplink: nil,
            buttonEnabled: true,
            buttonText: nil,
            dismissable: true,
            tokens: tokens
        )
    }

    func makeToken(networkId: String, address: String) -> Promotion.TokenInfo {
        Promotion.TokenInfo(
            networkId: networkId,
            token: Promotion.Token(id: "id", symbol: "TKN", name: "Token", address: address, decimalCount: 18)
        )
    }
}
