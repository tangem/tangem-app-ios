//
//  ForYouSelectedAccountsProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
@testable import Tangem

@Suite("ForYouSelectedAccountsProvider")
struct ForYouSelectedAccountsProviderTests {
    typealias SUT = ForYouSelectedAccountsProvider

    @Test("Defaults to `.all`")
    func defaultsToAll() {
        #expect(SUT().selection == .all)
    }

    @Test("Replays the current selection to a subscriber that arrives after init")
    func replaysCurrentSelectionToLateSubscriber() {
        let id = ForYouAccountID(anyAccount)
        let sut = SUT(selection: .subset([id]))

        var received: [ForYouAccountSelection] = []
        let cancellable = sut.selectionPublisher.sink { received.append($0) }
        defer { cancellable.cancel() }

        #expect(received == [.subset([id])])
    }

    @Test("select broadcasts the new selection and keeps the synchronous value in sync")
    func selectBroadcastsAndKeepsSyncValueConsistent() {
        let id = ForYouAccountID(anyAccount)
        let sut = SUT()

        var emissions: [ForYouAccountSelection] = []
        let cancellable = sut.selectionPublisher.sink { emissions.append($0) }
        defer { cancellable.cancel() }

        sut.select(.subset([id]))
        sut.select(.all)

        #expect(emissions == [.all, .subset([id]), .all])
        #expect(sut.selection == .all)
    }
}

// MARK: - Private helpers

private extension ForYouSelectedAccountsProviderTests {
    var anyAccount: CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
    }
}
