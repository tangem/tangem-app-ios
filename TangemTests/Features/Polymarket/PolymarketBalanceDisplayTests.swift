//
//  PolymarketBalanceDisplayTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemUI
@testable import Tangem

@Suite("Polymarket balance display")
struct PolymarketBalanceDisplayTests {
    @Test("Nothing is shown until the available balance arrives")
    func showsNothingBeforeTheFirstBalance() {
        var display = PolymarketBalanceDisplay()

        #expect(display.state == nil)

        display.update(available: .loaded("$10.00"))

        #expect(display.state == Self.loadedState("$10.00"))
    }

    @Test("A failed refresh keeps showing the last loaded balance")
    func failureFallsBackToTheLastBalance() throws {
        var display = PolymarketBalanceDisplay()
        display.update(available: .loaded("$10.00"))
        display.update(available: .failure(.empty("-")))

        let state = try #require(display.state)
        let reference = try #require(Self.loadedState("$10.00"))

        guard case .failed(let cached, _) = state, case .loaded(let loaded) = reference else {
            Issue.record("Expected the cached balance, got \(state)")
            return
        }

        #expect(cached == loaded)
    }

    @Test("A failed refresh after a cached balance keeps showing that cache")
    func failureFallsBackToTheCachedBalance() throws {
        var display = PolymarketBalanceDisplay()
        display.update(available: .loading(.cache(.init(balance: "$10.00", date: Date()))))
        display.update(available: .failure(.empty("-")))

        let state = try #require(display.state)
        let reference = try #require(Self.loadedState("$10.00"))

        guard case .failed(let cached, _) = state, case .loaded(let loaded) = reference else {
            Issue.record("Expected the cached balance, got \(state)")
            return
        }

        #expect(cached == loaded)
    }

    @Test("A failed first load shows the failure as is")
    func failureWithoutCacheIsShownAsIs() {
        var display = PolymarketBalanceDisplay()
        display.update(available: .failure(.empty("-")))

        guard case .failed = display.state else {
            Issue.record("Expected the failure state")
            return
        }
    }

    @Test("A refresh over a cached balance is drawn as the loaded balance")
    func cachedLoadingIsDrawnAsLoaded() {
        var display = PolymarketBalanceDisplay()
        display.update(available: .loading(.cache(.init(balance: "$10.00", date: Date()))))

        #expect(display.state == Self.loadedState("$10.00"))
    }

    @Test("The mode stays on available while the total has no value to show")
    func cannotSwitchWithoutTotal() {
        var display = PolymarketBalanceDisplay()
        display.update(available: .loaded("$10.00"))
        display.update(total: .failure(.empty("-")))

        display.toggleMode()

        #expect(!display.canSwitchMode)
        #expect(display.mode == .available)
    }

    @Test("A known total lets the mode switch back and forth")
    func switchesWhenTotalIsKnown() {
        var display = PolymarketBalanceDisplay()
        display.update(available: .loaded("$10.00"))
        display.update(total: .loaded("$25.00"))

        display.toggleMode()
        #expect(display.mode == .total)
        #expect(display.state == Self.loadedState("$25.00"))

        display.toggleMode()
        #expect(display.mode == .available)
        #expect(display.state == Self.loadedState("$10.00"))
    }

    @Test("A cached total lets the mode switch")
    func switchesWhenTotalIsCached() {
        var display = PolymarketBalanceDisplay()
        display.update(available: .loaded("$10.00"))
        display.update(total: .failure(.cache(.init(balance: "$25.00", date: Date()))))

        display.toggleMode()

        #expect(display.canSwitchMode)
        #expect(display.mode == .total)
    }

    @Test("Losing the total falls back to the available mode")
    func fallsBackWhenTotalIsLost() {
        var display = PolymarketBalanceDisplay()
        display.update(available: .loaded("$10.00"))
        display.update(total: .loaded("$25.00"))
        display.toggleMode()

        display.update(total: .failure(.empty("-")))

        #expect(display.mode == .available)
        #expect(!display.canSwitchMode)
    }

    // MARK: - Helpers

    static func loadedState(_ balance: String) -> LoadableBalanceView.State? {
        var display = PolymarketBalanceDisplay()
        display.update(available: .loaded(balance))
        return display.state
    }
}
