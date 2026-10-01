//
//  PromoCampaignsDTORequestTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PromoCampaignsDTO request")
struct PromoCampaignsDTORequestTests {
    @Test("A card wallet goes out as the card type with its batch")
    func cardWallet() throws {
        let json = try encode(walletType: .card, batchId: "AF04")

        #expect(json["walletType"] as? String == "card")
        #expect(json["batchId"] as? String == "AF04")
    }

    @Test("A mobile wallet goes out as the mobile type without a batch")
    func mobileWallet() throws {
        let json = try encode(walletType: .mobile, batchId: nil)

        #expect(json["walletType"] as? String == "mobile")
        #expect(json["batchId"] == nil)
    }
}

// MARK: - Helpers

private extension PromoCampaignsDTORequestTests {
    func encode(walletType: PromoCampaignsDTO.Request.WalletType, batchId: String?) throws -> [String: Any] {
        let request = PromoCampaignsDTO.Request(
            walletId: "wallet",
            walletType: walletType,
            batchId: batchId,
            language: "en"
        )
        let data = try JSONEncoder().encode(request)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
