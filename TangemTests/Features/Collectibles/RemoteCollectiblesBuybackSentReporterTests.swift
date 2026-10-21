//
//  RemoteCollectiblesBuybackSentReporterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("RemoteCollectiblesBuybackSentReporter")
struct RemoteCollectiblesBuybackSentReporterTests {
    typealias SUT = RemoteCollectiblesBuybackSentReporter

    @Test("Reports the sent hash for the buyback on behalf of the wallet")
    func reportsSentHash() async throws {
        let requester = APIRequesterStub(response: #"{"buybackId":"bb-1","status":"buyback-tx-sent"}"#)
        let sut = SUT(userWalletID: "wallet-1", requester: requester)

        try await sut.report(buybackID: "bb-1", txHash: "hash-1")

        guard case .buybackTxSent(let request, let userWalletID)? = requester.targets.first else {
            Issue.record("Expected the buyback-tx-sent request, got \(requester.targets)")
            return
        }

        #expect(request.buybackID == "bb-1")
        #expect(request.txHash == "hash-1")
        #expect(userWalletID == "wallet-1")
        #expect(requester.targets.count == 1)
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
