//
//  PolymarketServerClockPluginTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import TangemPolymarket

@Suite("Server clock plugin")
struct PolymarketServerClockPluginTests {
    private let deviceNow = Date(timeIntervalSince1970: 1_787_000_000)

    private static let liveHeaderValue = "Thu, 17 Sep 2026 12:34:51 GMT"
    private static let liveHeaderDate = Date(timeIntervalSince1970: 1_789_648_491)

    @Test("The backend's date header is read as the time it names")
    func readsTheDateHeader() {
        let clock = makeClock()

        makeSUT(clock: clock).didReceive(.success(makeResponse(dateHeader: Self.liveHeaderValue)), target: makeTarget())

        #expect(clock.now == Self.liveHeaderDate)
    }

    @Test("A failed request still carries the header, and its time counts just the same")
    func readsTheDateHeaderOffAFailure() {
        let clock = makeClock()
        let response = makeResponse(dateHeader: Self.liveHeaderValue, statusCode: 401)

        makeSUT(clock: clock).didReceive(.failure(.statusCode(response)), target: makeTarget())

        #expect(clock.now == Self.liveHeaderDate)
    }

    @Test("An answer without the header leaves the device clock alone")
    func ignoresAMissingHeader() {
        let clock = makeClock()

        makeSUT(clock: clock).didReceive(.success(makeResponse(dateHeader: nil)), target: makeTarget())

        #expect(clock.now == deviceNow)
    }

    @Test("An answer whose header cannot be read leaves the device clock alone")
    func ignoresAnUnreadableHeader() {
        let clock = makeClock()

        makeSUT(clock: clock).didReceive(.success(makeResponse(dateHeader: "not a date")), target: makeTarget())

        #expect(clock.now == deviceNow)
    }
}

// MARK: - Fixtures

private extension PolymarketServerClockPluginTests {
    func makeClock() -> PolymarketServerClock {
        let fixedDeviceNow = deviceNow

        return PolymarketServerClock(deviceNow: { fixedDeviceNow })
    }

    func makeSUT(clock: PolymarketServerClock) -> PolymarketServerClockPlugin {
        PolymarketServerClockPlugin(serverClock: clock)
    }

    func makeResponse(dateHeader: String?, statusCode: Int = 200) -> Response {
        let url = URL(string: "https://api.tangem.org/api/predictions/v1/withdraw/0x1")!
        let headerFields = dateHeader.map { ["Date": $0] }
        let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/2", headerFields: headerFields)

        return Response(statusCode: statusCode, data: Data(), response: httpResponse)
    }

    func makeTarget() -> PolymarketBridgeTarget {
        PolymarketBridgeTarget(baseURL: URL(string: "https://api.tangem.org")!, target: .supportedAssets)
    }
}
