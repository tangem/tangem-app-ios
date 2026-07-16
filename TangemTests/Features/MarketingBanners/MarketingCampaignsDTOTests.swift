//
//  MarketingCampaignsDTOTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketingCampaignsDTO", .tags(.marketingBanners))
struct MarketingCampaignsDTOTests {
    private typealias Fixtures = MarketingCampaignsFixtures

    /// Real backend payload verified by QA on the dev stand (linked_to_provider, onramp).
    private static let linkedToProviderJSON = """
    {
      "campaigns": [
        {
          "id": 16,
          "type": "onramp",
          "priority": 2,
          "startAt": null,
          "endAt": null,
          "minAmount": null,
          "maxAmount": null,
          "providerIds": ["mercuryo"],
          "banner": {
            "uiType": "linked_to_provider",
            "text": "Discover Bitcoin",
            "icon": "https://cdn.tangem.com/dev/star.png",
            "iconAlign": null,
            "bgColor": null,
            "deeplink": "tangem://swap",
            "dismissible": false
          }
        }
      ]
    }
    """

    /// Real backend payload verified by QA on the dev stand (standalone, onramp).
    private static let standaloneJSON = """
    {
      "campaigns": [
        {
          "id": 16,
          "type": "onramp",
          "priority": 2,
          "startAt": null,
          "endAt": null,
          "minAmount": null,
          "maxAmount": null,
          "providerIds": ["simplex"],
          "banner": {
            "uiType": "standalone",
            "text": "Discover Bitcoin",
            "icon": "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/bitcoin.png",
            "iconAlign": null,
            "bgColor": null,
            "deeplink": null,
            "dismissible": true
          }
        }
      ]
    }
    """

    private static let tokenDetailsJSON = """
    {
      "campaigns": [
        {
          "id": 21,
          "type": "token_details",
          "priority": 1,
          "minAmount": 10.5,
          "maxAmount": 1000,
          "tokens": [
            { "networkId": "ethereum", "contractAddress": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "id": "usd-coin" },
            { "networkId": "solana", "contractAddress": null, "id": null }
          ],
          "banner": {
            "uiType": "standalone",
            "text": "Boost your USDC",
            "icon": null,
            "bgColor": "#1A1A1A",
            "deeplink": "tangem://token_details",
            "dismissible": false
          }
        }
      ]
    }
    """

    private func decodeResponse(_ json: String) throws -> MarketingCampaignsDTO.Response {
        try JSONDecoder().decode(MarketingCampaignsDTO.Response.self, from: Data(json.utf8))
    }

    @Test("QA linked_to_provider payload decodes with all fields")
    func decodesLinkedToProviderPayload() throws {
        let campaign = try #require(decodeResponse(Self.linkedToProviderJSON).campaigns.first)

        #expect(campaign.id == 16)
        #expect(campaign.type == "onramp")
        #expect(campaign.priority == 2)
        #expect(campaign.minAmount == nil)
        #expect(campaign.maxAmount == nil)
        #expect(campaign.providerIds == ["mercuryo"])
        #expect(campaign.tokens == nil)

        guard case .linkedToProvider = campaign.banner.uiType else {
            Issue.record("Expected linkedToProvider uiType")
            return
        }
        #expect(campaign.banner.text == "Discover Bitcoin")
        #expect(campaign.banner.icon == URL(string: "https://cdn.tangem.com/dev/star.png"))
        #expect(campaign.banner.bgColor == nil)
        #expect(campaign.banner.deeplink == URL(string: "tangem://swap"))
        #expect(campaign.banner.dismissible == false)
    }

    @Test("QA standalone payload decodes with nil deeplink and dismissible true")
    func decodesStandalonePayload() throws {
        let campaign = try #require(decodeResponse(Self.standaloneJSON).campaigns.first)

        guard case .standalone = campaign.banner.uiType else {
            Issue.record("Expected standalone uiType")
            return
        }
        #expect(campaign.providerIds == ["simplex"])
        #expect(campaign.banner.deeplink == nil)
        #expect(campaign.banner.dismissible == true)
    }

    @Test("Token-details payload decodes tokens and exact Decimal bounds")
    func decodesTokenDetailsPayload() throws {
        let campaign = try #require(decodeResponse(Self.tokenDetailsJSON).campaigns.first)

        #expect(campaign.minAmount == Decimal(string: "10.5")!)
        #expect(campaign.maxAmount == Decimal(string: "1000")!)

        let tokens = try #require(campaign.tokens)
        #expect(tokens.count == 2)
        #expect(tokens[0].networkId == "ethereum")
        #expect(tokens[0].contractAddress == "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
        #expect(tokens[0].id == "usd-coin")
        #expect(tokens[1].networkId == "solana")
        #expect(tokens[1].contractAddress == nil)
        #expect(tokens[1].id == nil)
    }

