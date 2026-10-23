//
//  RemoteCollectiblesBuybackStatusProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("RemoteCollectiblesBuybackStatusProvider")
struct RemoteCollectiblesBuybackStatusProviderTests {
    typealias SUT = RemoteCollectiblesBuybackStatusProvider

    @Test("Asks for the status of the buyback on behalf of the wallet")
    func asksForBuybackStatus() async throws {
        let (sut, requester) = makeSUT(wireStatus: "confirming")

        _ = try await sut.load(buybackID: "bb-1")

        guard case .buybackStatus(let request, let userWalletID)? = requester.targets.first else {
            Issue.record("Expected the status request, got \(requester.targets)")
            return
        }

        #expect(request.buybackID == "bb-1")
        #expect(userWalletID == "wallet-1")
        #expect(requester.targets.count == 1)
    }

    @Test("Statuses are read by their wire names, an unknown one is kept as is", arguments: [
        (wire: "created", status: CollectiblesBuybackStatus.created),
        (wire: "waiting-tx-hash", status: .waitingTxHash),
        (wire: "buyback-tx-sent", status: .buybackTxSent),
        (wire: "confirming", status: .confirming),
        (wire: "confirmed", status: .confirmed),
        (wire: "expired", status: .expired),
        (wire: "cancelled", status: .unknown("cancelled")),
    ])
    func mapsStatus(wire: String, status: CollectiblesBuybackStatus) async throws {
        let (sut, _) = makeSUT(wireStatus: wire)

        let loaded = try await sut.load(buybackID: "bb-1")

        #expect(loaded == status)
    }
}

// MARK: - Helpers

private extension RemoteCollectiblesBuybackStatusProviderTests {
    func makeSUT(wireStatus: String) -> (SUT, APIRequesterStub) {
        let requester = APIRequesterStub(response: #"{"buybackId":"bb-1","status":"\#(wireStatus)"}"#)
        return (SUT(userWalletID: "wallet-1", requester: requester), requester)
    }
}

// MARK: - Stubs

private final class APIRequesterStub: CollectiblesAPIRequesting {
    private(set) var targets: [CollectiblesAPITarget.Target] = []

    private let response: String

    init(response: String) {
        self.response = response
    }

    func request<T: Decodable>(_ target: CollectiblesAPITarget.Target) async throws -> T {
        targets.append(target)
        return try JSONDecoder().decode(T.self, from: Data(response.utf8))
    }
}
