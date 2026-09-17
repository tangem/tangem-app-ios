//
//  JointAccountInviteLinkBuilderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// A shared link only works if the app it lands on reads back the invite that was written into it, so these check the
/// builder against `JointAccountInviteDeeplink` rather than against a literal of their own.
@Suite("Tests for how an invite link is written")
struct JointAccountInviteLinkBuilderTests {
    private let builder = JointAccountInviteLinkBuilder()
    private let parser = DeeplinkParser()
    private let inviteId = "B15CF4AC32F65CA583F007580390FAD07CF48A2BBD23C817A6FE83A3FF1BFB63"

    @Test("The invite is written into the path of a universal link")
    func universalLinkIsBuilt() throws {
        let url = try #require(builder.buildURL(invite: StoredJointAccountInvite(id: inviteId)))

        #expect(url.absoluteString == "https://tangem.com/joint-account/join/\(inviteId)")
    }

    @Test("The link the builder writes is the one the parser reads")
    func builtLinkIsParsedBack() throws {
        let url = try #require(builder.buildURL(invite: StoredJointAccountInvite(id: inviteId)))

        #expect(parser.parse(url) == .navigation(.jointAccountInvite(JointAccountInviteDeeplink(inviteId: inviteId))))
    }
}
