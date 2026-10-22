//
//  ExternalLinkDeeplinkResponderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Web link deeplink", .serialized)
@MainActor
struct ExternalLinkDeeplinkResponderTests {
    @Test("A page of ours opens in the browser")
    func opensThePage() async {
        await withBrowser { manager in
            let responder = ExternalLinkDeeplinkResponder()

            let handled = responder.didReceiveIncomingAction(.externalLink(Constants.url))

            #expect(handled)
            #expect(manager.openedURLs == [Constants.url])
        }
    }

    @Test("The same page arriving twice is answered by the browser already showing it")
    func doesNotOpenTheSamePageTwice() async {
        await withBrowser { manager in
            let responder = ExternalLinkDeeplinkResponder()

            _ = responder.didReceiveIncomingAction(.externalLink(Constants.url))
            let handled = responder.didReceiveIncomingAction(.externalLink(Constants.url))

            #expect(handled)
            #expect(manager.openedURLs == [Constants.url])
        }
    }

    @Test("A link that isn't a page of ours is passed on")
    func passesOnEverythingElse() async {
        await withBrowser { manager in
            let responder = ExternalLinkDeeplinkResponder()

            let handled = responder.didReceiveIncomingAction(.navigation(.markets(MarketsDeeplink(order: nil, interval: nil))))

            #expect(!handled)
            #expect(manager.openedURLs.isEmpty)
        }
    }
}

// MARK: - Environment

private extension ExternalLinkDeeplinkResponderTests {
    func withBrowser(_ body: (SafariManagerSpy) async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousSafariManager = InjectedValues[\.safariManager]

            let manager = SafariManagerSpy()
            InjectedValues[\.safariManager] = manager

            defer { InjectedValues[\.safariManager] = previousSafariManager }

            await body(manager)
        }
    }

    enum Constants {
        static let url = URL(string: "https://tangem.com/pricing")!
    }
}

// MARK: - Stubs and spies

private final class SafariManagerSpy: SafariManager {
    private(set) var openedURLs: [URL] = []

    func openURL(
        _ url: URL,
        configuration: SafariConfiguration,
        onDismiss: @escaping () -> Void,
        onSuccess: @escaping (URL) -> Void
    ) -> SafariHandle? {
        openedURLs.append(url)
        return SafariHandleStub(url: url)
    }

    func openURL(_ url: URL, configuration: SafariConfiguration) {
        openedURLs.append(url)
    }
}

private final class SafariHandleStub: SafariHandle {
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func isMatching(startingURL: URL) -> Bool {
        url == startingURL
    }
}
