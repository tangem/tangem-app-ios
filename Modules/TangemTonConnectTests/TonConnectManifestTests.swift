//
//  TonConnectManifestTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectManifestTests {
    @Test
    func decodesFullManifestAndIgnoresUnknownFields() throws {
        let body = Data(#"""
        {
          "url": "https://app.example.com",
          "name": "Example App",
          "iconUrl": "https://app.example.com/icon-180.png",
          "termsOfUseUrl": "https://app.example.com/terms",
          "privacyPolicyUrl": "https://app.example.com/privacy",
          "somethingNew": {"nested": true}
        }
        """#.utf8)

        let manifest = try TonConnectManifest.decode(from: body)

        #expect(manifest.name == "Example App")
        #expect(manifest.url.absoluteString == "https://app.example.com")
        #expect(manifest.termsOfUseUrl?.absoluteString == "https://app.example.com/terms")
        #expect(try manifest.appDomain() == "app.example.com")
    }

    @Test
    func appDomainIsLowercasedHostWithoutPathOrPort() throws {
        let manifest = TonConnectManifest(url: URL(string: "https://App.Example.COM:8443/some/path?q=1")!, name: "x", iconUrl: URL(string: "https://a.b/i.png")!)

        #expect(try manifest.appDomain() == "app.example.com")
    }

    @Test(arguments: ["tonkeeper", "localhost", ".example", "example.", "a..b", ""])
    func rejectsDomainsWithoutProperDotSeparation(host: String) {
        #expect(!TonConnectManifest.isValidAppDomain(host))
    }

    @Test(arguments: ["a.b", "app.example.com", "xn--80ak6aa92e.com"])
    func acceptsDottedDomains(host: String) {
        #expect(TonConnectManifest.isValidAppDomain(host))
    }

    @Test(arguments: ["https://tonkeeper", "https://localhost/manifest"])
    func appDomainRejectsReservedBareNames(url: String) throws {
        let manifest = TonConnectManifest(url: try #require(URL(string: url)), name: "x", iconUrl: URL(string: "https://a.b/i.png")!)

        #expect(throws: TonConnectError.manifestContentError("url host is not a valid dApp domain")) {
            try manifest.appDomain()
        }
    }

    @Test
    func rejectsInvalidJSONAndMissingRequiredFields() {
        #expect(throws: TonConnectError.manifestContentError("not a valid manifest JSON")) {
            try TonConnectManifest.decode(from: Data("{".utf8))
        }
        #expect(throws: TonConnectError.manifestContentError("not a valid manifest JSON")) {
            try TonConnectManifest.decode(from: Data(#"{"url":"https://a.b","name":"x"}"#.utf8))
        }
    }

    @Test
    func rejectsNonHTTPSAppURLAndIcon() {
        #expect(throws: TonConnectError.manifestContentError("url must use https")) {
            try TonConnectManifest.decode(from: Data(#"{"url":"http://a.b","name":"x","iconUrl":"https://a.b/i.png"}"#.utf8))
        }
        #expect(throws: TonConnectError.manifestContentError("iconUrl must use https")) {
            try TonConnectManifest.decode(from: Data(#"{"url":"https://a.b","name":"x","iconUrl":"http://a.b/i.png"}"#.utf8))
        }
    }

    @Test
    func rejectsBlankName() {
        #expect(throws: TonConnectError.manifestContentError("name is empty")) {
            try TonConnectManifest.decode(from: Data(#"{"url":"https://a.b","name":"  ","iconUrl":"https://a.b/i.png"}"#.utf8))
        }
    }
}
