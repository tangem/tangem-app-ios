//
//  PromoPageViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Promo page screen", .timeLimit(.minutes(1)))
@MainActor
struct PromoPageViewModelTests {
    @Test("A page that loads stays on screen, hides the loader and stops waiting for the timeout")
    func loadedPageStays() async {
        let (sut, dismissAction, loadTimeout) = makeSUT()

        sut.onAppear()
        sut.pageDidFinishLoading()
        await first(loadTimeout.cancellations)

        #expect(sut.isLoading == false)
        #expect(dismissAction.timesCalled == 0)
    }

    @Test("A network or HTTP error before the page loads closes the screen once")
    func failureClosesOnce() async {
        let (sut, dismissAction, loadTimeout) = makeSUT()

        sut.onAppear()
        sut.pageDidFailLoading()
        sut.pageDidFailLoading()
        await first(loadTimeout.cancellations)

        #expect(dismissAction.timesCalled == 1)
    }

    @Test("A page that doesn't load in time closes the screen")
    func timeoutCloses() async {
        let (sut, dismissAction, loadTimeout) = makeSUT()

        sut.onAppear()
        loadTimeout.elapse()
        await first(dismissAction.dismissals)

        #expect(dismissAction.timesCalled == 1)
    }

    @Test("An error after the page has loaded leaves it on screen")
    func failureAfterLoadIsIgnored() async {
        let (sut, dismissAction, loadTimeout) = makeSUT()

        sut.onAppear()
        sut.pageDidFinishLoading()
        await first(loadTimeout.cancellations)
        sut.pageDidFailLoading()

        #expect(dismissAction.timesCalled == 0)
    }

    @Test("A screen the user has closed is not closed a second time")
    func closedScreenIsLeftAlone() async {
        let (sut, dismissAction, loadTimeout) = makeSUT()

        sut.onAppear()
        sut.onDisappear()
        await first(loadTimeout.cancellations)
        sut.pageDidFailLoading()

        #expect(dismissAction.timesCalled == 0)
    }

    @Test(
        "The page moves only to the listed domains over https",
        arguments: [
            ("https://promo.tangem.com/prize-draw-status/?no-wallet", true),
            ("https://tangem.com/en/", true),
            ("http://promo.tangem.com/page", false),
            ("https://x.promo.tangem.com", false),
            ("https://example.org", false),
            ("tangem://markets", false),
        ]
    )
    func navigatesOnlyToListedDomains(link: String, isAllowed: Bool) throws {
        let (sut, _, _) = makeSUT()
        let url = try #require(URL(string: link))

        #expect(sut.allowsNavigation(to: url) == isAllowed)
    }
}

// MARK: - Helpers

private extension PromoPageViewModelTests {
    func makeSUT() -> (sut: PromoPageViewModel, dismissAction: DismissActionSpy, loadTimeout: LoadTimeoutSpy) {
        let dismissAction = DismissActionSpy()
        let loadTimeout = LoadTimeoutSpy()
        let sut = PromoPageViewModel(
            url: URL(string: "https://promo.tangem.com/prize-draw-status/?success")!,
            dismiss: { dismissAction.dismiss() },
            waitForLoadTimeout: { await loadTimeout.wait() }
        )

        return (sut, dismissAction, loadTimeout)
    }

    func first(_ stream: AsyncStream<Void>) async {
        var iterator = stream.makeAsyncIterator()
        _ = await iterator.next()
    }
}

// MARK: - Stubs

@MainActor
private final class DismissActionSpy {
    private(set) var timesCalled = 0

    let dismissals: AsyncStream<Void>
    private let dismissalsContinuation: AsyncStream<Void>.Continuation

    init() {
        (dismissals, dismissalsContinuation) = AsyncStream.makeStream()
    }

    func dismiss() {
        timesCalled += 1
        dismissalsContinuation.yield()
    }
}

private final class LoadTimeoutSpy: Sendable {
    let cancellations: AsyncStream<Void>

    private let cancellationsContinuation: AsyncStream<Void>.Continuation
    private let gate = TestGate()

    init() {
        (cancellations, cancellationsContinuation) = AsyncStream.makeStream()
    }

    func wait() async {
        await withTaskCancellationHandler {
            await gate.wait()
        } onCancel: { [gate, cancellationsContinuation] in
            cancellationsContinuation.yield()
            gate.open()
        }
    }

    func elapse() {
        gate.open()
    }
}
