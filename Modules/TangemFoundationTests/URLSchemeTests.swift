//
//  URLSchemeTests.swift
//  TangemFoundationTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemFoundation

@Suite
struct URLSchemeTests {
    @Test(arguments: ["https://tangem.com", "HTTPS://tangem.com"])
    func httpsLinkIsHTTPS(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(url.isHTTPS)
    }

    @Test(arguments: ["http://tangem.com", "tangem://crash", "tangem.com"])
    func otherLinkIsNotHTTPS(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(!url.isHTTPS)
    }

    @Test(arguments: ["https://tangem.com", "HTTP://tangem.com"])
    func webLinkIsWebURL(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(url.isWebURL)
    }

    @Test(arguments: ["tangem://crash", "mailto:support@tangem.com", "tangem.com"])
    func nonWebLinkIsNotWebURL(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(!url.isWebURL)
    }
}
