//
//  UnavailableCollectiblesColdKeyInteractorTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
@testable import TangemCollectibles

@Suite("UnavailableCollectiblesColdKeyInteractor")
struct UnavailableCollectiblesColdKeyInteractorTests {
    @Test("Refuses to derive and never runs the work")
    func refusesToDerive() async {
        await #expect(throws: (any Error).self) {
            try await UnavailableCollectiblesColdKeyInteractor().derive(andRun: NeverRunningWork())
        }
    }

    @Test("Refuses to sign")
    func refusesToSign() async {
        await #expect(throws: (any Error).self) {
            let coldKey = Wallet.PublicKey(seedKey: Data(repeating: 0x11, count: 32), derivationType: nil)
            _ = try await UnavailableCollectiblesColdKeyInteractor().sign(message: Data([1, 2, 3]), coldKey: coldKey)
        }
    }
}

// MARK: - Doubles

private struct NeverRunningWork: CollectiblesColdKeySessionWork {
    func run(signer: any CollectiblesColdKeySigner) async throws {
        Issue.record("The work must not run")
    }
}
