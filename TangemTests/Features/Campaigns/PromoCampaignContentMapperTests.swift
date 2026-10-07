//
//  PromoCampaignContentMapperTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PromoCampaignContentMapper", .tags(.campaigns))
struct PromoCampaignContentMapperTests {
    @Test("The contract example maps into the content the sheet renders")
    func contractExample() throws {
        let content = try map(
            blocks: """
            [
              { "type": "text", "text": "Stake from 100 USDT and get cashback" },
              { "type": "block", "title": "Cashback and amounts", "items": [
                  { "label": "From $10K", "value": 0.10, "valueType": "percent" },
                  { "label": "Weekly bonus", "value": 5, "valueType": "money", "currency": "USDT" },
                  { "label": "Tier", "value": "Gold", "valueType": "text" }
              ] },
              { "type": "table", "title": "Payout breakdown", "headers": ["Condition", "Value"], "columnTypes": ["text", "money"], "rows": [
                  [{ "text": "Cashback" }, { "value": 5, "currency": "USDT" }],
                  [{ "text": "Gas refund" }, { "value": 0.002, "currency": "ETH" }]
              ] },
              { "type": "highlight", "title": "Deadline", "text": "Until August 31" }
            ]
            """
        )

        #expect(content.title == "Summer staking bonus")
        #expect(content.imageURL == URL(string: "https://cdn.tangem.com/campaigns/example_campaign.png"))
        #expect(content.actionButtonTitle == "Select cashback token")
        #expect(content.learnMoreLink == .init(title: "Learn more", url: URL(string: "https://tangem.com/campaigns/example_campaign")!))
        #expect(content.termsLink == .init(title: "Terms and conditions", url: URL(string: "https://tangem.com/campaigns/example_campaign/terms")!))

        #expect(content.blocks == [
            .text(title: nil, text: "Stake from 100 USDT and get cashback", link: nil),
            .items(title: "Cashback and amounts", items: [
                .init(label: "From $10K", value: "0.10%"),
                .init(label: "Weekly bonus", value: "USDT\u{00A0}5"),
                .init(label: "Tier", value: "Gold"),
            ]),
            .table(.init(
                title: "Payout breakdown",
                headers: ["Condition", "Value"],
                rows: [["Cashback", "USDT\u{00A0}5"], ["Gas refund", "ETH\u{00A0}0.002"]]
            )),
            .highlight(title: "Deadline", text: "Until August 31"),
        ])
    }

    @Test("A block with nothing to show is left out")
    func emptyBlocksAreLeftOut() throws {
        let content = try map(
            blocks: """
            [
              { "type": "text", "text": "" },
              { "type": "highlight", "title": "Deadline", "text": "" },
              { "type": "block", "title": "Cashback", "items": [] },
              { "type": "table", "title": "Payout", "rows": [[]] },
              { "type": "text", "text": "Kept" }
            ]
            """
        )

        #expect(content.blocks == [.text(title: nil, text: "Kept", link: nil)])
    }

    @Test("The reworked contract brings a subtitle and text blocks with a title and a trailing link")
    func reworkedContract() throws {
        let content = try map(
            blocks: """
            [
              { "type": "text", "title": "Max payout and limits", "text": "Payout arrives weekly", "link": { "text": "Learn more", "url": "https://tangem.com/campaigns/example_campaign" } },
              { "type": "text", "title": "", "text": "No title", "link": { "text": "", "url": "https://tangem.com/campaigns/example_campaign" } }
            ]
            """,
            links: """
            "campaignDescription": "Earn cashback on every swap from $10K",
            "tncLink": { "text": "Terms and conditions", "url": "https://tangem.com/campaigns/example_campaign/terms" },
            """
        )

        #expect(content.subtitle == "Earn cashback on every swap from $10K")
        #expect(content.blocks == [
            .text(
                title: "Max payout and limits",
                text: "Payout arrives weekly",
                link: .init(title: "Learn more", url: URL(string: "https://tangem.com/campaigns/example_campaign")!)
            ),
            .text(title: nil, text: "No title", link: nil),
        ])
    }

    @Test("The global learn-more link gives way to the links the text blocks carry")
    func blockLinksReplaceGlobalLearnMore() throws {
        let content = try map(
            blocks: """
            [{ "type": "text", "text": "Payout arrives weekly", "link": { "text": "Learn more", "url": "https://tangem.com/campaigns/example_campaign" } }]
            """
        )

        #expect(content.learnMoreLink == nil)
        #expect(content.blocks == [
            .text(title: nil, text: "Payout arrives weekly", link: .init(title: "Learn more", url: URL(string: "https://tangem.com/campaigns/example_campaign")!)),
        ])
    }

    @Test("An empty campaign description is treated as no subtitle")
    func emptyDescriptionIsNoSubtitle() throws {
        let content = try map(blocks: "[]", links: #""campaignDescription": "","#)

        #expect(content.subtitle == nil)
    }

    @Test("An empty title is treated as no title")
    func emptyTitleIsNoTitle() throws {
        let content = try map(
            blocks: """
            [{ "type": "highlight", "title": "", "text": "Until August 31" }]
            """
        )

        #expect(content.blocks == [.highlight(title: nil, text: "Until August 31")])
    }

    @Test("A table cell prefers its text, and a cell with neither text nor value stays blank")
    func tableCells() throws {
        let content = try map(
            blocks: """
            [{ "type": "table", "rows": [[{ "text": "Label", "value": 1 }, {}, { "value": 25, "currency": "USD" }]] }]
            """
        )

        #expect(content.blocks == [.table(.init(title: nil, headers: [], rows: [["Label", "", "$25"]]))])
    }

    @Test("A cell with an empty text falls back to its value")
    func emptyCellTextFallsBackToValue() throws {
        let content = try map(
            blocks: """
            [{ "type": "table", "rows": [[{ "text": "", "value": 25, "currency": "USD" }]] }]
            """
        )

        #expect(content.blocks == [.table(.init(title: nil, headers: [], rows: [["$25"]]))])
    }

    @Test("Rows are padded or trimmed to the declared columns, and a row with nothing to show is left out")
    func rowsAlignToColumns() throws {
        let content = try map(
            blocks: """
            [{ "type": "table", "headers": ["Condition", "Value"], "rows": [
                [{ "text": "Short" }],
                [{ "text": "Long" }, { "text": "Kept" }, { "text": "Dropped" }],
                [{}, { "text": "" }]
            ] }]
            """
        )

        #expect(content.blocks == [.table(.init(
            title: nil,
            headers: ["Condition", "Value"],
            rows: [["Short", ""], ["Long", "Kept"]]
        ))])
    }

    @Test("Column types wider than the headers pad the headers")
    func headersPadToColumnTypes() throws {
        let content = try map(
            blocks: """
            [{ "type": "table", "headers": ["Condition"], "columnTypes": ["text", "money"], "rows": [
                [{ "text": "Cashback" }, { "value": 5, "currency": "USDT" }]
            ] }]
            """
        )

        #expect(content.blocks == [.table(.init(title: nil, headers: ["Condition", ""], rows: [["Cashback", "USDT\u{00A0}5"]]))])
    }

    @Test("A column type decides how a cell value without a currency reads")
    func columnTypesFormatCells() throws {
        let content = try map(
            blocks: """
            [{ "type": "table", "columnTypes": ["text", "percent", "number"], "rows": [
                [{ "text": "Tier" }, { "value": 0.1 }, { "value": 1500 }]
            ] }]
            """
        )

        #expect(content.blocks == [.table(.init(title: nil, headers: [], rows: [["Tier", "0.10%", "1,500"]]))])
    }

    @Test("An item without a label or with an empty text value is left out")
    func emptyItemsAreLeftOut() throws {
        let content = try map(
            blocks: """
            [
              { "type": "block", "title": "Cashback", "items": [
                  { "label": "", "value": 5, "valueType": "number" },
                  { "label": "Tier", "value": "", "valueType": "text" },
                  { "label": "Count", "value": 1500, "valueType": "number" }
              ] },
              { "type": "block", "title": "Empty", "items": [{ "label": "", "value": "Gold", "valueType": "text" }] }
            ]
            """
        )

        #expect(content.blocks == [.items(title: "Cashback", items: [.init(label: "Count", value: "1,500")])])
    }

    @Test("A link without a text is left out")
    func linkWithoutTextIsLeftOut() throws {
        let content = try map(
            blocks: "[]",
            links: """
            "learnMoreLink": { "text": "", "url": "https://tangem.com/campaigns/example_campaign" },
            "tncLink": { "text": "Terms and conditions", "url": "https://tangem.com/campaigns/example_campaign/terms" },
            """
        )

        #expect(content.learnMoreLink == nil)
        #expect(content.termsLink == .init(title: "Terms and conditions", url: URL(string: "https://tangem.com/campaigns/example_campaign/terms")!))
    }

    @Test("A currency matching a payout token reads as a token even when it is an ISO 4217 code")
    func payoutTokenCurrencyReadsAsToken() throws {
        let content = try map(
            blocks: """
            [{ "type": "table", "columnTypes": ["text", "money"], "rows": [[{ "text": "Cashback" }, { "value": 10.12345, "currency": "MNT" }]] }]
            """,
            payoutTokenSymbols: ["MNT"]
        )

        #expect(content.blocks == [.table(.init(title: nil, headers: [], rows: [["Cashback", "MNT\u{00A0}10.12345"]]))])
    }

    @Test("Links the campaign doesn't send stay absent")
    func missingLinks() throws {
        let content = try map(blocks: "[]", links: "")

        #expect(content.subtitle == nil)
        #expect(content.learnMoreLink == nil)
        #expect(content.termsLink == nil)
        #expect(content.imageURL == nil)
    }
}

