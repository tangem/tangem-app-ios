//
//  CommonSafariManagerTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("In-app browser")
struct CommonSafariManagerTests {
    @Test(
        "A link the browser can't show is closed at once instead of crashing the app",
        arguments: ["tangem://crash", "changenow://tx/1", "mailto:support@tangem.com"]
    )
    func closesNonWebLink(link: String) throws {
        var isDismissed = false

        let handle = CommonSafariManager().openURL(
            try #require(URL(string: link)),
            configuration: .init(),
            onDismiss: { isDismissed = true },
            onSuccess: { _ in }
        )

        #expect(handle == nil)
        #expect(isDismissed)
    }
}
