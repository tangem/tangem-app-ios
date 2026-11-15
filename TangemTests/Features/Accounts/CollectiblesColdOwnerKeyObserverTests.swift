//
//  CollectiblesColdOwnerKeyObserverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("CollectiblesAccountModelsRegistry.ColdOwnerKeyObserver")
struct CollectiblesColdOwnerKeyObserverTests {
    @Test(
        "Re-reads the Packs state after new keys arrive only while the Packs key is missing and no onboarding runs",
        arguments: [
            (isSyncRequired: true, isOnboarding: false, refreshCount: 1),
            (isSyncRequired: false, isOnboarding: false, refreshCount: 0),
            (isSyncRequired: true, isOnboarding: true, refreshCount: 0),
        ]
    )
    func refreshesAfterKeysChange(isSyncRequired: Bool, isOnboarding: Bool, refreshCount: Int) {
        let sut = makeSUT(isSyncRequired: isSyncRequired, isOnboarding: isOnboarding)

        sut.keys.send([])

        #expect(sut.refreshes.count == refreshCount)
    }
}

// MARK: - Helpers

private extension CollectiblesColdOwnerKeyObserverTests {
    typealias SUT = (
        observer: CollectiblesAccountModelsRegistry.ColdOwnerKeyObserver,
        keys: CurrentValueSubject<[KeyInfo], Never>,
        refreshes: RefreshRecorder
    )

    func makeSUT(isSyncRequired: Bool, isOnboarding: Bool) -> SUT {
        let keys = CurrentValueSubject<[KeyInfo], Never>([])
        let refreshes = RefreshRecorder()
        let observer = CollectiblesAccountModelsRegistry.ColdOwnerKeyObserver(
            keysPublisher: keys.eraseToAnyPublisher(),
            isSyncRequiredPublisher: Just(isSyncRequired).eraseToAnyPublisher(),
            isOnboardingPublisher: Just(isOnboarding).eraseToAnyPublisher(),
            refreshState: refreshes.record
        )

        return (observer, keys, refreshes)
    }
}

// MARK: - Doubles

private final class RefreshRecorder {
    private(set) var count = 0

    func record() {
        count += 1
    }
}