// MARK: - Helpers

private extension PromoCampaignContentMapperTests {
    static let links = """
    "publicImage": "https://cdn.tangem.com/campaigns/example_campaign.png",
    "learnMoreLink": { "text": "Learn more", "url": "https://tangem.com/campaigns/example_campaign" },
    "tncLink": { "text": "Terms and conditions", "url": "https://tangem.com/campaigns/example_campaign/terms" },
    """

    func map(blocks: String, links: String = Self.links, payoutTokenSymbols: [String] = []) throws -> PromoCampaignContent {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dto = try decoder.decode(
            PromoCampaignsDTO.Content.self,
            from: Data(
                """
                {
                  "campaignName": "Summer staking bonus",
                  "publicDescription": \(blocks),
                  \(links)
                  "actionButtonName": "Select cashback token"
                }
                """.utf8
            )
        )

        let mapper = PromoCampaignContentMapper(valueFormatter: PromoCampaignValueFormatter(locale: Locale(identifier: "en_US")))
        let payoutTokens = payoutTokenSymbols.map {
            PromoCampaignsDTO.PayoutToken(tokenAddress: "0x0", networkId: "ethereum", tokenSymbol: $0, tokenName: $0, tokenId: nil, decimals: nil)
        }

        return mapper.map(dto, payoutTokens: payoutTokens)
    }
}
