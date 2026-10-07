//
//  PromoCampaignsDTODecodingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PromoCampaignsDTO decoding")
struct PromoCampaignsDTODecodingTests {
    @Test("Every block type the current version knows decodes into its own case")
    func knownBlockTypes() throws {
        let blocks = try decodeBlocks(
            """
            [
              { "type": "text", "text": "Stake from 100 USDT" },
              { "type": "highlight", "title": "Deadline", "text": "Until August 31" },
              { "type": "block", "title": "Cashback", "items": [
                  { "label": "From $10K", "value": 0.10, "valueType": "percent" }
              ] },
              { "type": "table", "title": "Payout", "headers": ["Condition", "Value"], "columnTypes": ["text", "money"], "rows": [
                  [{ "text": "Cashback" }, { "value": 5, "currency": "USDT" }]
              ] }
            ]
            """
        )

        #expect(blocks.count == 4)

        guard case .text(let text) = blocks[0] else {
            Issue.record("Expected a text block, got \(blocks[0])")
            return
        }

        #expect(text.text == "Stake from 100 USDT")

        guard case .highlight(let highlight) = blocks[1] else {
            Issue.record("Expected a highlight block, got \(blocks[1])")
            return
        }

        #expect(highlight.title == "Deadline")

        guard case .block(let items) = blocks[2] else {
            Issue.record("Expected an items block, got \(blocks[2])")
            return
        }

        #expect(items.items.count == 1)
        #expect(items.items[0].valueType == .percent)

        guard case .table(let table) = blocks[3] else {
            Issue.record("Expected a table block, got \(blocks[3])")
            return
        }

        #expect(table.headers == ["Condition", "Value"])
        #expect(table.rows[0][1].currency == "USDT")
    }

    @Test("A block type added after this version shipped is dropped, the rest survives")
    func unknownBlockTypeIsDropped() throws {
        let blocks = try decodeBlocks(
            """
            [
              { "type": "text", "text": "Before" },
              { "type": "carousel", "slides": ["a", "b"] },
              { "type": "text", "text": "After" }
            ]
            """
        )

        #expect(blocks.count == 2)

        guard case .text(let before) = blocks[0], case .text(let after) = blocks[1] else {
            Issue.record("Expected the surrounding text blocks to survive")
            return
        }

        #expect(before.text == "Before")
        #expect(after.text == "After")
    }

    @Test("A text block keeps its title and link, and a link it cannot read costs only the link")
    func textBlockTitleAndLink() throws {
        let blocks = try decodeBlocks(
            """
            [
              { "type": "text", "title": "Max payout and limits", "text": "Payout arrives weekly", "link": { "text": "Learn more", "url": "https://tangem.com/campaigns/example_campaign" } },
              { "type": "text", "text": "Empty url", "link": { "text": "Learn more", "url": "" } },
              { "type": "text", "text": "No link text", "link": { "url": "https://tangem.com" } }
            ]
            """
        )

        #expect(blocks.count == 3)

        guard case .text(let linked) = blocks[0], case .text(let emptyURL) = blocks[1], case .text(let noLinkText) = blocks[2] else {
            Issue.record("Expected three text blocks")
            return
        }

        #expect(linked.title == "Max payout and limits")
        #expect(linked.link?.text == "Learn more")
        #expect(linked.link?.url == URL(string: "https://tangem.com/campaigns/example_campaign"))
        #expect(emptyURL.text == "Empty url")
        #expect(emptyURL.link == nil)
        #expect(noLinkText.link == nil)
    }

    @Test("A known block missing a required field is dropped rather than failing the campaign")
    func malformedKnownBlockIsDropped() throws {
        let blocks = try decodeBlocks(
            """
            [
              { "type": "text", "text": "Before" },
              { "type": "highlight", "title": "No text at all" },
              { "type": "text", "text": "After" }
            ]
            """
        )

        #expect(blocks.count == 2)
    }

    @Test("A block carries either a number or a string as its value")
    func itemValueAcceptsBothShapes() throws {
        let blocks = try decodeBlocks(
            """
            [
              { "type": "block", "items": [
                  { "label": "Rate", "value": 0.2, "valueType": "percent" },
                  { "label": "Tier", "value": "Gold", "valueType": "text" }
              ] }
            ]
            """
        )

        guard case .block(let items) = blocks[0] else {
            Issue.record("Expected an items block, got \(blocks[0])")
            return
        }

        guard case .number(let rate) = items.items[0].value else {
            Issue.record("Expected a numeric value, got \(items.items[0].value)")
            return
        }

        #expect(rate == Decimal(string: "0.2"))

        guard case .text(let tier) = items.items[1].value else {
            Issue.record("Expected a string value, got \(items.items[1].value)")
            return
        }

        #expect(tier == "Gold")
    }

    @Test("A campaign this version cannot decode is dropped, the other campaigns survive")
    func undecodableCampaignIsDropped() throws {
        let response = try decoder.decode(
            PromoCampaignsDTO.Response.self,
            from: Data(
                """
                { "promotions": [
                  {
                    "id": 1,
                    "name": "future_campaign",
                    "alreadyEnrolled": false,
                    "content": \(contentJSON),
                    "properties": { "payoutNeeded": false, "matchMode": "device" }
                  },
                  {
                    "id": 2,
                    "name": "summer_staking_2026",
                    "alreadyEnrolled": false,
                    "content": \(contentJSON),
                    "properties": { "payoutNeeded": false, "matchMode": "strict" }
                  }
                ] }
                """.utf8
            )
        )

        #expect(response.promotions.map(\.id) == [2])
        #expect(response.promotions.map(\.name) == ["summer_staking_2026"])
    }

    @Test("Match mode keeps the snake_case spelling the backend sends")
    func matchModeSpelling() throws {
        let properties = try decoder.decode(
            PromoCampaignsDTO.Properties.self,
            from: Data(
                """
                { "payoutNeeded": false, "matchMode": "linked_wallet" }
                """.utf8
            )
        )

        #expect(properties.matchMode == .linkedWallet)
        #expect(properties.payoutTokens == nil)
    }
}

// MARK: - Helpers

private extension PromoCampaignsDTODecodingTests {
    var contentJSON: String {
        """
        {
          "campaignName": "Summer staking bonus",
          "publicDescription": [{ "type": "text", "text": "Stake from 100 USDT" }],
          "publicImage": "https://cdn.tangem.com/campaigns/summer.png",
          "actionButtonName": "Select cashback token"
        }
        """
    }

    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    func decodeBlocks(_ json: String) throws -> [PromoCampaignsDTO.ContentBlock] {
        let content = try decoder.decode(
            PromoCampaignsDTO.Content.self,
            from: Data(
                """
                {
                  "campaignName": "Summer staking bonus",
                  "publicDescription": \(json),
                  "actionButtonName": "Select cashback token"
                }
                """.utf8
            )
        )

        return content.publicDescription
    }
}
