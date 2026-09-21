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
struct PolymarketReceiveTokenWithdrawNoticeInteractorTests {
    private let usdcPolygon = PolymarketUtilities.usdcTokenItem

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

    /// The bridge takes USDC on Polygon and nothing else today, but the notice is per asset so that a second
    /// deposit asset would get its own warning rather than inherit a dismissed one.
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
        let store = try #require(UserDefaults(suiteName: "polymarket.notice.\(UUID().uuidString)"))
        store.removePersistentDomain(forName: store.description)

        return store
    }

    func makeSUT(store: UserDefaults) -> PolymarketReceiveTokenWithdrawNoticeInteractor {
        PolymarketReceiveTokenWithdrawNoticeInteractor(store: store)
    }
}
