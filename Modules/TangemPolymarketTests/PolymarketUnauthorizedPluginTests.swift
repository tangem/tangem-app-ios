//
//  PolymarketUnauthorizedPluginTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
import TangemFoundation
@testable import TangemPolymarket

@Suite("Unauthorized plugin")
struct PolymarketUnauthorizedPluginTests {
    @Test(
        "A 401 to a request signed with the wallet's API credentials reports the wallet it was sent for",
        arguments: [
            PolymarketCLOBTarget.Target.balanceAllowance,
            .updateBalanceAllowance(.collateral),
            .placeOrder(body: Data()),
            .order(id: "0xorder"),
        ]
    )
    func reportsAnUnauthorizedResponse(target: PolymarketCLOBTarget.Target) {
        let observer = ObserverSpy()

        makeSUT(observer: observer).didReceive(.success(makeResponse(statusCode: 401)), target: makeTarget(target))

        #expect(observer.walletIds == [Self.walletId])
    }

    @Test(
        "A 401 to an exchange request that carries no API credentials is left alone",
        arguments: [
            PolymarketCLOBTarget.Target.createCredentials,
            .deriveCredentials,
            .price(tokenId: "1", orderSide: .buy),
        ]
    )
    func ignoresRequestsWithoutCredentials(target: PolymarketCLOBTarget.Target) {
        let observer = ObserverSpy()

        makeSUT(observer: observer).didReceive(.success(makeResponse(statusCode: 401)), target: makeTarget(target))

        #expect(observer.walletIds.isEmpty)
    }

    @Test("A 401 from our backend says nothing about the exchange credentials and is left alone")
    func ignoresTheBackend() {
        let observer = ObserverSpy()
        let backendTarget = PolymarketDepositWalletTarget(
            environment: PolymarketBFFEnvironment(baseURL: URL(string: "https://api.tangem.org")!, headers: [:]),
            walletId: Self.walletId,
            target: .walletState(ownerAddress: nil)
        )

        makeSUT(observer: observer).didReceive(.success(makeResponse(statusCode: 401)), target: backendTarget)

        #expect(observer.walletIds.isEmpty)
    }

    @Test("A 401 delivered as a failure reports the wallet just the same")
    func reportsAnUnauthorizedFailure() {
        let observer = ObserverSpy()

        makeSUT(observer: observer).didReceive(.failure(.statusCode(makeResponse(statusCode: 401))), target: makeTarget())

        #expect(observer.walletIds == [Self.walletId])
    }

    @Test("Any other answer, including a forbidden one, is left alone", arguments: [200, 403, 404, 409, 500])
    func ignoresOtherAnswers(statusCode: Int) {
        let observer = ObserverSpy()

        makeSUT(observer: observer).didReceive(.success(makeResponse(statusCode: statusCode)), target: makeTarget())

        #expect(observer.walletIds.isEmpty)
    }

    @Test("A request that never reached the exchange is left alone")
    func ignoresAConnectionFailure() {
        let observer = ObserverSpy()

        makeSUT(observer: observer).didReceive(.failure(.underlying(URLError(.notConnectedToInternet), nil)), target: makeTarget())

        #expect(observer.walletIds.isEmpty)
    }

    @Test("Every 401 is reported, so a burst is folded by whoever listens")
    func reportsEveryUnauthorizedAnswer() {
        let observer = ObserverSpy()
        let sut = makeSUT(observer: observer)

        for _ in 0 ..< 3 {
            sut.didReceive(.success(makeResponse(statusCode: 401)), target: makeTarget())
        }

        #expect(observer.walletIds.count == 3)
    }
}

// MARK: - Fixtures

private extension PolymarketUnauthorizedPluginTests {
    static let walletId = "wallet-1"

    func makeSUT(observer: ObserverSpy) -> PolymarketUnauthorizedPlugin {
        PolymarketUnauthorizedPlugin(walletId: Self.walletId, observer: observer)
    }

    func makeResponse(statusCode: Int) -> Response {
        let url = URL(string: "https://clob.polymarket.com/balance-allowance")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/2", headerFields: nil)

        return Response(statusCode: statusCode, data: Data(), response: httpResponse)
    }

    func makeTarget(_ target: PolymarketCLOBTarget.Target = .balanceAllowance) -> PolymarketCLOBTarget {
        PolymarketCLOBTarget(baseURL: URL(string: "https://clob.polymarket.com")!, target: target, authHeaders: [:])
    }
}

private final class ObserverSpy: PolymarketUnauthorizedObserving {
    private let reported = OSAllocatedUnfairLock(initialState: [String]())

    var walletIds: [String] {
        reported.withLock { $0 }
    }

    func exchangeRejectedCredentials(walletId: String) {
        reported.withLock { $0.append(walletId) }
    }
}