    @Test("Unknown uiType decodes to the unknown case instead of throwing")
    func unknownUITypeDecodesToUnknownCase() throws {
        let json = """
        { "uiType": "brand_new_type", "text": "X", "dismissible": false }
        """

        let banner = try JSONDecoder().decode(MarketingCampaignsDTO.Banner.self, from: Data(json.utf8))

        guard case .unknown(let raw) = banner.uiType else {
            Issue.record("Expected unknown uiType")
            return
        }
        #expect(raw == "brand_new_type")
    }

    @Test("Campaign dates decode with the production date strategy")
    func decodesCampaignDates() throws {
        let json = """
        {
          "campaigns": [
            {
              "id": 16,
              "type": "onramp",
              "priority": 1,
              "startAt": "2026-08-01T12:00:00.000Z",
              "endAt": "2026-09-01T12:00:00.500Z",
              "banner": { "uiType": "standalone", "text": "X", "dismissible": true }
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        let campaign = try #require(decoder.decode(MarketingCampaignsDTO.Response.self, from: Data(json.utf8)).campaigns.first)

        #expect(campaign.startAt == Date(timeIntervalSince1970: 1_785_585_600))
        #expect(campaign.endAt == Date(timeIntervalSince1970: 1_788_264_000.5))
    }

    @Test(
        "Campaign survives the encode-decode roundtrip used by the disk cache",
        arguments: ["standalone", "linked_to_provider", "brand_new_type"]
    )
    func campaignSurvivesCodableRoundtrip(uiTypeRaw: String) throws {
        let uiType: MarketingCampaignsDTO.Banner.UIType = switch uiTypeRaw {
        case "standalone": .standalone
        case "linked_to_provider": .linkedToProvider
        default: .unknown(uiTypeRaw)
        }

        let campaign = Fixtures.makeCampaign(
            id: 5,
            startAt: Date(timeIntervalSince1970: 1_785_585_600),
            endAt: Date(timeIntervalSince1970: 1_788_264_000.5),
            minAmount: Decimal(string: "10.5")!,
            maxAmount: Decimal(string: "1000")!,
            providerIds: ["mercuryo"],
            tokens: [Fixtures.makeToken(networkId: "ethereum", contractAddress: "0xA", id: "usd-coin")],
            uiType: uiType,
            deeplink: URL(string: "tangem://swap"),
            dismissible: true
        )

        let data = try JSONEncoder().encode(campaign)
        let decoded = try JSONDecoder().decode(MarketingCampaignsDTO.Campaign.self, from: data)

        #expect(decoded.id == campaign.id)
        #expect(decoded.startAt == campaign.startAt)
        #expect(decoded.endAt == campaign.endAt)
        #expect(decoded.minAmount == campaign.minAmount)
        #expect(decoded.maxAmount == campaign.maxAmount)
        #expect(decoded.providerIds == campaign.providerIds)
        #expect(decoded.tokens?.first?.contractAddress == "0xA")
        #expect(decoded.banner.deeplink == campaign.banner.deeplink)
        #expect(decoded.banner.dismissible == campaign.banner.dismissible)
        #expect(rawValue(of: decoded.banner.uiType) == uiTypeRaw)
    }

    @Test("Request parameters carry the exact backend type strings and omit nil values")
    func requestParametersContract() {
        let swapParameters = MarketingCampaignsDTO.Request.swap(.init(
            fromNetwork: "stellar",
            fromContractAddress: "USDC-GA5Z",
            toNetwork: "solana",
            toContractAddress: nil,
            language: "en"
        )).parameters
        #expect(swapParameters as? [String: String] == [
            "type": "swap",
            "fromNetwork": "stellar",
            "fromContractAddress": "USDC-GA5Z",
            "toNetwork": "solana",
            "language": "en",
        ])

        let onrampParameters = MarketingCampaignsDTO.Request.onramp(.init(
            toNetwork: "stellar",
            toContractAddress: "USDC-GA5Z",
            fiatCurrency: "EUR",
            language: "en"
        )).parameters
        #expect(onrampParameters as? [String: String] == [
            "type": "onramp",
            "toNetwork": "stellar",
            "toContractAddress": "USDC-GA5Z",
            "fromFiat": "EUR",
            "language": "en",
        ])

        #expect(MarketingCampaignsDTO.Request.staking(language: "en").parameters as? [String: String] == [
            "type": "staking",
            "language": "en",
        ])
        #expect(MarketingCampaignsDTO.Request.yield(language: "en").parameters as? [String: String] == [
            "type": "yield",
            "language": "en",
        ])
        #expect(MarketingCampaignsDTO.Request.tokenDetails(language: "en").parameters as? [String: String] == [
            "type": "token_details",
            "language": "en",
        ])
        #expect(MarketingCampaignsDTO.Request.marketsToken(language: nil).parameters as? [String: String] == [
            "type": "markets_token",
        ])
    }

    private func rawValue(of uiType: MarketingCampaignsDTO.Banner.UIType) -> String {
        switch uiType {
        case .standalone: "standalone"
        case .linkedToProvider: "linked_to_provider"
        case .unknown(let raw): raw
        }
    }
}
