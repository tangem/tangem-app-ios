//
//  JointAccountInviteLinkParserTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Single source of truth for joint account invite link parsing.
/// Keep all `jointAccountInvite` parser scenarios here rather than duplicating them in `DefaultIncomingLinkParserTests`.
@Suite("Tests for how an invite link is read")
struct JointAccountInviteLinkParserTests {
    private let parser = JointAccountInviteLinkParser()
    private let inviteId = "B15CF4AC32F65CA583F007580390FAD07CF48A2BBD23C817A6FE83A3FF1BFB63"

    // MARK: - Supported formats

    @Test("The universal link carries the invite id in its path")
    func universalLinkIsParsed() throws {
        let url = try #require(URL(string: "https://tangem.com/joint-account/join/\(inviteId)"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .jointAccountInvite)
        #expect(deeplink.params.id == inviteId)
        #expect(deeplink.deeplinkString == url.absoluteString)
    }

    @Test("The app scheme carries the invite id in a query item")
    func deepLinkIsParsed() throws {
        let url = try #require(URL(string: "tangem://joint-account-invite?id=\(inviteId)"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .jointAccountInvite)
        #expect(deeplink.params.id == inviteId)
    }

    @Test("The host is read regardless of how it is cased")
    func deepLinkHostIsCaseInsensitive() throws {
        let url = try #require(URL(string: "tangem://Joint-Account-Invite?id=\(inviteId)"))

        #expect(try parser.parse(url) != nil)
    }

    // MARK: - Links carrying no invite

    @Test("A link without an invite id is left to the other parsers", arguments: [
        "https://tangem.com/joint-account/join",
        "https://tangem.com/joint-account/join/",
        "tangem://joint-account-invite",
        "tangem://joint-account-invite?id=",
    ])
    func linksWithoutAnInviteIdAreRejected(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(try parser.parse(url) == nil)
    }

    @Test("An invite id of unsupported characters is turned away by the validator")
    func inviteIdOfUnsupportedCharactersIsRejected() throws {
        let url = try #require(URL(string: "tangem://joint-account-invite?id=not%20an%20invite"))

        #expect(try parser.parse(url) == nil)
    }

    // MARK: - Links belonging elsewhere

    @Test("Links of other destinations are left alone", arguments: [
        "https://tangem.com/news/markets/190801-polygon",
        "https://tangem.com/joint-account",
        "tangem://news?news_id=190801",
        "tangem://token?type=income_transaction",
    ])
    func foreignLinksAreRejected(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(try parser.parse(url) == nil)
    }
}
