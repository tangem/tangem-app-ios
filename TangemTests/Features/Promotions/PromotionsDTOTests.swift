//
//  PromotionsDTOTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PromotionsDTO")
struct PromotionsDTOTests {
    // MARK: - Placement Parsing

    @Test("Decodes token_details placement")
    func decodesTokenDetailsPlacement() throws {
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "token_details"))

        let response = try decode(json)

        #expect(response.items.first?.placeholder == .tokenDetails)
    }

    @Test("Decodes yield placement")
    func decodesYieldPlacement() throws {
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "yield"))

        let response = try decode(json)

        #expect(response.items.first?.placeholder == .yield)
    }

    @Test("Decodes main placement (backward compatibility)")
    func decodesMainPlacement() throws {
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "main"))

        let response = try decode(json)

        #expect(response.items.first?.placeholder == .main)
    }

    @Test("Decodes shtorka placement (backward compatibility)")
    func decodesShtorkaPlacement() throws {
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "shtorka"))

        let response = try decode(json)

        #expect(response.items.first?.placeholder == .news)
    }

    // MARK: - Tokens Parsing

    @Test("Decodes response without tokens (main/shtorka)")
    func decodesWithoutTokens() throws {
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "main"))

        let response = try decode(json)

        #expect(response.items.first?.tokens == nil)
    }

    @Test("Decodes empty tokens array")
    func decodesEmptyTokens() throws {
        let emptyTokens = "[]"
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "token_details", tokens: emptyTokens))

        let response = try decode(json)

        #expect(response.items.first?.tokens?.isEmpty == true)
    }

    @Test("Decodes multiple tokens in array")
    func decodesMultipleTokens() throws {
        let tokensJSON = makeTokensArrayJSON([
            makeTokenJSON(),
            makeTokenJSON(
                networkId: Constants.secondaryNetworkId,
                id: Constants.secondaryTokenId,
                symbol: Constants.secondarySymbol
            ),
        ])
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "token_details", tokens: tokensJSON))

        let response = try decode(json)
        let tokens = try #require(response.items.first?.tokens)

        #expect(tokens.count == 2)
        #expect(tokens[0].networkId == Constants.defaultNetworkId)
        #expect(tokens[0].token.symbol == Constants.defaultSymbol)
        #expect(tokens[1].networkId == Constants.secondaryNetworkId)
        #expect(tokens[1].token.symbol == Constants.secondarySymbol)
    }

    // MARK: - Optional Fields

    @Test("Decodes all optional fields")
    func decodesAllOptionalFields() throws {
        let json = makeResponseJSON(items: makeItemJSON(
            placeholder: "main",
            priority: Constants.anyPriority,
            iconUrl: Constants.anyIconUrl,
            deeplink: Constants.anyDeeplink,
            buttonText: Constants.anyButtonText
        ))

        let response = try decode(json)
        let item = try #require(response.items.first)

        #expect(item.priority == Constants.anyPriority)
        #expect(item.iconUrl == URL(string: Constants.anyIconUrl))
        #expect(item.deeplink == URL(string: Constants.anyDeeplink))
        #expect(item.buttonText == Constants.anyButtonText)
    }

    @Test("Handles missing optional fields")
    func handlesMissingOptionalFields() throws {
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "main"))

        let response = try decode(json)
        let item = try #require(response.items.first)

        #expect(item.priority == nil)
        #expect(item.iconUrl == nil)
        #expect(item.deeplink == nil)
        #expect(item.buttonText == nil)
        #expect(item.tokens == nil)
    }

    // MARK: - Response Structure

    @Test("Decodes empty items array")
    func decodesEmptyItems() throws {
        let json = makeResponseJSON()

        let response = try decode(json)

        #expect(response.items.isEmpty)
    }

    @Test("Decodes multiple items in response")
    func decodesMultipleItems() throws {
        let json = makeResponseJSON(items: [
            makeItemJSON(placeholder: "main"),
            makeItemJSON(placeholder: "token_details"),
        ])

        let response = try decode(json)

        #expect(response.items.count == 2)
        #expect(response.items[0].placeholder == .main)
        #expect(response.items[1].placeholder == .tokenDetails)
    }

    @Test("Fails to decode unknown placeholder")
    func failsOnUnknownPlacement() throws {
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "unknown_placement"))

        #expect(throws: DecodingError.self) {
            try decode(json)
        }
    }

    // MARK: - Full Response

    @Test("Decodes response with tokens")
    func decodesTokens() throws {
        let tokensJSON = makeTokensArrayJSON([makeTokenJSON()])
        let json = makeResponseJSON(items: makeItemJSON(placeholder: "token_details", tokens: tokensJSON))

        let response = try decode(json)
        let item = try #require(response.items.first)

        #expect(item.tokens?.count == 1)

        let tokenInfo = try #require(item.tokens?.first)
        #expect(tokenInfo.networkId == Constants.defaultNetworkId)
        #expect(tokenInfo.token.id == Constants.defaultTokenId)
        #expect(tokenInfo.token.symbol == Constants.defaultSymbol)
        #expect(tokenInfo.token.name == Constants.defaultName)
        #expect(tokenInfo.token.address == Constants.defaultAddress)
        #expect(tokenInfo.token.decimalCount == Constants.defaultDecimalCount)
    }
}

