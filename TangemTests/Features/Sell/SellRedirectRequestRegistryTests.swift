//
//  SellRedirectRequestRegistryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

// MARK: - Tests

@Suite("Tests for the request ids that bind a sell redirect to the wallet and token it was opened for")
struct SellRedirectRequestRegistryTests {
    private let dateProvider = AdjustableDateProvider(now: Date(timeIntervalSince1970: 1_000_000))
    private let sut: SellRedirectRequestRegistry

    init() {
        sut = SellRedirectRequestRegistry(lifetime: Self.lifetime, dateProvider: dateProvider)
    }

    @Test("An issued request id is valid")
    func issuedRequestIdIsValid() {
        let requestId = sut.requestId(for: Self.key())

        #expect(sut.isValid(requestId: requestId, for: Self.key()))
    }

    @Test("Nothing is valid without a pending request")
    func nothingIsValidWithoutAPendingRequest() {
        #expect(!sut.isValid(requestId: UUID().uuidString, for: Self.key()))
        #expect(!sut.isValid(requestId: "", for: Self.key()))
    }

    @Test("A request id the registry never issued is rejected")
    func foreignRequestIdIsRejected() {
        _ = sut.requestId(for: Self.key())

        #expect(!sut.isValid(requestId: UUID().uuidString, for: Self.key()))
    }

    @Test("A request id issued for another wallet is rejected")
    func requestIdOfAnotherWalletIsRejected() {
        let requestId = sut.requestId(for: Self.key())

        #expect(!sut.isValid(requestId: requestId, for: Self.key(userWalletId: Self.otherWalletId)))
    }

    @Test("A request id issued for another token is rejected")
    func requestIdOfAnotherTokenIsRejected() {
        let requestId = sut.requestId(for: Self.key())

        #expect(!sut.isValid(requestId: requestId, for: Self.key(currencyCode: "usdt", contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7")))
        #expect(!sut.isValid(requestId: requestId, for: Self.key(currencyCode: "eth_arbitrum", networkCode: "arbitrum")))
    }

    @Test("A request id stays valid until its lifetime ends")
    func expiredRequestIdIsRejected() {
        let requestId = sut.requestId(for: Self.key())

        dateProvider.advance(by: Self.lifetime - 1)
        #expect(sut.isValid(requestId: requestId, for: Self.key()))

        dateProvider.advance(by: 1)
        #expect(!sut.isValid(requestId: requestId, for: Self.key()))
    }

    @Test("The same wallet and token reuse the request id within the first half of its lifetime")
    func sameWalletAndTokenReuseRequestIdWithinFirstHalfOfLifetime() {
        let firstRequestId = sut.requestId(for: Self.key())

        dateProvider.advance(by: Self.lifetime / 2 - 1)
        let secondRequestId = sut.requestId(for: Self.key())

        #expect(firstRequestId == secondRequestId)
    }

    @Test("Reusing a request id never extends its lifetime")
    func reuseNeverExtendsLifetime() {
        let requestId = sut.requestId(for: Self.key())

        dateProvider.advance(by: Self.lifetime / 2 - 1)
        #expect(sut.requestId(for: Self.key()) == requestId)

        dateProvider.advance(by: Self.lifetime / 2 + 1)
        #expect(!sut.isValid(requestId: requestId, for: Self.key()))
    }

    @Test("Past half of its lifetime a request id is replaced with a fresh one")
    func requestIdPastHalfOfLifetimeIsReplacedWithFreshOne() {
        let oldRequestId = sut.requestId(for: Self.key())

        dateProvider.advance(by: Self.lifetime / 2)
        let newRequestId = sut.requestId(for: Self.key())

        #expect(oldRequestId != newRequestId)
        #expect(!sut.isValid(requestId: oldRequestId, for: Self.key()))

        dateProvider.advance(by: Self.lifetime - 1)
        #expect(sut.isValid(requestId: newRequestId, for: Self.key()))
    }

    @Test("A new request id is issued after the old one expires")
    func newRequestIdIsIssuedAfterExpiry() {
        let expiredRequestId = sut.requestId(for: Self.key())

        dateProvider.advance(by: Self.lifetime)
        let newRequestId = sut.requestId(for: Self.key())

        #expect(expiredRequestId != newRequestId)
        #expect(!sut.isValid(requestId: expiredRequestId, for: Self.key()))
        #expect(sut.isValid(requestId: newRequestId, for: Self.key()))
    }

    @Test("Different wallets get different request ids")
    func differentWalletsGetDifferentRequestIds() {
        let firstRequestId = sut.requestId(for: Self.key())
        let secondRequestId = sut.requestId(for: Self.key(userWalletId: Self.otherWalletId))

        #expect(firstRequestId != secondRequestId)
        #expect(sut.isValid(requestId: firstRequestId, for: Self.key()))
        #expect(sut.isValid(requestId: secondRequestId, for: Self.key(userWalletId: Self.otherWalletId)))
    }

    @Test("Validation does not consume the request id")
    func validationDoesNotConsumeRequestId() {
        let requestId = sut.requestId(for: Self.key())

        #expect(sut.isValid(requestId: requestId, for: Self.key()))
        #expect(sut.isValid(requestId: requestId, for: Self.key()))
    }
}

// MARK: - Helpers

private extension SellRedirectRequestRegistryTests {
    static let lifetime: TimeInterval = 60 * 60
    static let walletId = UserWalletId(value: Data([0x01]))
    static let otherWalletId = UserWalletId(value: Data([0x02]))

    static func key(
        userWalletId: UserWalletId = walletId,
        currencyCode: String = "eth",
        networkCode: String = "ethereum",
        contractAddress: String? = nil
    ) -> SellRedirectRequestRegistry.Key {
        SellRedirectRequestRegistry.Key(
            userWalletId: userWalletId,
            currencyCode: currencyCode,
            networkCode: networkCode,
            contractAddress: contractAddress
        )
    }
}

private final class AdjustableDateProvider: DateProvider {
    private(set) var now: Date

    init(now: Date) {
        self.now = now
    }

    func advance(by interval: TimeInterval) {
        now.addTimeInterval(interval)
    }
}
