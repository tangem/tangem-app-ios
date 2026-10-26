//
//  MarketingActivityApiTargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
import TangemFoundation
@testable import Tangem

@Suite("TangemApiTarget.bindMarketingActivityWallets")
struct MarketingActivityApiTargetTests {
    private let request = MarketingActivityDTO.BindWallets.Request(walletIds: [
        "22BE6BE4DFC1C5D1A4F2EF6A4C1D8F4E0C2C7B3A9E2D1F0A8B7C6D5E4F3A224B",
        "0A1B2C3D4E5F60718293A4B5C6D7E8F90A1B2C3D4E5F60718293A4B5C6D7E8F9",
    ])

    @Test("Goes to the gateway base URL as a POST with no extra headers")
    func requestShape() {
        let target = makeTarget(uid: "AbC-123")

        #expect(target.method == .post)
        #expect(target.headers == nil)
        #expect(target.shouldLogResponseBody == false)
        #expect(url(of: target) == gatewayBase + "/marketing/activity/AbC-123/bind-wallets")
    }

    @Test(
        "The uid is a single path segment, escaped exactly once",
        arguments: [
            ("AbC-123", "AbC-123"),
            ("a.b_c~d", "a.b_c~d"),
            ("a/b", "a%2Fb"),
            ("a%b", "a%25b"),
            ("a%2Fb", "a%252Fb"),
            ("a?b", "a%3Fb"),
            ("a#b", "a%23b"),
            ("a b", "a%20b"),
            ("a+b", "a+b"),
            ("\"(;)\\", "%22(;)%5C"),
            ("ü", "%C3%BC"),
        ]
    )
    func uidInURL(uid: String, expectedSegment: String) {
        #expect(url(of: makeTarget(uid: uid)) == gatewayBase + "/marketing/activity/\(expectedSegment)/bind-wallets")
    }

    @Test("The body carries only the wallet ids, in their raw form")
    func body() throws {
        let target = makeTarget(uid: "AbC-123")

        guard case .requestJSONEncodable(let encodable) = target.task else {
            Issue.record("Expected a JSON body, got \(target.task)")
            return
        }

        let data = try JSONEncoder().encode(encodable)
        let body = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(body.keys) == ["walletIds"])
        #expect(body["walletIds"] as? [String] == request.walletIds)
    }

    @Test("The logged path doesn't carry the uid")
    func requestDescriptionMasksUid() {
        let uid = "email-campaign-uid-0123456789"
        let target = makeTarget(uid: uid)

        #expect(!target.requestDescription.contains(uid))
        #expect(target.requestDescription == "/marketing/activity/\(uid.masked())/bind-wallets")
    }
}

// MARK: - Helpers

private extension MarketingActivityApiTargetTests {
    var gatewayBase: String {
        AppEnvironment.current.apiBaseUrlWithGatewaySegment.absoluteString
    }

    func makeTarget(uid: String) -> TangemApiTarget {
        TangemApiTarget(type: .bindMarketingActivityWallets(uid: uid, request))
    }

    func url(of target: TangemApiTarget) -> String {
        URL(target: target).absoluteString
    }
}
