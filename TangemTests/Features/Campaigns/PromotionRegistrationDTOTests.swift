//
//  PromotionRegistrationDTOTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PromotionRegistrationDTO", .tags(.campaigns))
struct PromotionRegistrationDTOTests {
    @Test("Response status decodes both backend variants", arguments: [
        ("saved", PromotionRegistrationDTO.Response.Status.saved),
        ("already_exists", PromotionRegistrationDTO.Response.Status.alreadyExists),
    ])
    func responseStatusDecodesBackendVariants(rawStatus: String, expected: PromotionRegistrationDTO.Response.Status) throws {
        let json = Data(#"{"status": "\#(rawStatus)"}"#.utf8)

        let response = try JSONDecoder().decode(PromotionRegistrationDTO.Response.self, from: json)

        #expect(response.status == expected)
    }

    @Test("Unknown response status fails to decode")
    func unknownResponseStatusFailsToDecode() {
        let json = Data(#"{"status": "pending"}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PromotionRegistrationDTO.Response.self, from: json)
        }
    }

    @Test("Request encodes the exact field names the backend expects")
    func requestEncodesExactFieldNames() throws {
        let request = PromotionRegistrationDTO.Request(
            campaignId: "whale-swap-cashback",
            walletIds: ["wallet-1", "wallet-2"],
            tokenReward: .init(
                tokenAddress: "0xToken",
                networkId: "ethereum",
                userAddress: "0xUser",
                tokenId: "usd-coin"
            )
        )

        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        let tokenReward = json?["tokenReward"] as? [String: Any]

        #expect(json?["campaignId"] as? String == "whale-swap-cashback")
        #expect(json?["walletIds"] as? [String] == ["wallet-1", "wallet-2"])
        #expect(tokenReward?["tokenAddress"] as? String == "0xToken")
        #expect(tokenReward?["networkId"] as? String == "ethereum")
        #expect(tokenReward?["userAddress"] as? String == "0xUser")
        #expect(tokenReward?["tokenId"] as? String == "usd-coin")
    }

    @Test("Nil tokenId is omitted from the request payload")
    func nilTokenIdIsOmitted() throws {
        let request = PromotionRegistrationDTO.Request(
            campaignId: "whale-swap-cashback",
            walletIds: ["wallet-1"],
            tokenReward: .init(
                tokenAddress: "0xToken",
                networkId: "ethereum",
                userAddress: "0xUser",
                tokenId: nil
            )
        )

        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        let tokenReward = try #require(json?["tokenReward"] as? [String: Any])

        #expect(tokenReward["tokenId"] == nil)
    }
}
