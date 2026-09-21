//
//  PolymarketReceiveTokenWithdrawNoticeInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("PolymarketReceiveTokenWithdrawNoticeInteractor")
final class PolymarketReceiveTokenWithdrawNoticeInteractorTests {
    private let usdcPolygon = PolymarketUtilities.usdcTokenItem
    private let suiteName = "polymarket.notice.\(UUID().uuidString)"

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    @Test("The notice is offered the first time the deposit address is shown")
    func offersTheNoticeOnce() throws {
        let store = try makeStore()

        #expect(makeSUT(store: store).shouldShowWithdrawalAlert(for: usdcPolygon))
    }

    @Test("The notice is not offered again once it has been shown")
    func doesNotRepeatTheNotice() throws {
        let store = try makeStore()

        _ = makeSUT(store: store).shouldShowWithdrawalAlert(for: usdcPolygon)

        #expect(!makeSUT(store: store).shouldShowWithdrawalAlert(for: usdcPolygon))
    }

    @Test("A different asset is warned about on its own")
    func warnsPerAsset() throws {
        let store = try makeStore()
        let ethereum = TokenItem.blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))

        _ = makeSUT(store: store).shouldShowWithdrawalAlert(for: usdcPolygon)

        #expect(makeSUT(store: store).shouldShowWithdrawalAlert(for: ethereum))
    }
}

// MARK: - Fixtures

private extension PolymarketReceiveTokenWithdrawNoticeInteractorTests {
    func makeStore() throws -> UserDefaults {
        let store = try #require(UserDefaults(suiteName: suiteName))
        store.removePersistentDomain(forName: suiteName)

        return store
    }

    func makeSUT(store: UserDefaults) -> PolymarketReceiveTokenWithdrawNoticeInteractor {
        PolymarketReceiveTokenWithdrawNoticeInteractor(store: store)
    }
}
