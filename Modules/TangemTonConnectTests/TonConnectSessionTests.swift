//
//  TonConnectSessionTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectSessionTests {
    private func makeSession() -> TonConnectSession {
        TonConnectSession(
            dAppClientID: try! TonConnectClientID(hexString: String(repeating: "aa", count: 32)),
            walletClientID: try! TonConnectClientID(hexString: String(repeating: "bb", count: 32)),
            bridgeURL: URL(string: "https://connect.ton.org/bridge")!,
            manifest: TonConnectManifest(url: URL(string: "https://app.example.com")!, name: "Example", iconUrl: URL(string: "https://app.example.com/i.png")!),
            appDomain: "app.example.com",
            account: .init(address: "0:" + String(repeating: "00", count: 32), network: .mainnet, publicKey: String(repeating: "cc", count: 32)),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    @Test
    func acceptsFirstIdAsBaselineThenRequiresStrictIncrease() throws {
        var session = makeSession()

        try session.acceptRequest(id: "1700000000500")
        #expect(session.lastRequestID == "1700000000500")

        try session.acceptRequest(id: "1700000000501")

        #expect(throws: TonConnectError.requestIDNotIncreasing(received: "1700000000501", last: "1700000000501")) {
            try session.acceptRequest(id: "1700000000501")
        }
        #expect(throws: TonConnectError.requestIDNotIncreasing(received: "5", last: "1700000000501")) {
            try session.acceptRequest(id: "5")
        }
        #expect(session.lastRequestID == "1700000000501", "rejected ids must not move the baseline")

        // Compared numerically, not lexicographically.
        try session.acceptRequest(id: "10000000000000")
    }

    @Test(arguments: ["", "abc", "-1", "1.0", "0x10"])
    func rejectsNonIntegerIds(id: String) {
        var session = makeSession()

        #expect(throws: TonConnectError.badRequest("request id must be a non-negative integer")) {
            try session.acceptRequest(id: id)
        }
    }

    @Test
    func allocatesIncreasingEventIds() {
        var session = makeSession()

        #expect(session.allocateEventID() == 0)
        #expect(session.allocateEventID() == 1)
        #expect(session.nextEventID == 2)
    }

    @Test
    func roundTripsThroughCodable() throws {
        var session = makeSession()
        try session.acceptRequest(id: "7")
        _ = session.allocateEventID()
        session.lastBridgeEventID = "99"

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(TonConnectSession.self, from: data)

        #expect(decoded == session)
        #expect(decoded.lastRequestID == "7")
        #expect(decoded.nextEventID == 1)
        #expect(decoded.lastBridgeEventID == "99")
    }
}