// MARK: - Constants

private extension PromotionsDTOTests {
    enum Constants {
        // Optional fields
        static let anyPriority = "high"
        static let anyIconUrl = "https://example.com/icon.png"
        static let anyDeeplink = "app://action"
        static let anyButtonText = "Click me"

        // Default token (USDT on Ethereum)
        static let defaultNetworkId = "ethereum"
        static let defaultTokenId = "usdt"
        static let defaultSymbol = "USDT"
        static let defaultName = "Tether USD"
        static let defaultAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
        static let defaultDecimalCount = 6

        // Secondary token (USDC on Base)
        static let secondaryNetworkId = "base"
        static let secondaryTokenId = "usdc"
        static let secondarySymbol = "USDC"
    }
}

// MARK: - Helpers

private extension PromotionsDTOTests {
    func decode(_ json: String) throws -> PromotionsDTO.Load.Response {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(PromotionsDTO.Load.Response.self, from: data)
    }

    // MARK: - JSON Builders

    func makeItemJSON(
        placeholder: String,
        priority: String? = nil,
        iconUrl: String? = nil,
        deeplink: String? = nil,
        buttonText: String? = nil,
        tokens: String? = nil
    ) -> String {
        var optionalFields = ""
        if let priority { optionalFields += ",\n            \"priority\": \"\(priority)\"" }
        if let iconUrl { optionalFields += ",\n            \"iconUrl\": \"\(iconUrl)\"" }
        if let deeplink { optionalFields += ",\n            \"deeplink\": \"\(deeplink)\"" }
        if let buttonText { optionalFields += ",\n            \"buttonText\": \"\(buttonText)\"" }
        if let tokens { optionalFields += ",\n            \"tokens\": \(tokens)" }
        return """
        {
            "id": 1,
            "placeholder": "\(placeholder)",
            "title": "Title",
            "subtitle": "Subtitle",
            "buttonEnabled": true,
            "dismissable": true\(optionalFields)
        }
        """
    }

    func makeResponseJSON(items: String = "") -> String {
        """
        {
            "items": [\(items)]
        }
        """
    }

    func makeResponseJSON(items: [String]) -> String {
        makeResponseJSON(items: items.joined(separator: ", "))
    }

    func makeTokenJSON(
        networkId: String = Constants.defaultNetworkId,
        id: String = Constants.defaultTokenId,
        symbol: String = Constants.defaultSymbol,
        name: String = Constants.defaultName,
        address: String = Constants.defaultAddress,
        decimalCount: Int = Constants.defaultDecimalCount
    ) -> String {
        """
        {
            "networkId": "\(networkId)",
            "token": {
                "id": "\(id)",
                "symbol": "\(symbol)",
                "name": "\(name)",
                "address": "\(address)",
                "decimalCount": \(decimalCount)
            }
        }
        """
    }

    func makeTokensArrayJSON(_ tokens: [String]) -> String {
        "[\(tokens.joined(separator: ", "))]"
    }
}
