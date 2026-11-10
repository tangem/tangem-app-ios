//
//  PromoPageServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Promo page kept until the main screen shows it", .serialized)
struct PromoPageServiceTests {
    @Test("A newer page replaces the kept one")
    func newerPageReplacesKeptOne() async {
        await withStorage { storage in
            let service = makeSUT()

            service.markPending(page: Page.first)
            service.markPending(page: Page.second)

            #expect(storage.pendingPage == Page.second)
        }
    }

    @Test("Clearing drops the kept page")
    func clearDropsPage() async {
        await withStorage { storage in
            let service = makeSUT()

            service.markPending(page: Page.first)
            service.clearPending()

            #expect(storage.pendingPage == nil)
        }
    }

    @Test("With the toggle off no page is kept, and a newer link drops the one kept before")
    func toggleOffKeepsNothing() async {
        await withStorage { storage in
            storage.pendingPage = Page.first

            makeSUT(isEnabled: false).markPending(page: Page.second)

            #expect(storage.pendingPage == nil)
        }
    }
}

// MARK: - Helpers

private extension PromoPageServiceTests {
    enum Page {
        static let first = "https://promo.tangem.com/prize-draw-status/?success"
        static let second = "https://promo.tangem.com/prize-draw-status/?no-wallet"
    }

    func makeSUT(isEnabled: Bool = true) -> PromoPageService {
        PromoPageService(isEnabled: isEnabled)
    }

    func withStorage(_ body: (PromoPageStorageStub) async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousStorage = InjectedValues[\.promoPageStorage]
            let storage = PromoPageStorageStub()
            InjectedValues[\.promoPageStorage] = storage

            defer { InjectedValues[\.promoPageStorage] = previousStorage }

            await body(storage)
        }
    }
}
