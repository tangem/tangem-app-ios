//
//  OverlayDeeplinkResponderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Showing a deeplink over any screen", .serialized)
@MainActor
struct OverlayDeeplinkResponderTests {
    @Test("A card on the phone holds the link back instead of letting it cover the scan")
    func holdsTheLinkWhileScanning() async {
        let responder = OverlayDeeplinkResponder()

        NotificationCenter.default.post(name: .cardSessionDidStart, object: nil)
        // The responder hears about the scan on the main queue, one hop away from the post above.
        try? await Task.sleep(for: .milliseconds(50))

        let held = responder.didReceiveIncomingAction(Constants.actionWithNoScreen)

        #expect(held)

        NotificationCenter.default.post(name: .cardSessionDidFinish, object: nil)
    }

    @Test("With nothing in the way the link is left to whoever has a screen for it")
    func passesOnWhatItCannotShow() async {
        let responder = OverlayDeeplinkResponder()

        let shown = responder.didReceiveIncomingAction(Constants.actionWithNoScreen)

        #expect(!shown)
    }

    /// Held is not taken: a link this responder has no screen for is worth as much once the card is away as it
    /// was before the scan, so it goes back to the chain rather than into the log.
    @Test("Once the card is away the held link goes back to the chain")
    func handsTheHeldLinkBack() async {
        let manager = InjectedValues[\.incomingActionManager]
        let chain = ClaimingResponder()
        manager.becomeFirstResponder(chain)
        defer { manager.resignFirstResponder(chain) }

        let responder = OverlayDeeplinkResponder()

        NotificationCenter.default.post(name: .cardSessionDidStart, object: nil)
        try? await Task.sleep(for: .milliseconds(50))

        _ = responder.didReceiveIncomingAction(Constants.actionWithNoScreen)

        NotificationCenter.default.post(name: .cardSessionDidFinish, object: nil)
        try? await Task.sleep(for: .milliseconds(50))

        #expect(chain.received == [Constants.actionWithNoScreen])
    }
}

// MARK: - Spies

private final class ClaimingResponder: IncomingActionResponder {
    private(set) var received: [IncomingAction] = []

    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        received.append(action)
        return true
    }
}

// MARK: - Constants

private extension OverlayDeeplinkResponderTests {
    enum Constants {
        /// A campaign is shown by its own responder, so the presenter has no screen for it — which is what tells
        /// «shown» apart from «kept for later» here.
        static let actionWithNoScreen = IncomingAction.navigation(.campaigns(CampaignsDeeplink(campaignId: "any")))
    }
}
