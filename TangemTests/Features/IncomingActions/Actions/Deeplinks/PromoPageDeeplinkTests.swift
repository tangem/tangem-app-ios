//
//  PromoPageDeeplinkTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Promo page link")
struct PromoPageDeeplinkTests {
    @Test(
        "The page is decoded exactly once and kept as written",
        arguments: [
            ("page=https%3A%2F%2Fpromo.tangem.com%2Fprize-draw-status%2F%3Fsuccess", "https://promo.tangem.com/prize-draw-status/?success"),
            ("page=https%3A%2F%2Fpromo.tangem.com%2Fpage%3Fa%3D1%26b%3D2", "https://promo.tangem.com/page?a=1&b=2"),
            ("page=https%3A%2F%2Ftangem.com%2Fa%2520b", "https://tangem.com/a%20b"),
            ("page=https%3A%2F%2Ftangem.com%2F%3Fq%3Da+b", "https://tangem.com/?q=a+b"),
        ]
    )
    func readsPageOnce(query: String, expectedPage: String) throws {
        #expect(try makeSUT(query: query) == PromoPageDeeplink(page: expectedPage))
    }

    @Test("The first page that isn't empty is the one taken")
    func takesFirstNonEmptyPage() throws {
        #expect(try makeSUT(query: "page=&page=https%3A%2F%2Ftangem.com") == PromoPageDeeplink(page: "https://tangem.com"))
    }

    @Test("The page for a user without a wallet is not read")
    func ignoresNoWalletPage() throws {
        let query = "page_no_wallet=https%3A%2F%2Ftangem.com%2Fno-wallet&page=https%3A%2F%2Ftangem.com"

        #expect(try makeSUT(query: query) == PromoPageDeeplink(page: "https://tangem.com"))
    }

    @Test(
        "A link without a usable page still leads to the promo page",
        arguments: ["", "page=", "uid=AbC-123", "page_no_wallet=https%3A%2F%2Ftangem.com"]
    )
    func keepsLinkWithoutPage(query: String) throws {
        let url = try #require(URL(string: "tangem://promo_page?\(query)"))
        let link = try #require(DeeplinkURL(url: url))

        #expect(DeeplinkNavigationAction(link: link) == .promoPage(PromoPageDeeplink(page: nil)))
    }
}

// MARK: - Helpers

private extension PromoPageDeeplinkTests {
    func makeSUT(query: String) throws -> PromoPageDeeplink {
        let url = try #require(URL(string: "tangem://promo_page?\(query)"))
        let link = try #require(DeeplinkURL(url: url))
        return PromoPageDeeplink(link: link)
    }
}
