//
//  ConciergeWaitlistLinkTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Concierge waitlist link", .tags(.marketingBanners))
struct ConciergeWaitlistLinkTests {
    @Test("Only the waitlist link matches, however its scheme and type are written", arguments: [
        ("tangem://onramp?type=concierge_waitlist", true),
        ("Tangem://onramp?type=concierge_waitlist", true),
        ("tangem://onramp?type=CONCIERGE_WAITLIST", true),
        ("tangem://onramp", false),
        ("tangem://onramp?type=something_new", false),
        ("tangem://support?type=concierge_waitlist", false),
        ("https://tangem.com/onramp?type=concierge_waitlist", false),
    ])
    func matching(link: String, matches: Bool) throws {
        let url = try #require(URL(string: link))

        #expect(ConciergeWaitlistLink.matches(url) == matches)
    }

    @Test("Outside a banner the waitlist link is only the return from a provider page, like any onramp link", arguments: [
        "tangem://onramp?type=concierge_waitlist",
        "tangem://onramp",
        "tangem://onramp?tx_id=abc&result=success",
    ])
    func incomingLinkDismissesTheBrowser(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(IncomingActionParser().parseIncomingURL(url) == .dismissSafari(url))
    }
}
