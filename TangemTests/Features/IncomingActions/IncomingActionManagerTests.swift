//
//  IncomingActionManagerTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("Incoming action dispatch", .serialized)
@MainActor
struct IncomingActionManagerTests {
    @Test("A link reaches the chain as the action it was parsed into")
    func actionReachesTheChain() async {
        await withRepository {
            let manager = CommonIncomingActionManager()
            let responder = ResponderSpy(handles: { _ in true })
            manager.becomeFirstResponder(responder)

            manager.handleIncomingURL(Deeplink.markets)

            #expect(responder.received == [.navigation(.markets(MarketsDeeplink(order: nil, interval: nil)))])
        }
    }

    @Test("The responder that registered last answers first")
    func lastRegisteredAnswersFirst() async {
        await withRepository {
            let manager = CommonIncomingActionManager()
            let first = ResponderSpy(handles: { _ in true })
            let last = ResponderSpy(handles: { _ in true })
            manager.becomeFirstResponder(first)
            manager.becomeFirstResponder(last)

            manager.handleIncomingURL(Deeplink.markets)

            #expect(last.received.isNotEmpty)
            #expect(first.received.isEmpty)
        }
    }

    @Test("A responder that declines lets the one below answer")
    func decliningPassesTheLinkDown() async {
        await withRepository {
            let manager = CommonIncomingActionManager()
            let below = ResponderSpy(handles: { _ in true })
            let above = ResponderSpy()
            manager.becomeFirstResponder(below)
            manager.becomeFirstResponder(above)

            manager.handleIncomingURL(Deeplink.markets)

            #expect(above.received.count == 1)
            #expect(below.received.count == 1)
        }
    }

    @Test("A link nobody showed is gone: taking a place in the chain later brings nothing")
    func unshownLinkIsNotKept() async {
        await withRepository {
            let manager = CommonIncomingActionManager()
            let bystander = ResponderSpy()
            manager.becomeFirstResponder(bystander)

            manager.handleIncomingURL(Deeplink.markets)

            let latecomer = ResponderSpy(handles: { _ in true })
            manager.becomeFirstResponder(latecomer)
            manager.handleIncomingURL(Deeplink.news)

            #expect(latecomer.received == [.navigation(.news(NewsDeeplink(newsId: nil, categoryId: nil)))])
        }
    }

    @Test("A resigned responder isn't asked any more")
    func resignedResponderIsNotAsked() async {
        await withRepository {
            let manager = CommonIncomingActionManager()
            let responder = ResponderSpy(handles: { _ in true })
            manager.becomeFirstResponder(responder)

            manager.resignFirstResponder(responder)
            manager.handleIncomingURL(Deeplink.markets)

            #expect(responder.received.isEmpty)
        }
    }
}

// MARK: - Environment

private extension IncomingActionManagerTests {
    func withRepository(_ body: () async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [])

            defer { InjectedValues[\.userWalletRepository] = previousRepository }

            await body()
        }
    }

    enum Deeplink {
        static let markets = URL(string: "tangem://markets")!
        static let news = URL(string: "tangem://news")!
    }
}

// MARK: - Spies

@MainActor
private final class ResponderSpy: IncomingActionResponder {
    private(set) var received: [IncomingAction] = []

    private let handles: (IncomingAction) -> Bool

    init(handles: @escaping (IncomingAction) -> Bool = { _ in false }) {
        self.handles = handles
    }

    nonisolated func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        MainActor.assumeIsolated {
            received.append(action)
            return handles(action)
        }
    }
}
