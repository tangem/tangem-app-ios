//
//  PolymarketBFFEnvironmentTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import TangemPolymarket

@Suite("Polymarket BFF environment", .timeLimit(.minutes(1)))
struct PolymarketBFFEnvironmentTests {
    private let baseURL = URL(string: "https://api.tangem.org")!
    private let walletId = String(repeating: "a", count: 64)

    @Test("The wallet id travels as a header, and the environment's own headers survive alongside it")
    func walletIdJoinsEnvironmentHeaders() {
        let environment = PolymarketBFFEnvironment(
            baseURL: baseURL,
            headers: ["api-key": "secret", "version": "6.4"]
        )

        let headers = environment.requestHeaders(walletId: walletId)

        #expect(headers["wallet-id"] == walletId)
        #expect(headers["api-key"] == "secret")
        #expect(headers["version"] == "6.4")
    }

    @Test("The wallet of the request wins over one the environment happens to carry")
    func walletIdOverridesEnvironmentValue() {
        let environment = PolymarketBFFEnvironment(baseURL: baseURL, headers: ["wallet-id": "stale"])

        #expect(environment.requestHeaders(walletId: walletId)["wallet-id"] == walletId)
    }
}

@Suite("Polymarket wallet-scoped targets", .timeLimit(.minutes(1)))
struct PolymarketWalletScopedTargetTests {
    private let environment = PolymarketBFFEnvironment(baseURL: URL(string: "https://api.tangem.org")!, headers: ["api-key": "secret"])
    private let walletId = String(repeating: "a", count: 64)

    @Test("Without an owner address the wallet state is asked for by the wallet the target carries")
    func walletStateFallsBackToTheTargetWallet() throws {
        let request = PolymarketDepositWalletTarget(environment: environment, walletId: walletId, target: .walletState(ownerAddress: nil))

        guard case .requestParameters(let parameters, _) = request.task else {
            Issue.record("The wallet state read must carry query parameters")
            return
        }

        #expect(parameters["walletId"] as? String == walletId)
        #expect(parameters["ownerAddress"] == nil)
    }
}
