//
//  PolymarketClobAuthTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("ClobAuth signing payload", .timeLimit(.minutes(1)))
struct PolymarketClobAuthTests {
    private static let owner = "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf"
    private static let timestamp = "1735689600"

    @Test("The digest matches an independently computed vector", arguments: [
        Vector(owner: owner, timestamp: timestamp, digest: "eee0902fdab402c833900d907253e3eff18b45b061208ef2186a8cd9618c20c9"),
        Vector(owner: owner, timestamp: "1735689601", digest: "3c31de618b03c5fc115b9df8b1d6ef1a907a17333b2175ecf7d172d9b37996f5"),
        Vector(
            owner: "0x0491eb219E3D2d05aEF0C35D1079c0a55b19bd2B",
            timestamp: timestamp,
            digest: "c96c96ddf99e88cd87ad2d47d286fd58412f7aaf0f3bd938c9a9b0085f3dfb4a"
        ),
    ])
    func digestMatchesTheVector(vector: Vector) {
        let digest = PolymarketClobAuth.digest(ownerAddress: vector.owner, timestamp: vector.timestamp)

        #expect(digest.map { String(format: "%02x", $0) }.joined() == vector.digest)
    }
}

// MARK: - Fixtures

extension PolymarketClobAuthTests {
    struct Vector: Sendable {
        let owner: String
        let timestamp: String
        let digest: String
    }
}
