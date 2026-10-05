//
//  PromoCampaignsDTORequestTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
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

    @Test("A card wallet builds a card request with its id and batch")
    func cardWalletRequest() throws {
        let wallet = PromoCampaignWallet(userWalletId: UserWalletId(value: Data([0xAA])), identity: .card(batchId: "AF04"))
        let json = try encode(PromoCampaignsDTO.Request(wallet: wallet, language: "en"))

        #expect(json["walletId"] as? String == wallet.userWalletId.stringValue)
        #expect(json["walletType"] as? String == "card")
        #expect(json["batchId"] as? String == "AF04")
        #expect(json["language"] as? String == "en")
    }

    @Test("A mobile wallet builds a mobile request without a batch")
    func mobileWalletRequest() throws {
        let wallet = PromoCampaignWallet(userWalletId: UserWalletId(value: Data([0xAA])), identity: .mobile)
        let json = try encode(PromoCampaignsDTO.Request(wallet: wallet, language: "en"))

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
        return try encode(request)
    }

    func encode(_ request: PromoCampaignsDTO.Request) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
