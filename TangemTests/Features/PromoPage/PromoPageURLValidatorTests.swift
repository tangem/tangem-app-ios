//
//  PromoPageURLValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Promo page address check")
struct PromoPageURLValidatorTests {
    @Test(
        "A page on a listed domain over https passes unchanged",
        arguments: [
            "https://tangem.com",
            "https://www.tangem.com/en/",
            "https://buy.tangem.com/page",
            "https://app.tangem.com",
            "https://tangem.surveysparrow.com/s/survey",
            "https://feedback.tangem.com",
            "https://promo.tangem.com/prize-draw-status/?success",
        ]
    )
    func acceptsListedDomains(page: String) {
        #expect(makeSUT().validatedURL(from: page) == URL(string: page))
    }

    @Test("The scheme and the domain are compared without regard to case")
    func ignoresCase() {
        let page = "HTTPS://Promo.Tangem.COM/page"

        #expect(makeSUT().validatedURL(from: page) == URL(string: page))
    }

    @Test(
        "Any other address is turned away",
        arguments: [
            "http://promo.tangem.com",
            "https://x.promo.tangem.com",
            "https://tangem.com.example.org",
            "https://eviltangem.com",
            "https://tangem.com@example.org",
            "https://user:pass@tangem.com",
            "https://user@promo.tangem.com/page",
            "https://:@tangem.com",
            "https://evil.org%5C@tangem.com",
            "https://tangem.com:8443",
            "https://tangem.com:443",
            "promo.tangem.com/page",
            "not a url",
            "",
        ]
    )
    func rejectsOtherAddresses(page: String) {
        #expect(makeSUT().validatedURL(from: page) == nil)
    }
}

// MARK: - Helpers

private extension PromoPageURLValidatorTests {
    func makeSUT() -> PromoPageURLValidator {
        PromoPageURLValidator()
    }
}
