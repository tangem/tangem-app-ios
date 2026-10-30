//
//  DeeplinkMarketingActivityUidTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Deeplink destinations with a marketing activity uid")
struct DeeplinkMarketingActivityUidTests {
    private static let linksByHost: [String: String] = [
        TokenDeeplink.host: "tangem://token?token_id=bitcoin&network_id=bitcoin",
        StakingDeeplink.host: "tangem://staking?token_id=ethereum&network_id=ethereum",
        YieldDeeplink.host: "tangem://yield",
        SwapDeeplink.host: "tangem://swap",
        MarketsDeeplink.host: "tangem://markets?order=rating&interval=1w",
        FeedDeeplink.host: "tangem://discover?section=earn",
        BuyDeeplink.host: "tangem://buy",
        SellDeeplink.host: "tangem://sell",
        ReferralDeeplink.host: "tangem://referral",
        PromoDeeplink.host: "tangem://promo?promo_code=TANGEM",
        NewsDeeplink.host: "tangem://news?news_id=1001",
        EarnDeeplink.host: "tangem://earn?earn_type=staking&network_id=ethereum",
        TangemPayAccountDeeplink.host: "tangem://pay-account",
        TokenChartDeeplink.host: "tangem://token_chart?token_id=bitcoin",
        TokenExchangesDeeplink.host: "tangem://token_exchanges?token_id=bitcoin",
        SurveyDeeplink.host: "tangem://survey?token=ntt-abc123",
        CampaignsDeeplink.host: "tangem://campaigns?campaignId=some-id",
        OnboardVisaDeeplink.host: "tangem://onboard-visa?entry=banner&id=some-id",
        PayAppDeeplink.host: "tangem://pay-app?id=some-id",
        JointAccountInviteDeeplink.host: "tangem://joint-account-invite?id=some-invite-id",
        JointAccountDeeplink.host: "tangem://joint_account?entry=members&user_wallet_id=AB12&account_id=BA910A77",
        SupportDeeplink.host: "tangem://support",
        MCPIntentDeeplink.host: "tangem://intent?id=intent-id&source=intent-source&type=intent-type",
        MCPAuthorizationDeeplink.host: "tangem://mcp.authorization?user_code=user-code",
    ]

    private static let linksByPath: [String: String] = [
        PayAppDeeplink.pathSegment: "https://tangem.com/pay-app?id=some-id",
        NewsArticleDeeplink.pathSegment: "https://tangem.com/news/markets/190801-polygon-protiv-ethereum",
        JointAccountInviteDeeplink.pathSegment: "https://tangem.com/joint-account/join/B15CF4AC32F65CA583F007580390FAD07CF48A2BBD23C817A6FE83A3FF1BFB63",
    ]

    private static let uid = "AbC-123"

    static var allLinks: [String] {
        Array(linksByHost.values) + Array(linksByPath.values)
    }

    @Test("Every destination of the router has a sample link here")
    func samplesCoverEveryDestination() {
        let hostsWithoutSample = Set(DeeplinkNavigationAction.destinationsNamedByHost.keys).subtracting(Self.linksByHost.keys)
        let pathsWithoutSample = Set(DeeplinkNavigationAction.destinationsNamedByPath.keys).subtracting(Self.linksByPath.keys)

        #expect(hostsWithoutSample.isEmpty, "No sample link for the hosts \(hostsWithoutSample.sorted())")
        #expect(pathsWithoutSample.isEmpty, "No sample link for the pages \(pathsWithoutSample.sorted())")
    }

    @Test("A uid doesn't change where a link leads", arguments: DeeplinkMarketingActivityUidTests.allLinks)
    func uidKeepsTheDestination(link: String) throws {
        let parser = IncomingActionParser()
        let plain = try #require(URL(string: link))
        let withUid = try #require(appendingUid(to: plain))

        guard case .navigation(let plainAction) = parser.parseIncomingURL(plain) else {
            Issue.record("\(link) doesn't parse into a destination of ours")
            return
        }

        guard case .navigation(let actionWithUid) = parser.parseIncomingURL(withUid) else {
            Issue.record("\(withUid) doesn't parse into a destination of ours")
            return
        }

        #expect(destinationName(of: actionWithUid) == destinationName(of: plainAction))
    }

    @Test(
        "A Tangem Pay link goes to the onboarding validation without its uid",
        arguments: [
            "tangem://onboard-visa?entry=banner&id=42",
            "tangem://pay-app?id=42",
            "https://tangem.com/pay-app?id=42",
        ]
    )
    func tangemPayLinkLosesUid(link: String) throws {
        let parser = IncomingActionParser()
        let plain = try #require(URL(string: link))
        let withUid = try #require(appendingUid(to: plain))
        let plainAction = try #require(parser.parseIncomingURL(plain))

        #expect(parser.parseIncomingURL(withUid) == plainAction)
    }

    @Test("A uid doesn't reach the logged description of the action", arguments: DeeplinkMarketingActivityUidTests.allLinks)
    func uidStaysOutOfActionDescription(link: String) throws {
        let withUid = try #require(URL(string: link).flatMap(appendingUid(to:)))
        let action = try #require(IncomingActionParser().parseIncomingURL(withUid))

        #expect(!String(describing: action).contains(Self.uid))
    }

    @Test("Every sample link names a destination of the router", arguments: DeeplinkMarketingActivityUidTests.allLinks)
    func sampleNamesDestination(link: String) throws {
        let link = try #require(URL(string: link).flatMap(DeeplinkURL.init(url:)))

        #expect(DeeplinkNavigationAction.namesDestination(link))
    }

    @Test(
        "A link that names nothing of ours names no destination, however its parameters look",
        arguments: ["tangem://abc?token_id=bitcoin", "https://tangem.com/some/page", "https://tangem.com"]
    )
    func namesNoDestination(link: String) throws {
        let link = try #require(URL(string: link).flatMap(DeeplinkURL.init(url:)))

        #expect(!DeeplinkNavigationAction.namesDestination(link))
    }

    @Test(
        "A push link is read from the deeplink key first, then the link key",
        arguments: [
            (["deeplink": "tangem://markets?uid=a", "link": "tangem://buy?uid=b"], "tangem://markets?uid=a"),
            (["link": "tangem://buy?uid=b"], "tangem://buy?uid=b"),
            (["type": "income_transaction"], nil),
        ] as [([String: String], String?)]
    )
    func pushLink(userInfo: [String: String], expectedLink: String?) {
        #expect(IncomingActionParser().pushLink(from: userInfo)?.absoluteString == expectedLink)
    }
}

// MARK: - Helpers

private extension DeeplinkMarketingActivityUidTests {
    func appendingUid(to url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        components.queryItems = queryItems + [URLQueryItem(name: "uid", value: Self.uid)]
        return components.url
    }

    func destinationName(of action: DeeplinkNavigationAction) -> String {
        Mirror(reflecting: action).children.first?.label ?? String(describing: action)
    }
}
