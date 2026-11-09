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
    private let conciergeWaitlistOpenCount = OSAllocatedUnfairLock(initialState: 0)

    private var performer: CallToActionMarketingBannerActionPerformer {
        CallToActionMarketingBannerActionPerformer(
            incomingActionHandler: incomingActionHandler,
            externalLinkResponder: externalLinkResponder,
            openConciergeWaitlist: { [conciergeWaitlistOpenCount] in conciergeWaitlistOpenCount.withLock { $0 += 1 } }
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

    @Test("The Waitlist link opens the survey for the banner's own wallet, not through the app's link handling", arguments: [
        "tangem://onramp?type=concierge_waitlist",
        "Tangem://onramp?type=CONCIERGE_WAITLIST",
    ])
    func waitlistLinkOpensSurvey(link: String) {
        performer.perform(.open(URL(string: link)!))

        #expect(conciergeWaitlistOpenCount.withLock { $0 } == 1)
        #expect(incomingActionHandler.handledURLs.isEmpty)
        #expect(externalLinkResponder.receivedActions.isEmpty)
    }

    @Test("A link that only signals the provider's browser to close is opened by nobody")
    func dismissSafariLinkIsIgnored() {
        performer.perform(.open(URL(string: "tangem://onramp")!))

        #expect(incomingActionHandler.handledURLs.isEmpty)
        #expect(externalLinkResponder.receivedActions.isEmpty)
        #expect(conciergeWaitlistOpenCount.withLock { $0 } == 0)
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
