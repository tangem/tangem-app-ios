//
//  CallToActionMarketingBannerActionPerformerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CallToActionMarketingBannerActionPerformer", .tags(.marketingBanners))
struct CallToActionMarketingBannerActionPerformerTests {
    private let incomingActionHandler = IncomingActionHandlerSpy()
    private let externalLinkResponder = IncomingActionResponderSpy()

    private var performer: CallToActionMarketingBannerActionPerformer {
        CallToActionMarketingBannerActionPerformer(
            incomingActionHandler: incomingActionHandler,
            externalLinkResponder: externalLinkResponder
        )
    }

    @Test("A partner https link opens in the in-app browser without passing through the app's link handling")
    func partnerLinkOpensInAppBrowser() {
        let url = URL(string: "https://partner.example.com/otc?ref=tangem")!

        performer.perform(.open(url))

        #expect(externalLinkResponder.receivedActions == [.externalLink(url)])
        #expect(incomingActionHandler.handledURLs.isEmpty)
    }

    @Test("A link the app can open goes to the incoming action handler", arguments: [
        "tangem://support",
        "Tangem://support",
        "https://tangem.com/onramp",
        "https://tangem.com/some-page",
    ])
    func appLinkGoesToIncomingActionHandler(link: String) {
        let url = URL(string: link)!

        performer.perform(.open(url))

        #expect(incomingActionHandler.handledURLs == [url])
        #expect(externalLinkResponder.receivedActions.isEmpty)
    }

    @Test("A link that only signals the provider's browser to close is opened by nobody", arguments: [
        "tangem://onramp?type=concierge_waitlist",
        "tangem://onramp",
    ])
    func dismissSafariLinkIsIgnored(link: String) {
        performer.perform(.open(URL(string: link)!))

        #expect(incomingActionHandler.handledURLs.isEmpty)
        #expect(externalLinkResponder.receivedActions.isEmpty)
    }
}

private final class IncomingActionResponderSpy: IncomingActionResponder {
    private let state = OSAllocatedUnfairLock(initialState: [IncomingAction]())

    var receivedActions: [IncomingAction] { state.withLock { $0 } }

    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        state.withLock { $0.append(action) }
        return true
    }
}
